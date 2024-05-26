#! /bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/defaults.sh

container_definitions="[\
{\"name\":\"$container_name\",\
\"image\":\"$image\",\
\"cpu\":512,\
\"command\":[\"sleep\",\"3600\"],\
\"memory\":1024,\
\"essential\":true}\
]"

while [ $# -gt 0 ]; do
  case "$1" in
    --family_name*|-f*)
      if [[ "$1" != *=* ]]; then shift; fi # Value is next arg if no `=`
      family_name="${1#*=}"
      ;;
    --container_name*|-c*)
      if [[ "$1" != *=* ]]; then shift; fi
      container_name="${1#*=}"
      ;;
    --image*|-i*)
      if [[ "$1" != *=* ]]; then shift; fi
      image="${1#*=}"
      ;;      
    --help|-h)
      printf "\
USE:\n\
--family_name or -f for the task definition family input\n\
--container_name or -c for the container name input\n\
--image or -i for the image input\n"
      exit 0
      ;;
    *)
      >&2 printf "Error: Invalid argument\n"
      exit 1
      ;;
  esac
  shift
done

task_role_arn="arn:aws:iam::${account_id}:role/${task_role_name}"

aws ecs register-task-definition \
--family $family \
--container-definitions $container_definitions \
--network-mode "awsvpc" \
--requires-compatibilities "FARGATE" \
--cpu "512" \
--memory "1024" \
--task-role-arn $task_role_arn