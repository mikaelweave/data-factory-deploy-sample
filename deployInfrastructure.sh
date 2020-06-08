#!/bin/bash

# az login
# az account set --subscription <subscription_name>

az group create --location $LOCATION \
  --name "${RESOURCE_GROUP_NAME}-${ENVIRONMENT}"

az resource create --resource-group "${RESOURCE_GROUP_NAME}-${ENVIRONMENT}" \
  --location $LOCATION
  --namespace "Microsoft.DataFactory" \
  --name "${RESOURCE_NAME}-${ENVIRONMENT}-adf" \
  --resource-type "factories" \
  --properties '${json}'

  az monitor log-analytics workspace create \
    --resource-group "${RESOURCE_GROUP_NAME}-${ENVIRONMENT}" \
    --name "${RESOURCE_NAME}-${ENVIRONMENT}-la" --location $LOCATION