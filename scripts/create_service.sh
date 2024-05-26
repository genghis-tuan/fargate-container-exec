#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/defaults.sh

while [ $# -gt 0 ]; do
  case "$1" in
    --cluster_name*|-c*)
      if [[ "$1" != *=* ]]; then shift; fi
      service_name="${1#*=}"
      ;;
    --service_name*|-s*)
      if [[ "$1" != *=* ]]; then shift; fi
      service_name="${1#*=}"
      ;;
    --taskdefinition_name*|-t*)
      if [[ "$1" != *=* ]]; then shift; fi
      taskdefinition_name="${1#*=}"
      ;;
    --subnets*|-n*)
      if [[ "$1" != *=* ]]; then shift; fi
      subnet="${1#*=}"
      ;;
    --security_groups*|-g*)
      if [[ "$1" != *=* ]]; then shift; fi
      security_groups="${1#*=}"
      ;;               
    --help|-h)
      printf "\
USE:\n\
--cluster_name or -c for the cluster name input\n\
--service_name or -s for the service name input\n\
--taskdefinition_name or -t for the taskdefinition name input\n\
--subnets or -n for the input of the subnet IDs list\n\
--security_groups or g for the input of the security group IDs"
      exit 0
      ;;
    *)
      >&2 printf "Error: Invalid argument\n"
      exit 1
      ;;
  esac
  shift
done

aws ecs create-service \
--cluster $cluster_name \
--service-name $service_name \
--task-definition $taskdefinition_name \
--desired-count 1 \
--launch-type "FARGATE" \
--network-configuration "awsvpcConfiguration={subnets=${subnets},securityGroups=${security_groups},assignPublicIp=ENABLED}" \
--enable-execute-command