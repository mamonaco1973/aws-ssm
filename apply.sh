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

/* Run SSM documents on the instances */
sleep 60 # Wait for instances to be ready

aws ssm send-command \
  --document-name "InstallApacheOnUbuntu" \
  --document-version "1" \
  --targets '[{"Key":"tag:Name","Values":["ubuntu-instance"]}]' \
  --parameters '{}' \
  --timeout-seconds 600 \
  --max-concurrency "50" \
  --max-errors "0" \
  --region us-east-2 > /dev/null

aws ssm send-command \
  --document-name "InstallIISHelloWorld" \
  --document-version "1" \
  --targets '[{"Key":"tag:Name","Values":["windows-instance"]}]' \
  --parameters '{}' \
  --timeout-seconds 600 \
  --max-concurrency "50" \
  --max-errors "0" \
  --region us-east-2 > /dev/null


