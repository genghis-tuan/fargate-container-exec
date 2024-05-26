#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/defaults.sh

while [ $# -gt 0 ]; do
  case "$1" in
    --cluster_name*|-c*)
      if [[ "$1" != *=* ]]; then shift; fi
      cluster_name="${1#*=}"
      ;;
    --help|-h)
      printf "\
USE:\n\
--cluster_name or -c to specify the cluster name\n"
      exit 0
      ;;
    *)
      >&2 printf "Error: Invalid argument\n"
      exit 1
      ;;
  esac
  shift
done

aws ecs create-cluster \
--cluster-name $cluster_name