#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/scripts/defaults.sh

logs_dir=$SCRIPT_DIR/logs
mkdir $logs_dir
logfile="$logs_dir/create.log"
echo "" > $logfile

echo "checking prerequisites" | tee -a $logfile
plugin_check_result=$(session-manager-plugin | grep "$expected_output" | wc -l)
if [[ $plugin_check_result -lt 1 ]]; then
    echo -e "${YELLOW}Hey, it looks like you might not have the session-manager plugin installed.${NC}" 
    echo -e "It is a requirement to exec into a Fargate task's container." 
    echo -e "You can download it from the AWS official site:
    ${BLUE}https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html${NC}"
    echo "While the plugin is NOT required for this infrastructure setup, the setup won't serve its demo purpose without it."
    printf "${RED}Enter C to (C)ontinue or any other character to exit:  ${NC}"
    read choice
    if [ "$choice" != "${choice#[Cc]}" ] ;then 
        echo "OK continue..."; sleep 2
    else
        echo "Gotcha, exiting...";sleep 2
        exit
    fi
else
    echo "The prerequisites were satisified. Continuing with the infrastructure setup."
    sleep 2
fi

if [[ -z "$subnets" ]]; then
    echo -e "${RED}OOPS! IT LOOKS LIKE THE subnets VARIABLE IS NOT SET."
    echo -e "Please set the variable in ${SCRIPT_DIR}/scripts/defaults.sh and rerun this this script"
    echo -e "Exiting...${NC}"
    exit
fi 

echo "creating cluster ${cluster_name}" | tee -a $logfile 
$SCRIPT_DIR/scripts/create_cluster.sh -c $cluster_name >> $logfile

echo "creating role:${role_name} and policy:${policy_name}" | tee -a $logfile 
$SCRIPT_DIR/scripts/create_iam.sh -r $role_name -p $policy_name >> $logfile 

echo "creating task_definition:${taskdefinition_name} with container_name:${container_name}" | tee -a $logfile 
$SCRIPT_DIR/scripts/create_task_definition.sh -c $container_name -f $taskdefinition_name -i $image >> $logfile

echo "creating service:${service_name}" | tee -a $logfile 
$SCRIPT_DIR/scripts/create_service.sh -s $service_name -c $cluster_name -t $taskdefinition_name -n $subnets -g $security_groups >> $logfile 

echo "sleeping for a bit for the task to start" | tee -a $logfile 
count=30
while (( --count > 0 )); do
  echo $count;sleep 1
done

function check_resources {
    resource_type=$1
    resource_name=$2
    search_string=$3
    result=$4
    outcome="FAIL"
    if [[ 1 -eq $result ]];then
        outcome="PASS"
    fi
    echo "${outcome}: ${resource_type} named: ${resource_name}" | tee -a $logfile
}

# CONFIRM RESOURCES CREATED
cluster_check=$(aws ecs list-clusters \
--query "clusterArns[?ends_with(@,'$cluster_name')]|[0]" --output text | grep -iv "None" | wc -l)
check_resources "ECS_cluster" $cluster_name $cluster_name $cluster_check

service_check=$(aws ecs list-services --cluster $cluster_name \
--query "serviceArns[?ends_with(@,'$service_name')]|[0]" --output text | grep -iv "None" | wc -l)
check_resources "ECS_service" $service_name $service_name $service_check

task_def_check=$(aws ecs list-task-definitions --family-prefix $family --status "ACTIVE" \
--query "taskDefinitionArns" --output text | wc -l)
check_resources "ECS_task_definition" $taskdefinition_name $taskdefinition_name $task_def_check

role_check=$(aws iam get-role --role-name $role_name \
--query "Role.RoleName=='$role_name'" --output text | grep -i "true" | wc -l)
check_resources "Task_role" $role_name $role_name $role_check

policy_check=$(aws iam get-policy --policy-arn $policy_arn \
--query "Policy.PolicyName=='$policy_name'" --output text | grep -i true | wc -l)

task_id=$(aws ecs list-tasks --cluster $cluster_name --service-name $service_name --output text | cut -d'/' -f3 | tee -a $logfile)
echo "This is the task ID: ${task_id}" | tee -a $logfile
echo -e "${RED}USE THIS COMMAND TO exec into the container:${NC}"  | tee -a $logfile
echo -e "${BLUE}aws ecs execute-command \\
--cluster fargate_docker_exec \\
--task ${task_id} \\
--container ${container_name} \\
--interactive --command bash${NC}" | tee -a $logfile
echo "" | tee -a $logfile

echo -e "${YELLOW}
*** THE RESOURCES CREATED *** 
- ECS cluster:  ${cluster_name} 
- ECS service:  ${service_name} 
- ECS task_def: ${taskdefinition_name} 
- ECS task:     ${task_id} (the container name: ${container_name}) 
- IAM role:     ${role_name} 
- IAM policy    ${policy_name} 
${NC}" | tee -a $logfile

echo -e "\n${RED}Execute ./DESTROY.sh to destroy the resources.${NC}\n"

echo "Detailed logs are in ${logfile}" | tee -a $logfile
echo "End of script execution" | tee -a $logfile 
