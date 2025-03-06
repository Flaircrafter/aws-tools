#!/usr/bin/env bash

# Default to dev if no argument is provided
ENV=${1:-dev} # Use parameter expansion for default value
###### FLAG: SSH identity file
## ssh-db-tunnel p '/Users/abdylan/.ssh/bastion_host_rds'
IDENTITY_FILE=${2:-""} # Use parameter expansion for default value
#############################
REGION="" # <----------- INPUT HERE
# SSH tunnel configuration
DB_PORT=5432
LOCAL_PORT=5433


# Determine the environment and set variables accordingly
if [[ "$ENV" == "production" || "$ENV" == "p" || "$ENV" == "prod" ]]; then
  ENVIRONMENT="production"
  INSTANCE_ID="" # <----------- INPUT HERE
  AWS_VAULT_PROFILE="" # <----------- INPUT HERE
  DB_ENDPOINT="" # <----------- INPUT HERE
else
  ENVIRONMENT="dev"
  INSTANCE_ID="" # <----------- INPUT HERE
  AWS_VAULT_PROFILE="" # <----------- INPUT HERE
  DB_ENDPOINT="" # <----------- INPUT HERE
fi

echo "########  ========> SSH DB TUNNEL <=======  ########"
echo "========> Starting SSH tunnel to $ENVIRONMENT database..."

# Start the instance
echo "========> Starting instance $INSTANCE_ID..."
echo "aws ec2 start-instances --instance-ids $INSTANCE_ID"
aws-vault exec $AWS_VAULT_PROFILE -- aws ec2 start-instances --instance-ids $INSTANCE_ID --region $REGION > /dev/null
echo "========> Waiting for instance to start...  "

while true; do
  INSTANCE_STATE=$(aws-vault exec $AWS_VAULT_PROFILE -- aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[*].Instances[*].State.Name' --output text)
  if [[ "$INSTANCE_STATE" == "running" ]]; then
    echo "Instance is now running."
    break
  else
    echo ".... (still waiting) ...."
    sleep 3
  fi
done

# Get the instance IP
echo "========> Getting instance IP..."
BASTIONHOST_IP=$(aws-vault exec $AWS_VAULT_PROFILE -- aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

# Check if BASTIONHOST_IP is empty or less than 7 characters
if [ -z "$BASTIONHOST_IP" ] || [ ${#BASTIONHOST_IP} -lt 7 ]; then
  echo "Error: Could not get the instance IP. Exiting..."
  exit 1
fi

echo "========> Instance IP: $BASTIONHOST_IP"
echo "========> Creating tunnel to $DB_ENDPOINT on $BASTIONHOST_IP..."

# Your existing script

###################################
SSH_COMMAND="ssh -L $LOCAL_PORT:$DB_ENDPOINT:$DB_PORT"
if [ -n "$IDENTITY_FILE" ]; then
  echo ">> Adding SSH Identity flag: $IDENTITY_FILE"
  SSH_COMMAND="$SSH_COMMAND -i $IDENTITY_FILE"
fi
SSH_COMMAND="$SSH_COMMAND ubuntu@$BASTIONHOST_IP"

# Execute the SSH command
$SSH_COMMAND || echo "This happens sometimes, no worries. Re-Trying in 6sec..." && sleep 6 && $SSH_COMMAND
# $SSH_COMMAND -v
