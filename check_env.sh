#!/bin/bash

echo "NOTE: Validating that required commands are found in your PATH."
# List of required commands
commands=("aws" "packer" "terraform")

# Flag to track if all commands are found
all_found=true

# Iterate through each command and check if it's available
for cmd in "${commands[@]}"; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not found in the current PATH."
    all_found=false
  else
    echo "NOTE: $cmd is found in the current PATH."
  fi
done

# Final status
if [ "$all_found" = true ]; then
  echo "NOTE: All required commands are available."
else
  echo "ERROR: One or more commands are missing."
  exit 1
fi

echo "NOTE: Checking AWS cli connection."

aws sts get-caller-identity --query "Account" --output text >> /dev/null

# Check the return code of the login command
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to connect to AWS. Please check your credentials and environment variables."
  exit 1
else
  echo "NOTE: Successfully logged into AWS."
fi


