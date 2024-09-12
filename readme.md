# A demonstration of running docker exec into containers running in ECS Fargate

- This demo uses public subnets. However, private subnets can be used if there is a bastion or VPN with access to the subnets.

- The scripts/defaults.sh contains all the default variables for the demo. However, the values can all be overridden.

## All infrastructure needed for the public subnet demo is created using by executing `CREATE.sh`

## All infrastructure created is destroyed by executing `DESTROY.sh`

## PREREQUISITES

1. Installation of [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
1. Installation of [session manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

## Outcome & Expectations

- upon successful execution of `CREATE.sh`, the terminal output will display the session manager command to exec into the container.
- the ECS task created is the Docker Hub version of `python:3.11-slim`. 
- the container simply runs the `sleep 3600` command so that we have time to test out the docker exec functionality.

## What is created

- an ECS cluster
- an ECS task definition
- an IAM role set in the ECS task definition as the `task_role`
- an IAM policy that is attached to the IAM role giving it `ssmmessages` privileges

## Critical parts of this demo

- the ECS service has the `--enable-execute-command` set, which allows the docker command execution.
- the IAM role set as the task definition's `task_role`, which allows `ssmmessages`

## REQUIRED AND NON-DEFAULTED INPUTS

- **NOTE** an array string of one or more subnet IDs must be added to the `scripts/defaults.sh`
- An example is:
```
export subnets="['subnet-0fc1775879',subnet-052ed748]"
```

## Exec into a container using AWS cli, for example:

```
aws ecs execute-command --cluster <CLUSTER_NAME> \
--task <ECS_TASK_ID> \
--container <TASK_CONTAINER_NAME> \
--interactive --command "/bin/sh"
```
