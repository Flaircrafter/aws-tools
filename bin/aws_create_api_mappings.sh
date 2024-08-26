#!/usr/bin/env bash

# Exit script on error
set -e

# Validate stage argument
if [ -z "$1" ]; then
  echo "Usage: $0 <stage>"
  exit 1
fi
stage="$1"
environ="${stage}"


#Print env variables
echo "$%#$%#$%#$%#$%#$%#$%#$%#$%#$%##$%# AWS Creating API Mappings STARTED $%#$%#$%#$%#$%#$%#$%#$%#$%#$%#$%#$%#"
echo "=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&="
echo "stage: $stage"
echo "environ: $environ"
echo "AWS_REGION: $AWS_REGION"
echo "API_BASE_NAME: $API_BASE_NAME"
echo "API_MAPPING_PATH: $API_MAPPING_PATH"
echo "API_DOMAIN: $API_DOMAIN"
echo "DOMAIN_NAME: $DOMAIN_NAME"
echo "=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&=&"


# Check if required commands are available
if ! command -v aws &> /dev/null || ! command -v jq &> /dev/null; then
  sudo apt-get update || true
  sudo apt-get install -y awscli jq || true
  echo "aws and jq commands are required but not installed. Exiting."
  exit 1
fi


echo "Starting API Mappings creation for stage: $stage"

# Fetch API ID with error checking
API_ID=$(aws apigateway get-rest-apis | jq -r --arg apiName "${API_BASE_NAME}-${stage}" '.items[] | select(.name == $apiName) | .id')
if [ -z "$API_ID" ]; then
    echo "API ID for ${API_BASE_NAME}-${stage} not found. Exiting."
    exit 1
fi

echo "API ID: $API_ID"


echo "Check for existing API Mapping for ${API_DOMAIN} at $DOMAIN_NAME"
OUTPUT=$(aws apigatewayv2 get-api-mappings --domain-name "${DOMAIN_NAME}" 2>&1) || true

echo "Check if it is pointing to the correct API ID"
MAPPING_EXISTS=$(echo "$OUTPUT" | jq -r --arg apiId "${API_ID}" --arg apiMappingPath "${API_MAPPING_PATH}" '.Items[] | select(.ApiId == $apiId and .ApiMappingKey == $apiMappingPath) | .ApiMappingKey')

if [ -z "$MAPPING_EXISTS" ]; then
  echo "No existing mapping found pointing to API ID ${API_ID} with mapping path ${API_MAPPING_PATH}"
else
  echo "Existing mapping found pointing to API ID ${API_ID} with mapping path ${API_MAPPING_PATH}"
fi

echo "If not pointing to the correct API ID, delete the existing API Mapping"
echo "$OUTPUT" | jq -r --arg apiId "${API_ID}" --arg apiMappingPath "${API_MAPPING_PATH}" '.Items[] | select(.ApiId == $apiId and .ApiMappingKey == $apiMappingPath) | .ApiMappingId' | while read -r apiMappingId; do
  if [ -n "$apiMappingId" ]; then
    echo "Deleting API Mapping with ID: $apiMappingId"
    aws apigatewayv2 delete-api-mapping --domain-name "${DOMAIN_NAME}" --api-mapping-id "${apiMappingId}"
  fi
done

echo "Creating API Mapping for ${API_DOMAIN} at $DOMAIN_NAME"
OUTPUT=$(aws apigatewayv2 create-api-mapping --domain-name "${DOMAIN_NAME}" --api-id "${API_ID}" --stage "${stage}" --api-mapping-key "${API_MAPPING_PATH}" 2>&1) || true
sleep 3

echo "API Mapping creation response: $OUTPUT"

aws apigatewayv2 get-api-mappings --domain-name "${DOMAIN_NAME}" | jq -r '.Items[] | "API Mapping Key: \(.ApiMappingKey), API ID: \(.ApiId)"'


echo "API Mappings creation completed."
echo "$%#$%#$%#$%#$%#$%#$%#$%#$%#$%#$%#$%#$%# AWS Creating API Mappings FINISHED $%#$%#$%#$%#$%#$%#$%#$%#$%#$%#$%#$%#$%#"
