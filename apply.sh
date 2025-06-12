#!/bin/bash

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

terraform init
terraform apply -auto-approve