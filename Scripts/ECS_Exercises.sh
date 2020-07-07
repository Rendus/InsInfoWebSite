#!/bin/bash

PROCEED='n'

InitialSetupLocation='./InitialSetup.sh'
read -p "This script requires resources created by script InitialSetup.sh. Provide the location of script \"InitialSetup.sh\" like \"/tmp/mydir/InitialSetup.sh\" to proceed further.
Default is \"./InitialSetup.sh\": " InitialSetupLocation

source ./InitialSetup.sh

aws ecs register-task-definition --cli-input-json file://./EcsTaskDefinitions/MyWebAppTaskDefinition.json --region $REGION
export TASK_ARN=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY --query 'taskDefinitionArns[-1]' --output text --region $REGION)
echo $TASK_ARN

VPCID=$(aws cloudformation describe-stack-resource --stack-name $CFN_STACK --logical-resource-id 'Vpc' --query 'StackResourceDetail.PhysicalResourceId' --output text --region $REGION)
echo $VPCID

##################### Exercise - 1 ########################
read -p "Create resource for Exercise 1 (y/n)" PROCEED?
if [[ $PROCEED != 'y' ]] || [[ $PROCEED != 'Y' ]]; then Exit 1; fi

EX1_SERVICE_NAME='InsInfoService-EX-1'

EX1_TG_ARN=$(aws elbv2 create-target-group --name InsInfo-TG-EX-1 --protocol HTTP --port 80 --target-type instance --vpc-id $VPCID --health-check-path '/CpuStressTest.php' --region $REGION --query 'TargetGroups[*].TargetGroupArn' --output text)

LISTNER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query 'Listeners[0].ListenerArn' --output text --region $REGION)
echo $LISTNER_ARN

aws elbv2 create-rule --listener-arn $LISTNER_ARN --priority 2 --conditions '[{"Field": "path-pattern", "PathPatternConfig": {"Values": ["/CpuStressTest.php/*"]}}]' --actions Type=forward,TargetGroupArn=$EX1_TG_ARN --region $REGION

curl -s -o EX1_ECS_Service.json https://raw.githubusercontent.com/santosh07bec/InsInfoWebSite/master/ECS_Service.json 

sed -i '.org' -e "s#ECS_CLUSTER_NAME#$ECS_CLUSTER_NAME#g" -e "s#TASK_DEFINITION#$TASK_ARN#g"  -e "s#CONTAINER_NAME#$CONTAINER_NAME#g" -e "s#CONTAINER_PORT#$CONTAINER_PORT#g" -e "s#SERVICE_NAME#$EX1_SERVICE_NAME#g" -e "s#TG_ARN#$EX1_TG_ARN#g" ./EX1_ECS_Service.json
sed -ie '4 i\
    "launchType": "EC2",
    ' ./EX1_ECS_Service.json

aws ecs create-service --cli-input-json file://./EX1_ECS_Service.json --region $REGION

##################### Exercise - 2 ########################
read -p "Create resource for Exercise 2 (y/n)" PROCEED?
if [[ $PROCEED != 'y' ]] || [[ $PROCEED != 'Y' ]]; then Exit 1; fi

EX2_SERVICE_NAME='InsInfoService-EX-2'

cat EcsTaskDefinitions/MyWebAppTaskDefinition.json | jq '.containerDefinitions[1] += {"name": "MyDemoContainer", "image": "amazonlinux:2", "essential": true, "command": ["sleep", "60"]}' > EcsTaskDefinitions/EX2_MyWebAppTaskDefinition.json
aws ecs register-task-definition --cli-input-json file://./EcsTaskDefinitions/EX2_MyWebAppTaskDefinition.json --region $REGION
export EX2_TASK_ARN=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY --query 'taskDefinitionArns[-1]' --output text --region $REGION)
echo $EX2_TASK_ARN

curl -s -o EX2_ECS_Service.json https://raw.githubusercontent.com/santosh07bec/InsInfoWebSite/master/ECS_Service.json 

sed -i '.org' -e "s#ECS_CLUSTER_NAME#$ECS_CLUSTER_NAME#g" -e "s#TASK_DEFINITION#$EX2_TASK_ARN#g"  -e "s#CONTAINER_NAME#$CONTAINER_NAME#g" -e "s#CONTAINER_PORT#$CONTAINER_PORT#g" -e "s#SERVICE_NAME#$EX2_SERVICE_NAME#g" -e "s#TG_ARN#$TG_ARN#g" ./EX2_ECS_Service.json

aws ecs create-service --cli-input-json file://./EX2_ECS_Service.json --region $REGION

##################### Exercise - 3 ########################
read -p "Create resource for Exercise 3 (y/n)" PROCEED?
if [[ $PROCEED != 'y' ]] || [[ $PROCEED != 'Y' ]]; then Exit 1; fi

EX3_SERVICE_NAME='InsInfoService-EX-3'

cat EcsTaskDefinitions/MyWebAppTaskDefinition.json | jq '.containerDefinitions[1] += {"name": "MyDemoContainer", "image": "amazonlinux:2.0", "essential": true, "command": ["sleep", "60"]}' > EcsTaskDefinitions/EX3_MyWebAppTaskDefinition.json
aws ecs register-task-definition --cli-input-json file://./EcsTaskDefinitions/EX3_MyWebAppTaskDefinition.json --region $REGION
export EX3_TASK_ARN=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY --query 'taskDefinitionArns[-1]' --output text --region $REGION)
echo $EX3_TASK_ARN

EX3_TG_ARN=$(aws elbv2 create-target-group --name InsInfo-TG-EX-3 --protocol HTTP --port 80 --target-type instance --vpc-id $VPCID --health-check-path '/' --region $REGION --query 'TargetGroups[*].TargetGroupArn' --output text)

aws elbv2 create-rule --listener-arn $LISTNER_ARN --priority 3 --conditions '[{"Field": "path-pattern", "PathPatternConfig": {"Values": ["/index.php/*"]}}]' --actions Type=forward,TargetGroupArn=$EX3_TG_ARN --region $REGION

curl -s -o EX3_ECS_Service.json https://raw.githubusercontent.com/santosh07bec/InsInfoWebSite/master/ECS_Service.json 
sed -i '.org' -e "s#ECS_CLUSTER_NAME#$ECS_CLUSTER_NAME#g" -e "s#TASK_DEFINITION#$EX3_TASK_ARN#g"  -e "s#CONTAINER_NAME#$CONTAINER_NAME#g" -e "s#CONTAINER_PORT#$CONTAINER_PORT#g" -e "s#SERVICE_NAME#$EX3_SERVICE_NAME#g" -e "s#TG_ARN#$EX3_TG_ARN#g" ./EX3_ECS_Service.json

aws ecs create-service --cli-input-json file://./EX3_ECS_Service.json --region $REGION

##################### Exercise - 4 ########################
read -p "Create resource for Exercise 4 (y/n)" PROCEED?
if [[ $PROCEED != 'y' ]] || [[ $PROCEED != 'Y' ]]; then Exit 1; fi

EX4_SERVICE_NAME='InsInfoService-EX-4'

curl -s -o EX4_ECS_Service.json_1 https://raw.githubusercontent.com/santosh07bec/InsInfoWebSite/master/ECS_Service.json
sed -i '.org' -e "s#ECS_CLUSTER_NAME#$ECS_CLUSTER_NAME#g" -e "s#TASK_DEFINITION#$TASK_ARN#g"  -e "s#CONTAINER_NAME#$CONTAINER_NAME#g" -e "s#CONTAINER_PORT#$CONTAINER_PORT#g" -e "s#SERVICE_NAME#$EX4_SERVICE_NAME#g" -e "s#TG_ARN#$TG_ARN#g" ./EX4_ECS_Service.json_1
cat ./EX4_ECS_Service.json_1 | jq '. + {"placementConstraints": []}' | jq '.placementConstraints[0] += {"expression": "attribute:stack == Production", "type": "memberOf"}' > EX4_ECS_Service.json
rm -f ./EX4_ECS_Service.json_1

ECS_INSTANCES=$(aws ecs list-container-instances --cluster $ECS_CLUSTER_NAME --query 'containerInstanceArns[*]' --output text --region $REGION)
for INSTANCE in $ECS_INSTANCES; do aws ecs put-attributes --attributes name=stack,value=production,targetId=$INSTANCE --cluster $ECS_CLUSTER_NAME --region $REGION; done

aws ecs create-service --cli-input-json file://./EX4_ECS_Service.json --region $REGION

##################### Exercise - 5 ########################
read -p "Create resource for Exercise 5 (y/n)" PROCEED?
if [[ $PROCEED != 'y' ]] || [[ $PROCEED != 'Y' ]]; then Exit 1; fi

EX5_SERVICE_NAME='InsInfoService-EX-5'

DEFAULT_SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=default Name=vpc-id,Values=$VPCID --query 'SecurityGroups[*].GroupId' --region $REGION --output text)
ECS_SG1=$(aws cloudformation describe-stack-resource --stack-name $CFN_STACK --logical-resource-id 'EcsSecurityGroup' --query 'StackResourceDetail.PhysicalResourceId' --output text --region $REGION)
VPCCIDR=$(aws ec2 describe-vpcs --vpc-ids $VPCID --query 'Vpcs[*].CidrBlock' --output text --region $REGION)
RT=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPCID --query 'RouteTables[*].RouteTableId' --output text --region $REGION)
IAMPROFILE=$(aws cloudformation describe-stack-resource --stack-name $CFN_STACK --logical-resource-id 'EcsInstanceProfile' --query 'StackResourceDetail.PhysicalResourceId' --output text --region $REGION)

aws ec2 authorize-security-group-ingress --group-id $DEFAULT_SG --protocol tcp --port 443 --cidr $VPCCIDR --region $REGION
PRI_SUB_1=$(aws ec2 create-subnet --vpc-id $VPCID --availability-zone us-east-1a --cidr-block '10.0.202.0/24' --output text --query 'Subnet.SubnetId' --region $REGION)
PRI_SUB_2=$(aws ec2 create-subnet --vpc-id $VPCID --availability-zone us-east-1b --cidr-block '10.0.203.0/24' --output text --query 'Subnet.SubnetId' --region $REGION)

VPCEID1=$(aws ec2 create-vpc-endpoint --vpc-id $VPCID --vpc-endpoint-type Interface --service-name com.amazonaws.$REGION.ecr.api --subnet-ids $PRI_SUB_1 $PRI_SUB_2 --security-group-ids $DEFAULT_SG $ECS_SG1 --query 'VpcEndpoint.VpcEndpointId' --output text --region $REGION)
VPCEID2=$(aws ec2 create-vpc-endpoint --vpc-id $VPCID --vpc-endpoint-type Interface --service-name com.amazonaws.$REGION.ecr.dkr --subnet-ids $PRI_SUB_1 $PRI_SUB_2 --security-group-ids $DEFAULT_SG $ECS_SG1 --query 'VpcEndpoint.VpcEndpointId' --output text --region $REGION)
VPCEID3=$(aws ec2 create-vpc-endpoint --vpc-id $VPCID --service-name com.amazonaws.$REGION.s3 --route-table-ids $RT --region $REGION --query 'VpcEndpoint.VpcEndpointId' --output text)

echo -e '#!/bin/bash\necho "ECS_CLUSTER='${ECS_CLUSTER_NAME}'">> /etc/ecs/ecs.config' > ./User_Data.txt 

PRI_INS_ID1=$(aws ec2 run-instances --image-id ami-0f646559bb4969174 --instance-type t2.medium --key-name MyDemoKeyPair --security-group-ids $DEFAULT_SG $ECS_SG1  --subnet-id $PRI_SUB_1 --user-data file://./User_Data.txt --iam-instance-profile Name=$IAMPROFILE --query 'Instances[*].InstanceId' --output text --region $REGION)
PRI_INS_ID2=$(aws ec2 run-instances --image-id ami-0f646559bb4969174 --instance-type t2.medium --key-name MyDemoKeyPair --security-group-ids $DEFAULT_SG $ECS_SG1  --subnet-id $PRI_SUB_2 --user-data file://./User_Data.txt --iam-instance-profile Name=$IAMPROFILE --query 'Instances[*].InstanceId' --output text --region $REGION)

##################### Exercise - 6 ########################
read -p "Create resource for Exercise 6 (y/n)" PROCEED?
if [[ $PROCEED != 'y' ]] || [[ $PROCEED != 'Y' ]]; then Exit 1; fi

EX6_SERVICE_NAME='InsInfoService-EX-6'

VPCEID4=$(aws ec2 create-vpc-endpoint --vpc-id $VPCID --vpc-endpoint-type Interface --service-name com.amazonaws.$REGION.ecs --subnet-ids $PRI_SUB_1 $PRI_SUB_2 --security-group-ids $DEFAULT_SG $ECS_SG1 --query 'VpcEndpoint.VpcEndpointId' --output text --region $REGION)
VPCEID5=$(aws ec2 create-vpc-endpoint --vpc-id $VPCID --vpc-endpoint-type Interface --service-name com.amazonaws.$REGION.ecs-agent --subnet-ids $PRI_SUB_1 $PRI_SUB_2 --security-group-ids $DEFAULT_SG $ECS_SG1 --query 'VpcEndpoint.VpcEndpointId' --output text --region $REGION)
VPCEID6=$(aws ec2 create-vpc-endpoint --vpc-id $VPCID --vpc-endpoint-type Interface --service-name com.amazonaws.$REGION.ecs-telemetry --subnet-ids $PRI_SUB_1 $PRI_SUB_2 --security-group-ids $DEFAULT_SG $ECS_SG1 --query 'VpcEndpoint.VpcEndpointId' --output text --region $REGION)

ECSINSTANCES=$(aws ecs list-container-instances --cluster $ECS_CLUSTER_NAME --filter 'not(attribute:stack == production)' --query 'containerInstanceArns' --output text --region $REGION)
for INSTANCE in $ECSINSTANCES; do aws ecs put-attributes --attributes name=stack,value=InsInfoApp,targetId=$INSTANCE --cluster $ECS_CLUSTER_NAME --region $REGION; done

MyECRImage='342241566140.dkr.ecr.us-east-1.amazonaws.com/php_apache/web_image:with_improved_php_scripts_colour_env_var_logging_and_404_v5'

read -p "Exercise 6 needs to use a docker image from your ECR repo in $REGION region. Please provide docker image URL to proceed further: " MyECRImage

cat EcsTaskDefinitions/MyWebAppTaskDefinition.json | jq '.containerDefinitions[0] += {"image": "342241566140.dkr.ecr.us-east-1.amazonaws.com/php_apache/web_image:with_improved_php_scripts_colour_env_var_logging_and_404_v5"}' | jq --arg R $REGION  '.containerDefinitions[0] += {"logConfiguration": {"logDriver": "awslogs", "options": {"awslogs-group": "/ecs/MyDemoTask", "awslogs-region": $R, "awslogs-stream-prefix": "ecs"}}}' > EcsTaskDefinitions/EX6_MyWebAppTaskDefinition.json
aws ecs register-task-definition --cli-input-json file://./EcsTaskDefinitions/EX6_MyWebAppTaskDefinition.json --region $REGION
export EX6_TASK_ARN=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY --query 'taskDefinitionArns[-1]' --output text --region $REGION)
echo $EX6_TASK_ARN

curl -s -o EX6_ECS_Service.json_1 https://raw.githubusercontent.com/santosh07bec/InsInfoWebSite/master/ECS_Service.json
sed -i '.org' -e "s#ECS_CLUSTER_NAME#$ECS_CLUSTER_NAME#g" -e "s#TASK_DEFINITION#$EX6_TASK_ARN#g"  -e "s#CONTAINER_NAME#$CONTAINER_NAME#g" -e "s#CONTAINER_PORT#$CONTAINER_PORT#g" -e "s#SERVICE_NAME#$EX6_SERVICE_NAME#g" -e "s#TG_ARN#$TG_ARN#g" ./EX6_ECS_Service.json_1
cat ./EX6_ECS_Service.json_1 | jq '. + {"placementConstraints": []}' | jq '.placementConstraints[0] += {"expression": "attribute:stack == InsInfoApp", "type": "memberOf"}' > EX6_ECS_Service.json
rm -f ./EX6_ECS_Service.json_1

aws ecs create-service --cli-input-json file://./EX6_ECS_Service.json --region $REGION

##################### CleanUp #############################
echo -e "\nUse below commands to cleanup resources created in this script\n\n
RULES_ARN=$(aws elbv2 describe-rules --listener-arn $LISTNER_ARN --output text --query 'Rules[*].RuleArn' --region $REGION)
for RULE in $RULES_ARN; do aws elbv2 delete-rule --rule-arn $RULE --region $REGION; done

aws elbv2 delete-target-group --target-group-arn $EX1_TG_ARN --region $REGION
aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $EX1_SERVICE_NAME --desired-count 0 --region $REGION
aws ecs delete-service --cluster $ECS_CLUSTER_NAME --service $EX1_SERVICE_NAME --force --region $REGION
aws ecs deregister-task-definition --task-definition $TASK_ARN --region $REGION

aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $EX2_SERVICE_NAME --desired-count 0 --region $REGION
aws ecs delete-service --cluster $ECS_CLUSTER_NAME --service $EX2_SERVICE_NAME --force --region $REGION
aws ecs deregister-task-definition --task-definition $EX2_TASK_ARN --region $REGION

aws elbv2 delete-target-group --target-group-arn $EX3_TG_ARN --region $REGION
aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $EX3_SERVICE_NAME --desired-count 0 --region $REGION
aws ecs delete-service --cluster $ECS_CLUSTER_NAME --service $EX3_SERVICE_NAME --force --region $REGION
aws ecs deregister-task-definition --task-definition $EX3_TASK_ARN --region $REGION

aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $EX4_SERVICE_NAME --desired-count 0 --region $REGION
aws ecs delete-service --cluster $ECS_CLUSTER_NAME --service $EX4_SERVICE_NAME --force --region $REGION

aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $EX6_SERVICE_NAME --desired-count 0 --region $REGION
aws ecs delete-service --cluster $ECS_CLUSTER_NAME --service $EX6_SERVICE_NAME --force --region $REGION
aws ecs deregister-task-definition --task-definition $EX6_TASK_ARN --region $REGION
aws ec2 terminate-instances --instance-ids $PRI_INS_ID1 $PRI_INS_ID2 --region $REGION
aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $VPCEID1 $VPCEID2 $VPCEID3 $VPCEID4 $VPCEID5 $VPCEID6 --region $REGION

aws ec2 delete-subnet --subnet-id $PRI_SUB_1 --region $REGION
aws ec2 delete-subnet --subnet-id $PRI_SUB_2 --region $REGION
"
