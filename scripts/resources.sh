#!/bin/bash
if [[ $# -ne 2 ]]
    then
        echo "Please provide a resourcegroup and a location" 
        echo "Enter resource group name"
        read resourceGroup
        echo "Enter location (for example, westus)"
        read location
else 
    resourceGroup=$1
    location=$2
fi
subscriptionId=$(az account show | jq -r '.id')

echo "Creating resource group..." 
az group create --name $resourceGroup --location $location

echo "Deploying ETL resources..."
echo "Deploying Managed Identity"

az deployment group create \
    --name "ManagedIdentityDeployment" \
    --resource-group $resourceGroup \
    --template-file ./templates/resourcestemplate_uami.json > resourcesoutputs_uami.json

managedIdentityName=$(cat resourcesoutputs_uami.json | jq -r '.properties.outputs.managedIdentityName.value')

echo "Managed Identity" $managedIdentityName deployed
echo ""

echo "Deploying Blob Storage Account"
echo "Deploying ADLS Gen2 Account"
echo "Assigning role to Managed Identity"

az deployment group create \
    --name "StorageDeployment" \
    --resource-group $resourceGroup \
    --template-file ./templates/resourcestemplate_storage.json > resourcesoutputs_storage.json \
    --parameters managedIdentityName=$managedIdentityName

blobStorageName=$(cat resourcesoutputs_storage.json | jq -r '.properties.outputs.blobStorageName.value')
ADLSGen2StorageName=$(cat resourcesoutputs_storage.json | jq -r '.properties.outputs.adlsGen2StorageName.value')

echo "Blob Storage Account" $blobStorageName deployed
echo "ADLS Gen2 Account" $ADLSGen2StorageName deployed
echo ""

echo "Deploying VNET"
echo "Deploying Network Security Group"
echo "Deploying Spark Cluster"
echo "Deploying LLAP cluster"
echo "Note: Cluster creation can take around 25 minutes"
echo "Start time:" `date`

az deployment group create \
    --name "ClusterDeployment" \
    --resource-group $resourceGroup \
    --template-file ./templates/resourcestemplate_remainder.json > resourcesoutputs_remainder.json \
    --parameters managedIdentityName=$managedIdentityName blobStorageName=$blobStorageName ADLSGen2StorageName=$ADLSGen2StorageName

sparkClusterName=$(cat resourcesoutputs_remainder.json | jq -r '.properties.outputs.sparkClusterName.value')
llapClusterName=$(cat resourcesoutputs_remainder.json | jq -r '.properties.outputs.llapClusterName.value')

echo "Spark Cluster" $sparkClusterName deployed
echo "LLAP cluster" $llapClusterName deployed
echo ""

echo "Uploading data to blob storage..."
az storage blob upload-batch -d rawdata \
    --account-name $blobStorageName -s ./ --pattern *.csv

echo "Done"




