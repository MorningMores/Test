# Quick Reference - Azure Commands

## 🚀 Deployment

### Initial Deployment
```bash
# One-click deployment
./azure-deploy.sh

# Or manual deployment
az login
az group create --name rg-concert-platform --location southeastasia
```

### Redeploy Application
```bash
# Rebuild and redeploy backend
cd main_backend
docker build -f Dockerfile.azure -t concertplatformacr.azurecr.io/backend:latest .
docker push concertplatformacr.azurecr.io/backend:latest
az webapp restart --name concert-platform-backend --resource-group rg-concert-platform

# Rebuild and redeploy frontend
cd main_frontend/concert1
docker build -f Dockerfile.azure -t concertplatformacr.azurecr.io/frontend:latest .
docker push concertplatformacr.azurecr.io/frontend:latest
az webapp restart --name concert-platform-frontend --resource-group rg-concert-platform
```

## 📊 Monitoring

### View Logs
```bash
# Stream backend logs
az webapp log tail --name concert-platform-backend --resource-group rg-concert-platform

# Stream frontend logs
az webapp log tail --name concert-platform-frontend --resource-group rg-concert-platform

# Download logs
az webapp log download --name concert-platform-backend --resource-group rg-concert-platform --log-file backend-logs.zip
```

### Check Status
```bash
# List all resources
az resource list --resource-group rg-concert-platform --output table

# Check app service status
az webapp show --name concert-platform-backend --resource-group rg-concert-platform --query state

# Check database status
az mysql flexible-server show --name concert-platform-mysql-server --resource-group rg-concert-platform
```

## 🔧 Management

### Restart Services
```bash
# Restart backend
az webapp restart --name concert-platform-backend --resource-group rg-concert-platform

# Restart frontend
az webapp restart --name concert-platform-frontend --resource-group rg-concert-platform
```

### Update Configuration
```bash
# Update backend environment variable
az webapp config appsettings set --name concert-platform-backend --resource-group rg-concert-platform --settings JWT_SECRET=new_secret

# Update frontend environment variable
az webapp config appsettings set --name concert-platform-frontend --resource-group rg-concert-platform --settings NUXT_PUBLIC_API_BASE_URL=https://new-backend-url.com
```

### Scale Services
```bash
# Scale up (bigger instance)
az appservice plan update --name concert-platform-plan --resource-group rg-concert-platform --sku P1V2

# Scale out (more instances)
az appservice plan update --name concert-platform-plan --resource-group rg-concert-platform --number-of-workers 3
```

## 🗄️ Database

### Connect to Database
```bash
mysql -h concert-platform-mysql-server.mysql.database.azure.com -u myadmin -p
```

### Backup Database
```bash
# List backups
az mysql flexible-server backup list --resource-group rg-concert-platform --server-name concert-platform-mysql-server

# Restore from backup
az mysql flexible-server restore --resource-group rg-concert-platform --name concert-platform-mysql-restored --source-server concert-platform-mysql-server --restore-time "2025-10-13T10:00:00Z"
```

## 🐳 Container Registry

### Manage Images
```bash
# List repositories
az acr repository list --name concertplatformacr

# List tags
az acr repository show-tags --name concertplatformacr --repository backend

# Delete old images
az acr repository delete --name concertplatformacr --image backend:old-tag --yes
```

## 🔒 Security

### Rotate Secrets
```bash
# Update JWT secret
az webapp config appsettings set --name concert-platform-backend --resource-group rg-concert-platform --settings JWT_SECRET=$(openssl rand -base64 32)

# Regenerate database password
az mysql flexible-server update --resource-group rg-concert-platform --name concert-platform-mysql-server --admin-password NewSecurePassword123!
```

### Configure Firewall
```bash
# Allow your IP
MY_IP=$(curl -s https://api.ipify.org)
az mysql flexible-server firewall-rule create --resource-group rg-concert-platform --name concert-platform-mysql-server --rule-name MyIP --start-ip-address $MY_IP --end-ip-address $MY_IP

# Allow Azure services
az mysql flexible-server firewall-rule create --resource-group rg-concert-platform --name concert-platform-mysql-server --rule-name AllowAzure --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
```

## 💰 Cost Management

### View Costs
```bash
# Show current month costs
az consumption usage list --start-date $(date -u -d '1 day ago' +%Y-%m-%d) --end-date $(date -u +%Y-%m-%d) --query "[?contains(instanceName, 'concert-platform')]"

# Get cost by resource
az cost-management query --type Usage --dataset-filter "ResourceGroup eq 'rg-concert-platform'" --timeframe MonthToDate
```

## 🗑️ Cleanup

### Delete Everything
```bash
# Delete entire resource group (THIS DELETES ALL RESOURCES!)
az group delete --name rg-concert-platform --yes --no-wait
```

### Delete Specific Resources
```bash
# Delete app service
az webapp delete --name concert-platform-backend --resource-group rg-concert-platform

# Delete database
az mysql flexible-server delete --resource-group rg-concert-platform --name concert-platform-mysql-server --yes
```

## 🔍 Troubleshooting

### Debug Container Issues
```bash
# SSH into container
az webapp ssh --name concert-platform-backend --resource-group rg-concert-platform

# View container logs
az webapp log show --name concert-platform-backend --resource-group rg-concert-platform

# Check health endpoint
curl https://concert-platform-backend.azurewebsites.net/actuator/health
```

### Test Database Connection
```bash
# From local machine
mysql -h concert-platform-mysql-server.mysql.database.azure.com -u myadmin -p -e "SHOW DATABASES;"

# Test from App Service
az webapp ssh --name concert-platform-backend --resource-group rg-concert-platform
apt-get update && apt-get install -y mysql-client
mysql -h concert-platform-mysql-server.mysql.database.azure.com -u myadmin -p
```

## 📱 URLs

### Application URLs
```
Frontend: https://concert-platform-frontend.azurewebsites.net
Backend: https://concert-platform-backend.azurewebsites.net
Backend Health: https://concert-platform-backend.azurewebsites.net/actuator/health
Backend API Docs: https://concert-platform-backend.azurewebsites.net/swagger-ui.html
```

### Azure Portal URLs
```
Resource Group: https://portal.azure.com/#@/resource/subscriptions/YOUR_SUB_ID/resourceGroups/rg-concert-platform
App Services: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Web%2Fsites
Database: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.DBforMySQL%2FflexibleServers
```

---

**Quick Start**: `./azure-deploy.sh`  
**View Logs**: `az webapp log tail --name concert-platform-backend --resource-group rg-concert-platform`  
**Restart**: `az webapp restart --name concert-platform-backend --resource-group rg-concert-platform`
