#!/usr/bin/env bash

# Exit script on error
set -e

# Validate stage argument
if [ -z "$1" ]; then
  echo "Usage: $0 <stage>"
  exit 1
fi

stage="$1"
export environ="${stage}"

# Set common environment-specific variables
export AWS_REGION="us-east-1"
export API_BASE_NAME="MyOrdersAPI"
export API_MAPPING_PATH="orders"
export API_DOMAIN="myappdomain"
export DOMAIN_NAME="api.myappdomain.com"

# Execute the main script with the stage
bin/aws_create_api_mappings.sh "$stage"
