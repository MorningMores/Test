#!/bin/bash

# Azure Health Check Script
# Checks the health of all deployed services

set -e

RESOURCE_GROUP="rg-concert-platform"
FRONTEND_APP="concert-platform-frontend"
BACKEND_APP="concert-platform-backend"
MYSQL_SERVER="concert-platform-mysql-server"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🏥 Azure Health Check - Concert Platform"
echo "========================================"
echo ""

# Check if logged in
echo -e "${BLUE}Checking Azure login...${NC}"
if az account show &> /dev/null; then
    echo -e "${GREEN}✅ Logged in to Azure${NC}"
else
    echo -e "${RED}❌ Not logged in. Run 'az login' first.${NC}"
    exit 1
fi

echo ""

# Check Resource Group
echo -e "${BLUE}Checking Resource Group...${NC}"
if az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo -e "${GREEN}✅ Resource Group exists${NC}"
else
    echo -e "${RED}❌ Resource Group not found${NC}"
    exit 1
fi

echo ""

# Check Frontend App Service
echo -e "${BLUE}Checking Frontend App Service...${NC}"
FRONTEND_STATE=$(az webapp show --name $FRONTEND_APP --resource-group $RESOURCE_GROUP --query state -o tsv 2>/dev/null)
if [ "$FRONTEND_STATE" == "Running" ]; then
    echo -e "${GREEN}✅ Frontend is running${NC}"
    
    # Test frontend URL
    FRONTEND_URL="https://${FRONTEND_APP}.azurewebsites.net"
    if curl -f -s -o /dev/null -w "%{http_code}" $FRONTEND_URL | grep -q "200\|302"; then
        echo -e "${GREEN}✅ Frontend is accessible${NC}"
        echo -e "   URL: $FRONTEND_URL"
    else
        echo -e "${YELLOW}⚠️  Frontend is running but not responding${NC}"
    fi
else
    echo -e "${RED}❌ Frontend is $FRONTEND_STATE${NC}"
fi

echo ""

# Check Backend App Service
echo -e "${BLUE}Checking Backend App Service...${NC}"
BACKEND_STATE=$(az webapp show --name $BACKEND_APP --resource-group $RESOURCE_GROUP --query state -o tsv 2>/dev/null)
if [ "$BACKEND_STATE" == "Running" ]; then
    echo -e "${GREEN}✅ Backend is running${NC}"
    
    # Test backend health endpoint
    BACKEND_URL="https://${BACKEND_APP}.azurewebsites.net"
    HEALTH_RESPONSE=$(curl -f -s -w "%{http_code}" $BACKEND_URL/actuator/health -o /tmp/health.json 2>/dev/null || echo "000")
    
    if [ "$HEALTH_RESPONSE" == "200" ]; then
        echo -e "${GREEN}✅ Backend health check passed${NC}"
        echo -e "   URL: $BACKEND_URL"
        HEALTH_STATUS=$(cat /tmp/health.json | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        echo -e "   Status: $HEALTH_STATUS"
    else
        echo -e "${YELLOW}⚠️  Backend is running but health check failed (HTTP $HEALTH_RESPONSE)${NC}"
    fi
else
    echo -e "${RED}❌ Backend is $BACKEND_STATE${NC}"
fi

echo ""

# Check MySQL Server
echo -e "${BLUE}Checking MySQL Server...${NC}"
MYSQL_STATE=$(az mysql flexible-server show --resource-group $RESOURCE_GROUP --name $MYSQL_SERVER --query state -o tsv 2>/dev/null)
if [ "$MYSQL_STATE" == "Ready" ]; then
    echo -e "${GREEN}✅ MySQL server is ready${NC}"
    
    MYSQL_HOST="${MYSQL_SERVER}.mysql.database.azure.com"
    echo -e "   Host: $MYSQL_HOST"
    
    # Check if we can resolve the hostname
    if host $MYSQL_HOST > /dev/null 2>&1; then
        echo -e "${GREEN}✅ MySQL hostname resolves${NC}"
    else
        echo -e "${YELLOW}⚠️  Cannot resolve MySQL hostname${NC}"
    fi
else
    echo -e "${RED}❌ MySQL server is $MYSQL_STATE${NC}"
fi

echo ""

# Check Container Registry
echo -e "${BLUE}Checking Container Registry...${NC}"
ACR_NAME=$(az acr list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv 2>/dev/null)
if [ -n "$ACR_NAME" ]; then
    echo -e "${GREEN}✅ Container Registry found: $ACR_NAME${NC}"
    
    # List images
    BACKEND_TAGS=$(az acr repository show-tags --name $ACR_NAME --repository backend --output tsv 2>/dev/null | wc -l)
    FRONTEND_TAGS=$(az acr repository show-tags --name $ACR_NAME --repository frontend --output tsv 2>/dev/null | wc -l)
    
    echo -e "   Backend images: $BACKEND_TAGS"
    echo -e "   Frontend images: $FRONTEND_TAGS"
else
    echo -e "${YELLOW}⚠️  Container Registry not found${NC}"
fi

echo ""

# Summary
echo "========================================"
echo -e "${BLUE}Summary${NC}"
echo "========================================"
echo ""

if [ "$FRONTEND_STATE" == "Running" ] && [ "$BACKEND_STATE" == "Running" ] && [ "$MYSQL_STATE" == "Ready" ]; then
    echo -e "${GREEN}🎉 All services are healthy!${NC}"
    echo ""
    echo "Access your application at:"
    echo "  Frontend: https://${FRONTEND_APP}.azurewebsites.net"
    echo "  Backend:  https://${BACKEND_APP}.azurewebsites.net"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠️  Some services are not healthy${NC}"
    echo ""
    echo "Troubleshooting commands:"
    echo "  View frontend logs: az webapp log tail --name $FRONTEND_APP --resource-group $RESOURCE_GROUP"
    echo "  View backend logs:  az webapp log tail --name $BACKEND_APP --resource-group $RESOURCE_GROUP"
    echo "  Restart frontend:   az webapp restart --name $FRONTEND_APP --resource-group $RESOURCE_GROUP"
    echo "  Restart backend:    az webapp restart --name $BACKEND_APP --resource-group $RESOURCE_GROUP"
    echo ""
    exit 1
fi
