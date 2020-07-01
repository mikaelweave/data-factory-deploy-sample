#!/bin/bash

# Required dependencies:
# Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
# Azcopy: https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10

# Expected environment variables:
# - SUBSCRIPTION_ID
# - LOCATION
# - RESOURCE_GROUP_NAME
# - RESOURCE_NAME

# First ensure you have a proper .env file (in the same format as .env.sample) with the deployment values filled out
# Load settings from .env file
export $(grep -v '^#' .env | xargs)

# Ensure we have the correct subscription selected
# az login
az account set --subscription $SUBSCRIPTION_ID

# Create the resource group if needed
az group create -l $LOCATION -n $RESOURCE_GROUP_NAME
az configure --defaults group=$RESOURCE_GROUP_NAME location=$LOCATION

# Create Storage Accounts
az storage account create --name "${RESOURCE_NAME}dev" --sku Standard_LRS
az storage account create --name "${RESOURCE_NAME}test" --sku Standard_LRS
az storage account create --name "${RESOURCE_NAME}prod" --sku Standard_LRS

# Create Storage Container
az storage container create --account-name "${RESOURCE_NAME}dev" --name src
az storage container create --account-name "${RESOURCE_NAME}dev" --name dest
az storage container create --account-name "${RESOURCE_NAME}test" --name src
az storage container create --account-name "${RESOURCE_NAME}test" --name dest
az storage container create --account-name "${RESOURCE_NAME}prod" --name src
az storage container create --account-name "${RESOURCE_NAME}prod" --name dest

# Populate Source Storage Containers
#blobs=$(az storage blob list --account-name azureopendatastorage --container-name gfsweatherdatacontainer --sas-token r'')
mkdir temp
cd temp 
for n in {1..1000}; do
    dd if=/dev/urandom of=file$( printf %03d "$n" ).bin bs=1 count=$(( RANDOM + 1024 ))
done

cd ..
end=`date -u -v +1d '+%Y-%m-%dT%H:%M:%SZ'`
devSas=`az storage container generate-sas --account-name "${RESOURCE_NAME}dev" --name src --https-only --permissions dlrw --expiry $end -o tsv`
azcopy cp temp "https://${RESOURCE_NAME}dev.blob.core.windows.net/src?${devSas}" --recursive=true 
testSas=`az storage container generate-sas --account-name "${RESOURCE_NAME}test" --name src --https-only --permissions dlrw --expiry $end -o tsv`
azcopy cp temp "https://${RESOURCE_NAME}test.blob.core.windows.net/src?${testSas}" --recursive=true 
prodSas=`az storage container generate-sas --account-name "${RESOURCE_NAME}prod" --name src --https-only --permissions dlrw --expiry $end -o tsv`
azcopy cp temp "https://${RESOURCE_NAME}prod.blob.core.windows.net/src?${prodSas}" --recursive=true 
rm -rf temp/

# Create and populate Key Vaults
az keyvault create --name "${RESOURCE_NAME}dev"
az keyvault secret set --name "Storage-Account-Name" --vault-name "${RESOURCE_NAME}dev" --value "${RESOURCE_NAME}dev"
az keyvault secret set --name "Storage-Account-Key" --vault-name "${RESOURCE_NAME}dev" \
    --value $(az storage account keys list -n "${RESOURCE_NAME}dev" --out tsv --query '[0].value')

az keyvault create --name "${RESOURCE_NAME}test"
az keyvault secret set --name "Storage-Account-Name" --vault-name "${RESOURCE_NAME}test" --value "${RESOURCE_NAME}test"
az keyvault secret set --name "Storage-Account-Key" --vault-name "${RESOURCE_NAME}test" \
    --value $(az storage account keys list -n "${RESOURCE_NAME}test" --out tsv --query '[0].value')

az keyvault create --name "${RESOURCE_NAME}prod"
az keyvault secret set --name "Storage-Account-Name" --vault-name "${RESOURCE_NAME}prod" --value "${RESOURCE_NAME}prod"
az keyvault secret set --name "Storage-Account-Key" --vault-name "${RESOURCE_NAME}prod" \
    --value $(az storage account keys list -n "${RESOURCE_NAME}prod" --out tsv --query '[0].value')

# Create Data Factories
devDataFactry=$(az resource create \
  --namespace "Microsoft.DataFactory" --name "${RESOURCE_NAME}dev" --resource-type "factories" \
  --properties '{"properties": {}}')
testDataFactry=$(az resource create \
  --namespace "Microsoft.DataFactory" --name "${RESOURCE_NAME}test" --resource-type "factories" \
  --properties '{"properties": {}}')
prodDataFactry=$(az resource create \
  --namespace "Microsoft.DataFactory" --name "${RESOURCE_NAME}prod" --resource-type "factories" \
  --properties '{"properties": {}}')

# Give Data Factories Access To Key Vaults
az keyvault set-policy --name "${RESOURCE_NAME}dev" --object-id $(echo $devDataFactry | jq -r .id) --secret-permissions list get
az keyvault set-policy --name "${RESOURCE_NAME}test" --object-id $(echo $testDataFactry | jq -r .id) --secret-permissions list get
az keyvault set-policy --name "${RESOURCE_NAME}prod" --object-id $(echo $prodDataFactry | jq -r .id) --secret-permissions list get