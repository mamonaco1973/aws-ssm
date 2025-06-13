#!/bin/bash

# Set the default AWS region to us-east-2 for all AWS CLI commands.
export AWS_DEFAULT_REGION=us-east-2

# Run the environment check script. Exit immediately if the check fails.
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# Navigate to the Terraform configuration directory for SSM.
cd 01-ssm 

# Initialize Terraform to download required providers and set up the backend.
terraform init

# Apply the Terraform plan automatically without prompting for approval.
terraform apply -auto-approve

# Return to the root directory to continue the script.
cd ..

# Inform the user we're waiting for EC2 instances to fully initialize.
echo "NOTE: Waiting for instances to be ready..."

# Pause for 60 seconds to allow instances time to start up and become SSM-accessible.
sleep 60

# Send SSM command to install Apache on the Ubuntu instance.
aws ssm send-command \
  --document-name "InstallApacheOnUbuntu" \
  --document-version "1" \
  --targets '[{"Key":"tag:Name","Values":["ubuntu-instance"]}]' \
  --parameters '{}' \
  --timeout-seconds 600 \
  --max-concurrency "50" \
  --max-errors "0" \
  --region us-east-2 > /dev/null

# Send SSM command to install IIS and Hello World site on the Windows instance.
aws ssm send-command \
  --document-name "InstallIISHelloWorld" \
  --document-version "1" \
  --targets '[{"Key":"tag:Name","Values":["windows-instance"]}]' \
  --parameters '{}' \
  --timeout-seconds 600 \
  --max-concurrency "50" \
  --max-errors "0" \
  --region us-east-2 > /dev/null

# Notify user that we are monitoring the SSM command executions.
echo "NOTE: Waiting for SSM commands to finish..."
sleep 20  # Initial delay before checking status

# Continuously check for any SSM commands still in progress or pending.
while true; do

  # Count the number of commands still in progress or pending.
  count=$(aws ssm list-commands \
    --query "length(Commands[?Status=='InProgress' || Status=='Pending'])" \
    --output text | tr -d '\r\n' | xargs)

  # Exit loop if no commands are still running.
  if [[ "$count" == "0" ]]; then
    echo "NOTE: All SSM commands have completed."
    break
  fi

  # Display how many commands are still running and wait before checking again.
  echo "WARNING: Still waiting... $count command(s) in progress."
  sleep 20
done

# Run the validation script to confirm successful deployment and configuration.
./validate.sh
