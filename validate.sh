#!/bin/bash

export AWS_DEFAULT_REGION=us-east-2

windows_ip=$(aws ec2 describe-instances   \
             --filters "Name=tag:Name,Values=windows-instance" "Name=instance-state-name,Values=running"  \
             --query "Reservations[*].Instances[*].PrivateIpAddress" --output text | head -n1)

if [[ -z "$windows_ip" ]]; then
  echo "No running EC2 instance found with name 'windows-instance'. Exiting."
  exit 1
fi

windows_id=$(aws ec2 describe-instances \
  --filters "Name=private-ip-address,Values=$windows_ip" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

echo "NOTE: Private ip address for windows server is '$windows_ip'"

ubuntu_ip=$(aws ec2 describe-instances   \
             --filters "Name=tag:Name,Values=ubuntu-instance" "Name=instance-state-name,Values=running"  \
             --query "Reservations[*].Instances[*].PrivateIpAddress" --output text | head -n1)

if [[ -z "$ubuntu_ip" ]]; then
  echo "No running EC2 instance found with name 'ubuntu-instance'. Exiting."
  exit 1
fi

ubuntu_id=$(aws ec2 describe-instances \
  --filters "Name=private-ip-address,Values=$ubuntu_ip" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

echo "NOTE: Private ip address for ubuntu server is '$ubuntu_ip'"

echo "NOTE: Sending SSM command to windows instance to validate connectivity to ubuntu instance..."

win_command_id=$(aws ssm send-command \
  --document-name "AWS-RunPowerShellScript" \
  --document-version "1" \
  --targets '[{"Key":"tag:Name","Values":["windows-instance"]}]' \
  --parameters "{\"workingDirectory\":[\"\"],\"executionTimeout\":[\"3600\"],\"commands\":[\"curl.exe $ubuntu_ip\"]}" \
  --timeout-seconds 600 \
  --max-concurrency "50" \
  --max-errors "0" \
  --region us-east-2 \
  --query "Command.CommandId" \
  --output text)

echo "NOTE: Waiting for SSM commands to finish..."
sleep 5

while true; do
  count=$(aws ssm list-commands \
    --query "Commands[?Status=='InProgress' || Status=='Pending'] | length(@)" \
    --output text | tr -d '\r' | tr -d '\n' | xargs)

  if [[ "$count" == "0" ]]; then
    echo "NOTE: All SSM commands have completed."
    break
  fi

  echo "WARNING: Still waiting... command(s) in progress."
  sleep 20
done

response=$(aws ssm get-command-invocation \
  --command-id "$win_command_id" \
  --instance-id "$windows_id" \
  --query "StandardOutputContent" \
  --output text)

echo "NOTE: Response from windows - $response"







