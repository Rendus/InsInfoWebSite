#!/bin/bash

######################################################## Readme #########################################################
# This script executes all commands provided in [1] until step 8 (and step 12 partially). This helps to prepare your    #
# environment to execute the steps further.                                                                             #
#                                                                                                                       #
# Note: While executing this script, be sure to have awscli configured properly and git installed. Then SOURCE the      #
# script using "." or "source" command so that you have all the environment variable in your SHELL to execute the       #
# commands after step 8. Do not use "sh", "bash", or "./" to execute it.                                                #
#########################################################################################################################


# For details Instruction Check below link
# https://github.com/santosh07bec/InsInfoWebSite/blob/master/Instructions.md

TEMPDIR="/tmp/ECSDEMO-$(date +%d%m%Y-%H%M%S)"
mkdir -p $TEMPDIR

if [[ "x$(aws ecs describe-clusters --region ap-south-1 >/dev/null 2>&1; echo $?)" != 'x0' ]]; then
  echo -e "aws cli is either not install or not configured properly.\nInstall and configure aws cli before proceeding"
  exit 1
fi

if ! which git >/dev/null; then
  echo -e "Git is not installed or not in PATH, please install before proceeding"
  exit 1
fi

cd $TEMPDIR
git clone https://github.com/santosh07bec/InsInfoWebSite.git
cd InsInfoWebSite

export REGION="us-east-1"
export KEYPAIR="MyDemoKeyPair"
export CFN_STACK="InsInfoCluster"
export CP_NAME="MyDemoProvider-$(date +%d%m%Y-%H%M%S)"
export TASK_ROLE_NAME="DemoEcsTaskRole"
export TASK_FAMILY="MyDemoTask"
export TASK_NAME=$TASK_FAMILY
export CONTAINER_PORT=80
export CONTAINER_NAME="$TASK_NAME"
export CONTAINER_IMAGE='santosham2007s/ec2-instance-info:v1'
# export CONTAINER_IMAGE='342241566140.dkr.ecr.us-east-1.amazonaws.com/php_apache/web_image:with_improved_php_scripts_colour_env_var_logging_and_404_v5'
export PAGE_COLOUR='Blue'
export INSTANCE_TYPE='t2.medium'
export SERVICE_NAME="InsInfoService"

aws ec2 create-key-pair --key-name $KEYPAIR --query 'KeyMaterial' --output text --region $REGION  > $KEYPAIR.pem
chmod 400 $KEYPAIR.pem

export ECS_AMI_ID=$(aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux/recommended/image_id --query 'Parameters[*].Value' --output text --region $REGION)
echo $ECS_AMI_ID

aws cloudformation create-stack --stack-name $CFN_STACK --template-body file://./CFNTemplate/ECS_Cluster.yaml  --parameters ParameterKey=AsgMaxSize,ParameterValue=5 ParameterKey=EcsAmiId,ParameterValue=$ECS_AMI_ID ParameterKey=EcsInstanceType,ParameterValue=$INSTANCE_TYPE ParameterKey=KeyName,ParameterValue=$KEYPAIR --capabilities CAPABILITY_NAMED_IAM  --region $REGION

CFN_STATUS='CREATE_IN_PROGRESS'
while [[ $CFN_STATUS != "CREATE_COMPLETE" ]]; do
  sleep 10;
  printf "%s" ".";
  CFN_STATUS=$(aws cloudformation describe-stacks --stack-name $CFN_STACK --region $REGION --output text --query 'Stacks[*].StackStatus')
done

echo -e '\n\nCFN Create Complete.'

export ECS_CLUSTER_NAME=$(aws cloudformation describe-stack-resource --stack-name $CFN_STACK --logical-resource-id MyEcsCluster --query 'StackResourceDetail.PhysicalResourceId' --output text  --region $REGION)
echo $ECS_CLUSTER_NAME
export ASG_NAME=$(aws cloudformation describe-stack-resource --stack-name $CFN_STACK --logical-resource-id EcsInstanceAsg --query 'StackResourceDetail.PhysicalResourceId' --output text  --region $REGION)
echo $ASG_NAME
export TG_ARN=$(aws cloudformation describe-stack-resource --stack-name $CFN_STACK --logical-resource-id DefaultTargetGroup --query 'StackResourceDetail.PhysicalResourceId' --output text --region $REGION)
echo $TG_ARN
ALB_ARN=$(aws cloudformation describe-stack-resource --stack-name $CFN_STACK --logical-resource-id LoadBalancer --query 'StackResourceDetail.PhysicalResourceId' --output text --region $REGION)
export ALB_NAME=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --output text --query 'LoadBalancers[*].LoadBalancerName'  --region $REGION)
echo $ALB_NAME
export ASG_ARN=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[*].AutoScalingGroupARN' --output text --region $REGION)
echo $ASG_ARN

aws iam create-role --role-name $TASK_ROLE_NAME --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --region $REGION
aws iam attach-role-policy --role-name $TASK_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy --region $REGION
export TASK_ROLE_ARN=$(aws iam get-role --role-name DemoEcsTaskRole --query 'Role.Arn' --output text --region $REGION)
echo $TASK_ROLE_ARN

sed -ie "s#THIS_TASK_ROLE_ARN#$TASK_ROLE_ARN#g" ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
sed -ie "s#TASK_FAMILY#$TASK_FAMILY#g"          ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
sed -ie "s#CONTAINER_PORT#$CONTAINER_PORT#g"    ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
sed -ie "s#CONTAINER_IMAGE#$CONTAINER_IMAGE#g"  ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
sed -ie "s#PAGE_COLOUR#$PAGE_COLOUR#g"          ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
sed -ie "s#TASK_NAME#$TASK_NAME#g"              ./EcsTaskDefinitions/MyWebAppTaskDefinition.json

# aws ecs register-task-definition --cli-input-json file://./EcsTaskDefinitions/MyWebAppTaskDefinition.json --region $REGION
# export TASK_ARN=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY --query 'taskDefinitionArns[*]' --output text --region $REGION)
# echo $TASK_ARN

sed -ie "s#ECS_CLUSTER_NAME#$ECS_CLUSTER_NAME#g" ./ECS_Service.json
sed -ie "s#SERVICE_NAME#$SERVICE_NAME#g" ./ECS_Service.json
# sed -ie "s#TASK_DEFINITION#$TASK_ARN#g" ./ECS_Service.json
sed -ie "s#TG_ARN#$TG_ARN#g" ./ECS_Service.json
sed -ie "s#CONTAINER_NAME#$CONTAINER_NAME#g" ./ECS_Service.json
sed -ie "s#CONTAINER_PORT#$CONTAINER_PORT#g" ./ECS_Service.json

# aws ecs create-service --cli-input-json file://./ECS_Service.json --region $REGION

# ALB_ARN=$(aws cloudformation describe-stack-resource --stack-name $CFN_STACK --logical-resource-id LoadBalancer --query 'StackResourceDetail.PhysicalResourceId' --output text --region $REGION)
# aws elbv2 describe-load-balancers --load-balancer-arns ${ALB_ARN} --query 'LoadBalancers[*].DNSName' --output text | sed -e 's#.*#http://&#g'
