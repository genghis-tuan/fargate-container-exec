#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/defaults.sh

while [ $# -gt 0 ]; do
  case "$1" in
    --role_name*|-r*)
      if [[ "$1" != *=* ]]; then shift; fi
      role_name="${1#*=}"
      ;;
    --policy_name*|-p*)
      if [[ "$1" != *=* ]]; then shift; fi
      policy_name="${1#*=}"
      ;;
    --help|-h)
      printf "\
USE:\n\
--role_name or -r for the role name input\n\
--policy_name or -p for the policy name\n"
      exit 0
      ;;
    *)
      >&2 printf "Error: Invalid argument\n"
      exit 1
      ;;
  esac
  shift
done


aws iam create-role \
--role-name $role_name \
--assume-role-policy-document '{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}'

aws iam create-policy \
--policy-name $policy_name \
--policy-document '{ 
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": ["*"]
        }
    ]
}'

aws iam attach-role-policy \
--role-name $role_name \
--policy-arn $policy_arn