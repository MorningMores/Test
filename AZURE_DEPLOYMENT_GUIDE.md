# Azure Deployment Guide - Concert Event Platform

## 📋 Prerequisites

Before deploying to Azure, ensure you have:

1. **Azure Account** with active subscription
2. **Azure CLI** installed ([Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
3. **Docker** installed and running
4. **Git** for version control
5. **MySQL Client** (for database initialization)

## 🚀 Quick Start Deployment

### Option 1: One-Click Deployment Script

```bash
# Login to Azure
az login

# Run the deployment script
./azure-deploy.sh
```

This script will automatically:
- Create Azure Resource Group
- Create Azure Container Registry (ACR)
- Build and push Docker images
- Create Azure Database for MySQL
- Create App Service Plan
- Deploy Frontend and Backend services
- Configure environment variables
- Enable logging

**Estimated time**: 20-30 minutes

### Option 2: Manual Step-by-Step Deployment

#### Step 1: Login to Azure
```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

#### Step 2: Create Resource Group
```bash
az group create \
    --name rg-concert-platform \
    --location southeastasia
```

#### Step 3: Create Azure Container Registry
```bash
az acr create \
    --resource-group rg-concert-platform \
    --name concertplatformacr \
    --sku Basic \
    --admin-enabled true
```

#### Step 4: Build and Push Images
```bash
# Login to ACR
az acr login --name concertplatformacr

# Build and push backend
cd main_backend
docker build -f Dockerfile.azure -t concertplatformacr.azurecr.io/backend:latest .
docker push concertplatformacr.azurecr.io/backend:latest

# Build and push frontend
cd ../main_frontend/concert1
docker build -f Dockerfile.azure -t concertplatformacr.azurecr.io/frontend:latest .
docker push concertplatformacr.azurecr.io/frontend:latest
```

#### Step 5: Create MySQL Database
```bash
az mysql flexible-server create \
    --resource-group rg-concert-platform \
    --name concert-platform-mysql \
    --location southeastasia \
    --admin-user myadmin \
    --admin-password "YOUR_SECURE_PASSWORD" \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --storage-size 20 \
    --version 8.0
```

#### Step 6: Initialize Database
```bash
cd .azure
./init-database.sh
```

#### Step 7: Create App Services
```bash
# Create App Service Plan
az appservice plan create \
    --name concert-platform-plan \
    --resource-group rg-concert-platform \
    --location southeastasia \
    --is-linux \
    --sku B2

# Create Backend App Service
az webapp create \
    --resource-group rg-concert-platform \
    --plan concert-platform-plan \
    --name concert-platform-backend \
    --deployment-container-image-name concertplatformacr.azurecr.io/backend:latest

# Create Frontend App Service
az webapp create \
    --resource-group rg-concert-platform \
    --plan concert-platform-plan \
    --name concert-platform-frontend \
    --deployment-container-image-name concertplatformacr.azurecr.io/frontend:latest
```

#### Step 8: Configure Environment Variables

See `.azure/backend.env.template` and `.azure/frontend.env.template` for required variables.

```bash
# Backend configuration
az webapp config appsettings set \
    --resource-group rg-concert-platform \
    --name concert-platform-backend \
    --settings @backend-settings.json

# Frontend configuration
az webapp config appsettings set \
    --resource-group rg-concert-platform \
    --name concert-platform-frontend \
    --settings @frontend-settings.json
```

## 🔄 CI/CD with GitHub Actions

### Setup GitHub Secrets

Add these secrets to your GitHub repository:

1. **AZURE_CREDENTIALS** - Service Principal credentials
2. **ACR_USERNAME** - Container Registry username
3. **ACR_PASSWORD** - Container Registry password
4. **MYSQL_ADMIN_PASSWORD** - Database password
5. **JWT_SECRET_KEY** - JWT secret for backend

### Create Service Principal

```bash
az ad sp create-for-rbac \
    --name "concert-platform-github" \
    --role contributor \
    --scopes /subscriptions/{subscription-id}/resourceGroups/rg-concert-platform \
    --sdk-auth
```

Copy the output JSON and add it as `AZURE_CREDENTIALS` secret.

### Trigger Deployment

The GitHub Actions workflow (`.github/workflows/azure-deploy.yml`) will automatically trigger on:
- Push to `main` branch
- Push to `feature/azure-integration` branch
- Pull requests to `main`
- Manual workflow dispatch

## 📊 Monitoring and Logging

### View Application Logs

```bash
# Backend logs
az webapp log tail \
    --name concert-platform-backend \
    --resource-group rg-concert-platform

# Frontend logs
az webapp log tail \
    --name concert-platform-frontend \
    --resource-group rg-concert-platform
```

### Enable Application Insights (Optional)

```bash
# Create Application Insights
az monitor app-insights component create \
    --app concert-platform-insights \
    --location southeastasia \
    --resource-group rg-concert-platform

# Get instrumentation key
az monitor app-insights component show \
    --app concert-platform-insights \
    --resource-group rg-concert-platform \
    --query instrumentationKey
```

## 🔒 Security Best Practices

1. **Use Azure Key Vault** for sensitive credentials
2. **Enable HTTPS only** for all App Services
3. **Configure CORS** properly in backend
4. **Use Managed Identities** instead of passwords where possible
5. **Enable Azure DDoS Protection**
6. **Set up Azure Firewall** rules
7. **Regular security updates** for dependencies

### Enable HTTPS and Custom Domain

```bash
# Force HTTPS
az webapp update \
    --resource-group rg-concert-platform \
    --name concert-platform-frontend \
    --https-only true

# Add custom domain (if you have one)
az webapp config hostname add \
    --webapp-name concert-platform-frontend \
    --resource-group rg-concert-platform \
    --hostname www.yourdomain.com
```

## 💰 Cost Optimization

### Recommended SKUs by Environment

**Development/Testing:**
- App Service: B1 ($13/month)
- MySQL: B_Standard_B1ms ($12/month)
- Total: ~$25/month

**Production:**
- App Service: P1V2 ($70/month)
- MySQL: GP_Standard_D2ds_v4 ($140/month)
- Total: ~$210/month

### Cost Saving Tips

1. Use **Azure Reserved Instances** for 40-60% savings
2. Set up **auto-scaling** to scale down during off-peak hours
3. Enable **Azure Hybrid Benefit** if you have licenses
4. Use **Azure Cost Management** to monitor spending
5. Delete unused resources regularly

## 🔧 Troubleshooting

### Common Issues

#### 1. Container fails to start
```bash
# Check logs
az webapp log tail --name YOUR_APP_NAME --resource-group rg-concert-platform

# Check container settings
az webapp config show --name YOUR_APP_NAME --resource-group rg-concert-platform
```

#### 2. Database connection fails
- Verify firewall rules allow Azure services
- Check connection string format
- Verify credentials
- Test with MySQL client:
```bash
mysql -h YOUR_SERVER.mysql.database.azure.com -u myadmin -p
```

#### 3. 502 Bad Gateway
- Container might be starting (wait 2-3 minutes)
- Check WEBSITES_PORT is set correctly (8080 for backend, 3000 for frontend)
- Verify health check endpoint is accessible

#### 4. Image pull fails
- Verify ACR credentials are correct
- Check image exists: `az acr repository list --name concertplatformacr`
- Ensure App Service has permission to pull from ACR

### Debug Commands

```bash
# Restart app
az webapp restart --name YOUR_APP_NAME --resource-group rg-concert-platform

# View environment variables
az webapp config appsettings list --name YOUR_APP_NAME --resource-group rg-concert-platform

# SSH into container
az webapp ssh --name YOUR_APP_NAME --resource-group rg-concert-platform

# Check deployment status
az webapp deployment list --name YOUR_APP_NAME --resource-group rg-concert-platform
```

## 🔄 Updates and Maintenance

### Update Application Code

```bash
# Rebuild and push images
docker build -f Dockerfile.azure -t concertplatformacr.azurecr.io/backend:v2 .
docker push concertplatformacr.azurecr.io/backend:v2

# Update app service
az webapp config container set \
    --name concert-platform-backend \
    --resource-group rg-concert-platform \
    --docker-custom-image-name concertplatformacr.azurecr.io/backend:v2
```

### Database Migrations

```bash
# Backup database first
az mysql flexible-server backup list \
    --resource-group rg-concert-platform \
    --server-name concert-platform-mysql

# Run migration scripts
mysql -h YOUR_SERVER.mysql.database.azure.com -u myadmin -p < migration.sql
```

## 📱 Scaling

### Manual Scaling

```bash
# Scale up (more powerful instance)
az appservice plan update \
    --name concert-platform-plan \
    --resource-group rg-concert-platform \
    --sku P1V2

# Scale out (more instances)
az appservice plan update \
    --name concert-platform-plan \
    --resource-group rg-concert-platform \
    --number-of-workers 3
```

### Auto-scaling

```bash
# Enable auto-scale
az monitor autoscale create \
    --resource-group rg-concert-platform \
    --resource concert-platform-plan \
    --resource-type Microsoft.Web/serverfarms \
    --name concert-autoscale \
    --min-count 1 \
    --max-count 5 \
    --count 2

# Add CPU-based rule
az monitor autoscale rule create \
    --resource-group rg-concert-platform \
    --autoscale-name concert-autoscale \
    --condition "Percentage CPU > 70 avg 5m" \
    --scale out 1
```

## 🗑️ Cleanup

### Delete All Resources

```bash
# Delete entire resource group
az group delete --name rg-concert-platform --yes --no-wait
```

## 📚 Additional Resources

- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Database for MySQL Documentation](https://docs.microsoft.com/en-us/azure/mysql/)
- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)

## 🆘 Support

If you encounter issues:
1. Check Azure Portal for service health
2. Review application logs
3. Verify resource configurations
4. Check firewall and network settings
5. Contact Azure Support if needed

---

**Last Updated**: October 13, 2025  
**Azure Region**: Southeast Asia  
**Deployment Status**: Ready for Production
