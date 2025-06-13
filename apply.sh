#!/bin/bash

export AWS_DEFAULT_REGION=us-east-2

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

cd 01-ssm 
terraform init
terraform apply -auto-approve
cd ..
