#!/bin/bash

# Set the default AWS region for all AWS CLI commands.
export AWS_DEFAULT_REGION=us-east-2

# Get the private IP address of the running Windows instance named 'windows-instance'.
windows_ip=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=windows-instance" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].PrivateIpAddress" \
  --output text | head -n1)

# Exit if no Windows instance is found.
if [[ -z "$windows_ip" ]]; then
  echo "No running EC2 instance found with name 'windows-instance'. Exiting."
  exit 1
fi

# Get the instance ID for the Windows instance using its private IP.
windows_id=$(aws ec2 describe-instances \
  --filters "Name=private-ip-address,Values=$windows_ip" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

echo "NOTE: Private IP address for Windows server is '$windows_ip'"
echo "NOTE: CLI to connect to windows - 'aws ssm start-session --target $windows_id --region $AWS_DEFAULT_REGION'"

# Get the private IP address of the running Ubuntu instance named 'ubuntu-instance'.
ubuntu_ip=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ubuntu-instance" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].PrivateIpAddress" \
  --output text | head -n1)

# Exit if no Ubuntu instance is found.
if [[ -z "$ubuntu_ip" ]]; then
  echo "No running EC2 instance found with name 'ubuntu-instance'. Exiting."
  exit 1
fi

# Get the instance ID for the Ubuntu instance using its private IP.
ubuntu_id=$(aws ec2 describe-instances \
  --filters "Name=private-ip-address,Values=$ubuntu_ip" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

echo "NOTE: Private IP address for Ubuntu server is '$ubuntu_ip'"
echo "NOTE: CLI to connect to ubuntu - 'aws ssm start-session --target $ubuntu_id --region $AWS_DEFAULT_REGION'"

# Send an SSM command to the Windows instance to test connectivity to the Ubuntu instance using curl.
echo "NOTE: Sending SSM command to Windows instance to validate connectivity to Ubuntu..."
win_command_id=$(aws ssm send-command \
  --document-name "AWS-RunPowerShellScript" \
  --document-version "1" \
  --targets '[{"Key":"tag:Name","Values":["windows-instance"]}]' \
  --parameters "{\"workingDirectory\":[\"\"],\"executionTimeout\":[\"3600\"],\"commands\":[\"curl.exe $ubuntu_ip\"]}" \
  --timeout-seconds 600 \
  --max-concurrency "50" \
  --max-errors "0" \
  --query "Command.CommandId" \
  --output text)

# Send an SSM command to the Ubuntu instance to test connectivity to the Windows instance using curl.
echo "NOTE: Sending SSM command to Ubuntu instance to validate connectivity to Windows..."
ubuntu_command_id=$(aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --document-version "1" \
  --targets '[{"Key":"tag:Name","Values":["ubuntu-instance"]}]' \
  --parameters "{\"workingDirectory\":[\"\"],\"executionTimeout\":[\"3600\"],\"commands\":[\"curl $windows_ip\"]}" \
  --timeout-seconds 600 \
  --max-concurrency "50" \
  --max-errors "0" \
  --query "Command.CommandId" \
  --output text)

# Allow time for commands to start.
echo "NOTE: Waiting for SSM commands to finish..."
sleep 5

# Poll for completion of both SSM commands.
while true; do
  count=$(aws ssm list-commands \
    --query "length(Commands[?Status=='InProgress' || Status=='Pending'])" \
    --output text | head -n 1)

  if [[ "$count" == "0" ]]; then
    echo "NOTE: All SSM commands have completed."
    break
  fi

  echo "WARNING: Still waiting... $count command(s) in progress."
  sleep 20
done

# Retrieve and print the output from the Windows instance's curl command.
response=$(aws ssm get-command-invocation \
  --command-id "$win_command_id" \
  --instance-id "$windows_id" \
  --query "StandardOutputContent" \
  --output text)

echo "NOTE: Response from Windows: $response"

# Retrieve and print the output from the Ubuntu instance's curl command.
response=$(aws ssm get-command-invocation \
  --command-id "$ubuntu_command_id" \
  --instance-id "$ubuntu_id" \
  --query "StandardOutputContent" \
  --output text)

echo "NOTE: Response from Ubuntu: $response"
