# Instructions to use this repo

1. Clone this Repo
    ```
    cd ~
    git clone https://github.com/santosh07bec/MyTestWebSite.git
    cd MyTestWebSite
    ```
1. Define Parameters
    ```
    export KEYPAIR="MyDemoKeyPair"
    export CFN_STACK="InsInfoCluster"
    export CP_NAME="MyDemoProvider-$(date +%d%m%Y-%H%M%S)"
    export TASK_ROLE_NAME="DemoEcsTaskRole"
    export TASK_FAMILY="MyDemoTask"
    export TASK_NAME=$TASK_FAMILY
    export CONTAINER_PORT=80
    export CONTAINER_IMAGE='342241566140.dkr.ecr.us-east-1.amazonaws.com/php_apache/web_image:with_improved_php_scripts_colour_env_variable_and_logging_v4'
    export PAGE_COLOUR='Blue'
    export INSTANCE_TYPE='t2.medium'
    ```
1. Create EC2 KeyPair
    ```
    aws ec2 create-key-pair --key-name $KEYPAIR --query 'KeyMaterial' --output text > $KEYPAIR.pem
    chmod 400 $KEYPAIR.pem

    ```
1. Create ECS Cluster and EC2 Resources required to create ECS Services
    ```
    export ECS_AMI_ID=$(aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux/recommended/image_id --query 'Parameters[*].Value' --output text)
    echo $ECS_AMI_ID
    aws cloudformation create-stack --stack-name $CFN_STACK --template-body file://./CFNTemplate/ECS_Cluster.yaml  --parameters ParameterKey=AsgMaxSize,ParameterValue=5 ParameterKey=EcsAmiId,ParameterValue=$ECS_AMI_ID ParameterKey=EcsInstanceType,ParameterValue=$INSTANCE_TYPE ParameterKey=KeyName,ParameterValue=$KEYPAIR --capabilities CAPABILITY_NAMED_IAM
    ```
1. Check status of CFN and confirm it's creation is complete
    ```
    aws cloudformation describe-stacks --stack-name $CFN_STACK
    ```
1. Get ECS Cluster Name
    ```
    export ECS_CLUSTER_NAME=$(aws cloudformation describe-stack-resource --stack-name $CFN_STACK --logical-resource-id MyEcsCluster --query 'StackResourceDetail.PhysicalResourceId' --output text)
    echo $ECS_CLUSTER_NAME
    ```
1. Get the name of ASG created by above CFN Stack
    ```
    export ASG_NAME=$(aws cloudformation describe-stack-resource --stack-name $CFN_STACK --logical-resource-id EcsInstanceAsg --query 'StackResourceDetail.PhysicalResourceId' --output text)
    echo $ASG_NAME
    ```
1. Get the ARN of ASG created by above CFN Stack
    ```
    export ASG_ARN=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $(aws cloudformation describe-stack-resource --stack-name MyDemoStack --logical-resource-id EcsInstanceAsg --query 'StackResourceDetail.PhysicalResourceId' --output text | xargs) --query 'AutoScalingGroups[*].AutoScalingGroupARN' --output text)
    echo $ASG_ARN
    ```
1. Enable Instance Termination Protection on ASG and on ASG Instances
    ```
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --new-instances-protected-from-scale-in
    ASG_INSTANCES=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --output text --query 'AutoScalingGroups[*].Instances[*].InstanceId')
    echo $ASG_INSTANCES
    for INS in $ASG_INSTANCES; do aws autoscaling set-instance-protection --instance-ids $INS --auto-scaling-group-name $ASG_NAME --protected-from-scale-in; done
    ```
1. Create ECS Cluster Capacity Provide
    ```
    aws ecs create-capacity-provider --name $CP_NAME --auto-scaling-group-provider "autoScalingGroupArn=${ASG_ARN},managedScaling={status=ENABLED,targetCapacity=10,minimumScalingStepSize=1,maximumScalingStepSize=2},managedTerminationProtection=ENABLED"
    ```
1. Associate the Cluster Capacity Provider with the ECS Cluster
    ```
    aws ecs put-cluster-capacity-providers --cluster $ECS_CLUSTER_NAME --capacity-providers $CP_NAME --default-capacity-provider-strategy capacityProvider=$CP_NAME,weight=1,base=1
    ```

1. Varify if Cluster Capacity Provider was associated with ECS Cluster Properly
    ```
    aws ecs describe-clusters --clusters $ECS_CLUSTER_NAME
    ```
1. Create a IAM role for Task and attach "AmazonECSTaskExecutionRolePolicy" policy to it
    ```
    aws iam create-role --role-name $TASK_ROLE_NAME --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
    aws iam attach-role-policy --role-name $TASK_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
    export TASK_ROLE_ARN=$(aws iam get-role --role-name DemoEcsTaskRole --query 'Role.Arn' --output text)
    echo $TASK_ROLE_ARN
    ```
1. Change Role Arn in Task Definition
    ```
    sed -ie "s#THIS_TASK_ROLE_ARN#$TASK_ROLE_ARN/g" ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    ```
1. Register Task Definition
    ```
    sed -ie "s#TASK_FAMILY#$TASK_FAMILY#g" ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    sed -ie "s#CONTAINER_PORT#$CONTAINER_PORT#g"   ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    sed -ie "s#CONTAINER_IMAGE#$CONTAINER_IMAGE#g" ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    sed -ie "s#PAGE_COLOUR#$PAGE_COLOUR#g"         ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    sed -ie "s#TASK_NAME#$TASK_NAME#g"             ./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    aws ecs register-task-definition --cli-input-json file://./EcsTaskDefinitions/MyWebAppTaskDefinition.json
    ```
1. Run a task with registered Task Definition
    ```
    aws ecs run-task --cluster $ECS_CLUSTER_NAME --task-definition $TASK_NAME:1
    ```

Create ELB
Create Service with that
Update ASG to use Spot

Update Cluster provider with FARGET and FARGET_SPOT Providers
Create a Task Definition with Farget
Create Task with it.
Create a new service with fargate
Create a new service with fargate spot
