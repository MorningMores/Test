#!/bin/bash

# Azure Database Initialization Script
# This script initializes the Azure MySQL database with required schema

set -e

echo "🗄️  Initializing Azure MySQL Database"
echo "======================================"

# Configuration
RESOURCE_GROUP="rg-concert-platform"
MYSQL_SERVER_NAME="concert-platform-mysql-server"
MYSQL_DB_NAME="concert_db"
MYSQL_ADMIN_USER="myadmin"

# Prompt for admin password
read -sp "Enter MySQL admin password: " MYSQL_ADMIN_PASSWORD
echo ""

# Get MySQL server FQDN
MYSQL_HOST="${MYSQL_SERVER_NAME}.mysql.database.azure.com"

echo "📋 Checking MySQL server status..."
az mysql flexible-server show \
    --resource-group $RESOURCE_GROUP \
    --name $MYSQL_SERVER_NAME \
    --query "state" -o tsv

echo "🔥 Adding temporary firewall rule for your IP..."
MY_IP=$(curl -s https://api.ipify.org)
az mysql flexible-server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --name $MYSQL_SERVER_NAME \
    --rule-name TempLocalAccess \
    --start-ip-address $MY_IP \
    --end-ip-address $MY_IP

echo "⏳ Waiting for firewall rule to take effect..."
sleep 10

echo "📊 Executing database initialization script..."
mysql \
    --host=$MYSQL_HOST \
    --user=$MYSQL_ADMIN_USER \
    --password=$MYSQL_ADMIN_PASSWORD \
    --ssl-mode=REQUIRED \
    < .azure/init-db.sql

echo "✅ Database initialized successfully!"

echo "🧹 Removing temporary firewall rule..."
az mysql flexible-server firewall-rule delete \
    --resource-group $RESOURCE_GROUP \
    --name $MYSQL_SERVER_NAME \
    --rule-name TempLocalAccess \
    --yes

echo ""
echo "✅ Azure MySQL Database is ready!"
echo "Server: $MYSQL_HOST"
echo "Database: $MYSQL_DB_NAME"
echo ""
