#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/scripts/defaults.sh

logs_dir=$SCRIPT_DIR/logs
mkdir $logs_dir
logfile="$logs_dir/destroy.log"
echo "" > $logfile

echo "stopping all tasks" | tee -a $logfile
aws ecs update-service --cluster $cluster_name --task-definition $taskdefinition_name --service $service_name --desired-count 0 | tee -a $logfile
echo "sleep for a bit to let the task stop" | tee -a $logfile
count=30
while (( --count > 0 )); do
  echo $count;sleep 1
done

echo "deleting the ${service_name} service"  | tee -a $logfile
aws ecs delete-service --cluster $cluster_name --service $service_name --force | tee -a $logfile
echo "sleeping for a bit to let the service fully drain" | tee -a $logfile
count=30
while (( --count > 0 )); do
  echo $count;sleep 1
done

echo "deregistering the ${taskdefinition_name} task definitions"  | tee -a $logfile
task_defs=$(aws ecs list-task-definitions --family-prefix $family --status "ACTIVE" \
--query "taskDefinitionArns" --output text)
array=($(echo $task_defs | tr ',' "\n"))
for i in "${array[@]}"
do
   echo "deregistering: $i" | tee -a $logfile
   aws ecs deregister-task-definition --task-definition $i | tee -a $logfile
done

echo "deleting the ${cluster_name} ECS cluster" | tee -a $logfile
aws ecs delete-cluster --cluster $cluster_name | tee -a $logfile

echo "detaching the ${policy_arn} from the ${role_name} role" | tee -a $logfile
aws iam detach-role-policy --role-name $role_name --policy-arn $policy_arn | tee -a $logfile

echo "deleting the ${role_name} role" | tee -a $logfile
aws iam delete-role --role-name $role_name | tee -a $logfile

echo "deleting the ${policy_arn} policy" | tee -a $logfile
aws iam delete-policy --policy-arn $policy_arn | tee -a $logfile

echo "Detailed logs are in ${logfile}" |tee -a $logfile
echo "End of script" | tee -a $logfile

function check_resources {
    resource_type=$1
    resource_name=$2
    search_string=$3
    result=$4
    outcome="FAIL"
    if [[ 0 -eq $result ]];then
        outcome="PASS"
    fi
    echo "${outcome}: ${resource_type} named: ${resource_name}" | tee -a $logfile
}

# CONFIRM RESOURCES DESTROYED
cluster_check=$(aws ecs list-clusters \
--query "clusterArns[?ends_with(@,'$cluster_name')]|[0]" --output text | grep -iv "None" | wc -l)
check_resources "ECS_cluster" $cluster_name $cluster_name $cluster_check

service_check=$(aws ecs list-services --cluster $cluster_name \
--query "serviceArns[?ends_with(@,'$service_name')]|[0]" --output text | grep -iv "None" | wc -l)
check_resources "ECS_service" $service_name $service_name $service_check

# task_def_check=$(aws ecs list-task-definitions --family-prefix $family --status "ACTIVE" \
# --query "taskDefinitionArns" --output text | wc -l)
# check_resources "ECS_task_definition" $taskdefinition_name $taskdefinition_name $task_def_check

role_check=$(aws iam list-roles \
--query "Roles[?RoleName=='$role_name']" --output text | wc -l)
check_resources "Task_role" $role_name $role_name $role_check

policy_check=$(aws iam list-policies --scope "Local" \
--query "Policies[?PolicyName=='$policy_name']" --output text | wc -l)