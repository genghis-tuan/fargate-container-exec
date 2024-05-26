export account_id=$(aws sts get-caller-identity --query Account --output text)

# PREREQUISITE CHECKS
#### SESSION MANAGER PLUGIN CHECK
expected_output="The Session Manager plugin was installed successfully. Use the AWS CLI to start a session."

# DEFAULT VARIABLES
export policy_name="fargate_docker_exec"
export policy_arn="arn:aws:iam::${account_id}:policy/$policy_name"
export role_name="fargate_docker_exec"
export service_name="fargate_docker_exec"
export cluster_name="fargate_docker_exec"
export taskdefinition_name="fargate_docker_exec"
export family="fargate_docker_exec"
export container_name="testing-exec"
export task_role_name="fargate_docker_exec"
export image="python:3.11-slim"

# NOTE: these are dummy subnet IDs. They MUST be replaced.
# export subnets="['subnet-0fc1775879',subnet-052ed748]" #EXAMPLE

export security_groups="[]"

# COLORS
export RED='\033[0;31m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color