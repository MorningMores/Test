#!/bin/bash

# Azure Deployment Script for Concert Event Platform
# This script deploys the entire application stack to Azure

set -e

echo "🚀 Starting Azure Deployment for Concert Event Platform"
echo "=================================================="

# Configuration
RESOURCE_GROUP="rg-concert-platform"
LOCATION="southeastasia"
APP_NAME="concert-platform"
MYSQL_SERVER_NAME="${APP_NAME}-mysql-server"
MYSQL_DB_NAME="concert_db"
FRONTEND_APP_NAME="${APP_NAME}-frontend"
BACKEND_APP_NAME="${APP_NAME}-backend"
ACR_NAME="${APP_NAME}acr"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in to Azure
echo -e "${BLUE}🔐 Checking Azure login status...${NC}"
az account show &> /dev/null || {
    echo -e "${RED}❌ Not logged in to Azure. Please run 'az login' first.${NC}"
    exit 1
}

echo -e "${GREEN}✅ Azure CLI authenticated${NC}"

# Create Resource Group
echo -e "${BLUE}📦 Creating Resource Group...${NC}"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --tags Environment=Production Project=Concert-Platform ManagedBy=DevOps

echo -e "${GREEN}✅ Resource Group created${NC}"

# Create Azure Container Registry
echo -e "${BLUE}🐳 Creating Azure Container Registry...${NC}"
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --admin-enabled true

echo -e "${GREEN}✅ Container Registry created${NC}"

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)

echo -e "${GREEN}✅ ACR credentials retrieved${NC}"

# Build and push Docker images
echo -e "${BLUE}🔨 Building and pushing Docker images...${NC}"

# Login to ACR
echo $ACR_PASSWORD | docker login $ACR_LOGIN_SERVER --username $ACR_USERNAME --password-stdin

# Build and push backend
echo -e "${BLUE}Building backend image...${NC}"
docker build -t $ACR_LOGIN_SERVER/${APP_NAME}-backend:latest ./main_backend
docker push $ACR_LOGIN_SERVER/${APP_NAME}-backend:latest

# Build and push frontend
echo -e "${BLUE}Building frontend image...${NC}"
docker build -t $ACR_LOGIN_SERVER/${APP_NAME}-frontend:latest ./main_frontend/concert1
docker push $ACR_LOGIN_SERVER/${APP_NAME}-frontend:latest

echo -e "${GREEN}✅ Docker images built and pushed${NC}"

# Create Azure Database for MySQL
echo -e "${BLUE}🗄️  Creating Azure Database for MySQL...${NC}"
az mysql flexible-server create \
    --resource-group $RESOURCE_GROUP \
    --name $MYSQL_SERVER_NAME \
    --location $LOCATION \
    --admin-user myadmin \
    --admin-password "MySecurePass123!" \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --storage-size 20 \
    --version 8.0 \
    --public-access 0.0.0.0

echo -e "${GREEN}✅ MySQL Server created${NC}"

# Create database
echo -e "${BLUE}📊 Creating database...${NC}"
az mysql flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $MYSQL_SERVER_NAME \
    --database-name $MYSQL_DB_NAME

echo -e "${GREEN}✅ Database created${NC}"

# Configure firewall rules
echo -e "${BLUE}🔥 Configuring firewall rules...${NC}"
az mysql flexible-server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --name $MYSQL_SERVER_NAME \
    --rule-name AllowAzureServices \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0

echo -e "${GREEN}✅ Firewall rules configured${NC}"

# Create App Service Plan
echo -e "${BLUE}📋 Creating App Service Plan...${NC}"
az appservice plan create \
    --name ${APP_NAME}-plan \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --is-linux \
    --sku B2

echo -e "${GREEN}✅ App Service Plan created${NC}"

# Create Backend App Service
echo -e "${BLUE}🔧 Creating Backend App Service...${NC}"
az webapp create \
    --resource-group $RESOURCE_GROUP \
    --plan ${APP_NAME}-plan \
    --name $BACKEND_APP_NAME \
    --deployment-container-image-name $ACR_LOGIN_SERVER/${APP_NAME}-backend:latest

# Configure Backend App Settings
MYSQL_CONNECTION_STRING="jdbc:mysql://${MYSQL_SERVER_NAME}.mysql.database.azure.com:3306/${MYSQL_DB_NAME}?useSSL=true&requireSSL=false"

az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $BACKEND_APP_NAME \
    --settings \
        SPRING_DATASOURCE_URL=$MYSQL_CONNECTION_STRING \
        SPRING_DATASOURCE_USERNAME=myadmin \
        SPRING_DATASOURCE_PASSWORD="MySecurePass123!" \
        DOCKER_REGISTRY_SERVER_URL=https://$ACR_LOGIN_SERVER \
        DOCKER_REGISTRY_SERVER_USERNAME=$ACR_USERNAME \
        DOCKER_REGISTRY_SERVER_PASSWORD=$ACR_PASSWORD \
        WEBSITES_PORT=8080

echo -e "${GREEN}✅ Backend App Service created and configured${NC}"

# Create Frontend App Service
echo -e "${BLUE}🎨 Creating Frontend App Service...${NC}"
az webapp create \
    --resource-group $RESOURCE_GROUP \
    --plan ${APP_NAME}-plan \
    --name $FRONTEND_APP_NAME \
    --deployment-container-image-name $ACR_LOGIN_SERVER/${APP_NAME}-frontend:latest

# Configure Frontend App Settings
BACKEND_URL="https://${BACKEND_APP_NAME}.azurewebsites.net"

az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $FRONTEND_APP_NAME \
    --settings \
        NUXT_PUBLIC_API_BASE_URL=$BACKEND_URL \
        DOCKER_REGISTRY_SERVER_URL=https://$ACR_LOGIN_SERVER \
        DOCKER_REGISTRY_SERVER_USERNAME=$ACR_USERNAME \
        DOCKER_REGISTRY_SERVER_PASSWORD=$ACR_PASSWORD \
        WEBSITES_PORT=3000

echo -e "${GREEN}✅ Frontend App Service created and configured${NC}"

# Enable logging
echo -e "${BLUE}📝 Enabling application logging...${NC}"
az webapp log config \
    --resource-group $RESOURCE_GROUP \
    --name $BACKEND_APP_NAME \
    --docker-container-logging filesystem

az webapp log config \
    --resource-group $RESOURCE_GROUP \
    --name $FRONTEND_APP_NAME \
    --docker-container-logging filesystem

echo -e "${GREEN}✅ Logging enabled${NC}"

# Get URLs
FRONTEND_URL="https://${FRONTEND_APP_NAME}.azurewebsites.net"
BACKEND_URL="https://${BACKEND_APP_NAME}.azurewebsites.net"

echo ""
echo -e "${GREEN}=================================================="
echo "🎉 Deployment Complete!"
echo "==================================================${NC}"
echo ""
echo -e "${BLUE}Frontend URL:${NC} $FRONTEND_URL"
echo -e "${BLUE}Backend URL:${NC} $BACKEND_URL"
echo -e "${BLUE}MySQL Server:${NC} ${MYSQL_SERVER_NAME}.mysql.database.azure.com"
echo ""
echo -e "${BLUE}Resource Group:${NC} $RESOURCE_GROUP"
echo -e "${BLUE}Location:${NC} $LOCATION"
echo ""
echo -e "${GREEN}✅ All services are deployed and running!${NC}"
echo ""
echo "Next steps:"
echo "1. Wait 5-10 minutes for services to fully start"
echo "2. Visit the frontend URL to test the application"
echo "3. Check logs: az webapp log tail --name $FRONTEND_APP_NAME --resource-group $RESOURCE_GROUP"
echo ""
