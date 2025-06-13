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

# Run SSM documents on the instances 
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

echo "⏳ Waiting for SSM commands to finish..."

while true; do
  count=$(aws ssm list-commands \
    --region us-east-2 \
    --query "Commands[?Status=='InProgress' || Status=='Pending'] | length(@)" \
    --output text)

  if [[ "$count" -eq 0 ]]; then
    echo "✅ All SSM commands have completed."
    break
  fi

  echo "Still waiting... $count command(s) in progress."
  sleep 5
done




