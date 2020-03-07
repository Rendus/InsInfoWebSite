# Instructions for using this repository

### Prerequisite
1. Install and setup [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
1. Configure AWS CLI with an IAM user which has sufficient previledges for creating and deleteing EC2, ECS, ALB, CloudWatch and IAM resources.

### Usages Instruction
1. Clone this Repo
    ```
    cd ~
    git clone https://github.com/santosh07bec/InsInfoWebSite.git
    cd InsInfoWebSite
    ```
1. Define Parameters
    ```
    export REGION="us-east-1"
    export KEYPAIR="MyDemoKeyPair"
    export CFN_STACK="InsInfoCluster"
    export CP_NAME="MyDemoProvider-$(date +%d%m%Y-%H%M%S)"
    export TASK_ROLE_NAME="DemoEcsTaskRole"
    export TASK_FAMILY="MyDemoTask"
    export TASK_NAME=$TASK_FAMILY
    export CONTAINER_PORT=80
    export CONTAINER_NAME="$TASK_NAME"
    export CONTAINER_IMAGE='342241566140.dkr.ecr.us-east-1.amazonaws.com/php_apache/web_image:with_improved_php_scripts_colour_env_variable_and_logging_v4'
    export PAGE_COLOUR='Blue'
    export INSTANCE_TYPE='t2.medium'
    export SERVICE_NAME="InsInfoService"
    ```
1. Create EC2 KeyPair
    ```
    aws ec2 create-key-pair --key-name $KEYPAIR --query 'KeyMaterial' --output text --region $REGION  > $KEYPAIR.pem
    chmod 400 $KEYPAIR.pem

    ```
1. Get AMI ID and Create ECS and EC2 Resources using CFN Template
    ```
    export ECS_AMI_ID=$(aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux/recommended/image_id --query 'Parameters[*].Value' --output text --region $REGION)
    echo $ECS_AMI_ID
    
    aws cloudformation create-stack --stack-name $CFN_STACK --template-body file://./CFNTemplate/ECS_Cluster.yaml  --parameters ParameterKey=AsgMaxSize,ParameterValue=5 ParameterKey=EcsAmiId,ParameterValue=$ECS_AMI_ID ParameterKey=EcsInstanceType,ParameterValue=$INSTANCE_TYPE ParameterKey=KeyName,ParameterValue=$KEYPAIR --capabilities CAPABILITY_NAMED_IAM  --region $REGION
    ```
1. Check status of CFN and confirm it's creation is complete
    ```
    aws cloudformation describe-stacks --stack-name $CFN_STACK --region $REGION
    aws cloudformation describe-stacks --stack-name $CFN_STACK --region $REGION --output json --query 'Stacks[*].StackStatus' 
    ```
1. Initialize needed variables from CFN resources
    ```
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
    ```
1. Enable Instance Termination Protection on ASG and on existing ASG Instances
    ```
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --new-instances-protected-from-scale-in --region $REGION
    
    ASG_INSTANCES=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --output text --query 'AutoScalingGroups[*].Instances[*].InstanceId' --region $REGION)
    echo $ASG_INSTANCES
    
    for INS in $ASG_INSTANCES; do aws autoscaling set-instance-protection --instance-ids $INS --auto-scaling-group-name $ASG_NAME --protected-from-scale-in --region $REGION; done
    ```
1. Create ECS Cluster Capacity Provide
    ```
    aws ecs create-capacity-provider --name $CP_NAME --auto-scaling-group-provider "autoScalingGroupArn=${ASG_ARN},managedScaling={status=ENABLED,targetCapacity=10,minimumScalingStepSize=1,maximumScalingStepSize=2},managedTerminationProtection=ENABLED" --region $REGION
    ```
1. Associate the Cluster Capacity Provider with the ECS Cluster
    ```
    aws ecs put-cluster-capacity-providers --cluster $ECS_CLUSTER_NAME --capacity-providers $CP_NAME --default-capacity-provider-strategy capacityProvider=$CP_NAME,weight=1,base=1 --region $REGION
    ```

1. Varify if Cluster Capacity Provider was associated with ECS Cluster Properly
    ```
    aws ecs describe-clusters --clusters $ECS_CLUSTER_NAME --region $REGION
    ```
1. Create a IAM role for Task and attach "AmazonECSTaskExecutionRolePolicy" policy to it
    ```
    aws iam create-role --role-name $TASK_ROLE_NAME --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --region $REGION
    
    aws iam attach-role-policy --role-name $TASK_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy --region $REGION
    
    export TASK_ROLE_ARN=$(aws iam get-role --role-name DemoEcsTaskRole --query 'Role.Arn' --output text --region $REGION)
    echo $TASK_ROLE_ARN
    ```
1. Build Task Definition file
    ```
    sed -ie "s#THIS_TASK_ROLE_ARN#$TASK_ROLE_ARN#g" ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    sed -ie "s#TASK_FAMILY#$TASK_FAMILY#g"          ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    sed -ie "s#CONTAINER_PORT#$CONTAINER_PORT#g"    ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    sed -ie "s#CONTAINER_IMAGE#$CONTAINER_IMAGE#g"  ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    sed -ie "s#PAGE_COLOUR#$PAGE_COLOUR#g"          ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    sed -ie "s#TASK_NAME#$TASK_NAME#g"              ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    ```
1. Register Task Definition
    ```
    aws ecs register-task-definition --cli-input-json file://./EcsTaskDefinitions/MyWebAppTaskDefinition.json --region $REGION
    ```
1. Get Task Definition ARN
    ```
    export TASK_ARN=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY --query 'taskDefinitionArns[*]' --output text --region $REGION)
    echo $TASK_ARN
    ```
1. Run a task with registered Task Definition
    ```
    aws ecs run-task --cluster $ECS_CLUSTER_NAME --task-definition $TASK_ARN --region $REGION
    ```
1. Create an ECS Service File
    ```
    sed -ie "s#ECS_CLUSTER_NAME#$ECS_CLUSTER_NAME#g" ./ECS_Service.json
    sed -ie "s#SERVICE_NAME#$SERVICE_NAME#g" ./ECS_Service.json
    sed -ie "s#TASK_DEFINITION#$TASK_ARN#g" ./ECS_Service.json
    sed -ie "s#TG_ARN#$TG_ARN#g" ./ECS_Service.json
    sed -ie "s#CONTAINER_NAME#$CONTAINER_NAME#g" ./ECS_Service.json
    sed -ie "s#CONTAINER_PORT#$CONTAINER_PORT#g" ./ECS_Service.json
    ```
1. Create an ECS Service
    ```   
    aws ecs create-service --cli-input-json file://./ECS_Service.json --region $REGION
    ```
1. URL to view the webpage
    ```
    ALB_ARN=$(aws cloudformation describe-stack-resource --stack-name $CFN_STACK --logical-resource-id LoadBalancer --query
     'StackResourceDetail.PhysicalResourceId' --output text --region $REGION)
     aws elbv2 describe-load-balancers --load-balancer-arns ${ALB_ARN} --query 'LoadBalancers[*].DNSName' --output text | sed -e 's#.*#http://&#g'
    ```
1. Cleaning up resources
    ```
    aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $SERVICE_NAME --desired-count 0 --region $REGION
    sleep 30
    
    aws ecs delete-service --cluster $ECS_CLUSTER_NAME --service $SERVICE_NAME --force --region $REGION
    
    TASKS=$(aws ecs list-tasks --cluster $ECS_CLUSTER_NAME --output text --query 'taskArns[*]' --region $REGION)
    for TASK in $TASKS; do aws ecs stop-task --task $TASK --cluster $ECS_CLUSTER_NAME --region $REGION; done
    
    aws ecs deregister-task-definition --task-definition $TASK_ARN --region $REGION
    
    aws iam detach-role-policy --role-name $TASK_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy --region $REGION
    
    aws iam delete-role --role-name $TASK_ROLE_NAME --region $REGION
    
    ASG_INSTANCES=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --output text --query 'AutoScalingGroups[*].Instances[*].InstanceId' --region $REGION)
    for INS in $ASG_INSTANCES; do aws autoscaling set-instance-protection --instance-ids $INS --auto-scaling-group-name $ASG_NAME --no-protected-from-scale-in --region $REGION; done
    
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --no-new-instances-protected-from-scale-in --region $REGION
    
    aws ec2 delete-key-pair --key-name $KEYPAIR --region $REGION
    
    aws cloudformation delete-stack --stack-name $CFN_STACK --region $REGION
    ```
1. TODOs
    1. Service Role for ECS
    1. Update ASG to use Spot
    1. Update Cluster provider with FARGET and FARGET_SPOT Providers
    1. Create a Task Definition with Farget
    1. Create Task with it.
    1. Create a new service with fargate
    1. Create a new service with fargate spot
    1. AppMesh Integration
