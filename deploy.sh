#!/usr/bin/env bash

#------------------------------------------------------------------------------
# Exit on errors and unset variables
#------------------------------------------------------------------------------
set -euo pipefail

#------------------------------------------------------------------------------
# Colors
#------------------------------------------------------------------------------
COLOR_DEFAULT="\033[0;39m"
COLOR_LIGHT_RED='\033[1;31m'
COLOR_LIGHT_BLUE='\033[1;34m'
COLOR_LIGHT_PURPLE='\033[1;35m'

#------------------------------------------------------------------------------
# Logging Functions
#------------------------------------------------------------------------------
DEBUG_ENABLED=0

function enable_debug() {
  DEBUG_ENABLED=1
}

function fatal() {
  2>&1 echo -e "${COLOR_LIGHT_RED}fatal:${COLOR_DEFAULT} " "${@}"
  exit 1
}

function error() {
  2>&1 echo -e "${COLOR_LIGHT_RED}error:${COLOR_DEFAULT} " "${@}"
}

function info() {
  echo -e "${COLOR_LIGHT_BLUE}info:${COLOR_DEFAULT} " "${@}"
}

function debug() {
  if [[ ${DEBUG_ENABLED} -ne 0 ]]; then
    echo -e "${COLOR_LIGHT_PURPLE}debug:${COLOR_DEFAULT} " "${@}"
  fi
}

#------------------------------------------------------------------------------
# Validates the necessary variables are set
#------------------------------------------------------------------------------
function validate() {
  if [[ -z "${CLUSTER+z}" ]]; then
    fatal "cluster is required"
  fi

  if [[ -z "${SERVICE+z}" ]]; then
    fatal "service is required"
  fi

  if [[ -z "${IMAGE+z}" ]]; then
    fatal "image is required"
  fi
}

#------------------------------------------------------------------------------
# Prints help menu
#------------------------------------------------------------------------------
function print_help() {
  info "Usage: "
  info "  ${0} -c <cluster> -s <service> -i <image>"
  info "  CLUSTER=<cluster> SERVICE=<service> IMAGE=<image> ${0}"
}

#------------------------------------------------------------------------------
# Parse arguments
#------------------------------------------------------------------------------
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -i|--image)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        IMAGE=$2
        shift 2
      else
        fatal "argument for $1 is missing"
      fi
      ;;
    -c|--cluster)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        CLUSTER=$2
        shift 2
      else
        fatal "argument for $1 is missing"
      fi
      ;;
    -s|--service)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        SERVICE=$2
        shift 2
      else
        fatal "argument for $1 is missing"
      fi
      ;;
    -*|--*=) # unsupported flags
      fatal "unsupported flag $1"
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

validate
source /usr/local/bin/helper.sh
aws_authentication

LATEST_DEFINITION=$(aws ecs describe-services --services "${SERVICE}" --cluster "${CLUSTER}" | jq -r .services[0].taskDefinition | sed 's/.*\///g')

info "found task definition ${LATEST_DEFINITION}"

DEFINITION=$(aws ecs describe-task-definition \
  --task-definition "${LATEST_DEFINITION}" --output json \
  | jq -r ".taskDefinition")

NEW_DEFINITION=$(echo "${DEFINITION}" \
  | jq -r ".containerDefinitions[0].image = \"${IMAGE}\"" \
  | jq -r "del(.taskDefinitionArn)|del(.revision)|del(.status)|del(.compatibilities)|del(.requiresAttributes)|del(.registeredAt)|del(.registeredBy)")

NEW_DEFINITION=$(aws ecs register-task-definition \
  --cli-input-json "${NEW_DEFINITION}" \
  --output json)

if [[ "${PRUNE_REPOSITORY_CREDENTIALS+x}" == "true" ]]; then
  info "pruning repository credentials"
  NEW_DEFINITION=$(echo "${NEW_DEFINITION}" | jq -r "del(.containerDefinitions[0].repositoryCredentials)")
fi

NEW_DEFINITION=$(echo "${NEW_DEFINITION}" | jq -r "del(.containerDefinitions.repositoryCredentials)")

NEW_DEFINITION_NAME=$(echo "${NEW_DEFINITION}" | jq -r '.taskDefinition.taskDefinitionArn' | sed 's/.*\///g')


info "created task definition ${NEW_DEFINITION_NAME}"

SERVICE_UPDATE=$(aws ecs update-service --cluster "${CLUSTER}" --service "${SERVICE}" --task-definition "${NEW_DEFINITION_NAME}")
SERVICE_ARN=$(echo "${SERVICE_UPDATE}" | jq -r ".service.serviceArn")

info "updated service ${SERVICE_ARN}"

info "waiting for service to stabilize... "
set +e
ECS_WAIT_ATTEMPTS=1
if [[ -n "${ECS_WAIT_RETRIES+x}" ]]; then
  ((ECS_WAIT_ATTEMPTS=ECS_WAIT_ATTEMPTS+ECS_WAIT_RETRIES))
fi
for ((i=0; i<ECS_WAIT_ATTEMPTS; i++)); do
  aws ecs wait services-stable --cluster "${CLUSTER}" --services "${SERVICE}"
  EXIT_CODE=$?
  # only continue to loop through wait attempts if failure was due to timeout and we have remaining attempts left
  if [[ ${EXIT_CODE} == 255 && ${i} < $((ECS_WAIT_ATTEMPTS-1)) ]]; then
    error "failed due to timeout, retrying..."
    continue
  elif [[ ${EXIT_CODE} != 0 ]]; then
    error "failed"
    break
  else
    info "success"
    break
  fi
done

info "deregistering task definition ${LATEST_DEFINITION}..."
aws ecs deregister-task-definition --task-definition "${LATEST_DEFINITION}" --output json > /dev/null 2>&1
info "done"

exit ${EXIT_CODE}
