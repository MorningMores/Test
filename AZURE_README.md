# Azure Integration - README

## 🎯 Overview

This branch (`feature/azure-integration`) contains all necessary files and configurations to deploy the Concert Event Platform to Microsoft Azure.

## 📁 Azure Files Structure

```
.
├── .azure/
│   ├── config.json                    # Azure resource configuration
│   ├── backend.env.template           # Backend environment variables template
│   ├── frontend.env.template          # Frontend environment variables template
│   ├── init-db.sql                    # Database schema initialization
│   └── init-database.sh               # Database initialization script
├── .github/
│   └── workflows/
│       └── azure-deploy.yml           # GitHub Actions CI/CD pipeline
├── main_backend/
│   ├── Dockerfile.azure               # Optimized Dockerfile for Azure
│   └── src/main/resources/
│       └── application-azure.properties  # Azure-specific Spring Boot config
├── main_frontend/concert1/
│   └── Dockerfile.azure               # Optimized Dockerfile for Azure
├── azure-deploy.sh                    # One-click deployment script
├── azure-health-check.sh              # Health check script for deployed services
├── AZURE_DEPLOYMENT_GUIDE.md          # Comprehensive deployment guide
├── AZURE_ARCHITECTURE.md              # Architecture documentation
└── AZURE_QUICK_REFERENCE.md           # Quick command reference
```

## 🚀 Quick Deployment

### Prerequisites
1. Azure account with active subscription
2. Azure CLI installed ([Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
3. Docker installed and running
4. Git installed

### One-Click Deployment

```bash
# 1. Login to Azure
az login

# 2. Run deployment script
./azure-deploy.sh
```

This will deploy:
- ✅ Azure Resource Group
- ✅ Azure Container Registry
- ✅ Azure Database for MySQL (Flexible Server)
- ✅ Backend App Service (Java 21 + Spring Boot)
- ✅ Frontend App Service (Node 20 + Nuxt 4)
- ✅ All necessary networking and security configurations

**Estimated deployment time**: 20-30 minutes

### Access Your Application

After deployment completes:
```
Frontend: https://concert-platform-frontend.azurewebsites.net
Backend:  https://concert-platform-backend.azurewebsites.net
API Docs: https://concert-platform-backend.azurewebsites.net/actuator/health
```

## 📊 Architecture

### Azure Resources

| Resource | Type | SKU | Purpose |
|----------|------|-----|---------|
| Resource Group | rg-concert-platform | - | Container for all resources |
| Container Registry | concertplatformacr | Basic | Store Docker images |
| App Service Plan | concert-platform-plan | B2 | Host web applications |
| Frontend App | App Service (Linux) | Node 20 | Nuxt 4 SSR application |
| Backend App | App Service (Linux) | Java 21 | Spring Boot REST API |
| MySQL Server | Flexible Server | B1ms | MySQL 8.0 database |

### Data Flow

```
User → Frontend (Nuxt) → Backend (Spring Boot) → MySQL Database
                ↓                    ↓
         events.json            JWT Auth
```

## 🔧 Configuration

### Environment Variables

#### Backend (`main_backend`)
See `.azure/backend.env.template` for all required variables:
- `SPRING_DATASOURCE_URL` - MySQL connection string
- `SPRING_DATASOURCE_USERNAME` - Database username
- `SPRING_DATASOURCE_PASSWORD` - Database password
- `JWT_SECRET` - JWT signing secret
- `CORS_ALLOWED_ORIGINS` - Allowed CORS origins

#### Frontend (`main_frontend/concert1`)
See `.azure/frontend.env.template` for all required variables:
- `NUXT_PUBLIC_API_BASE_URL` - Backend API URL
- `NODE_ENV` - Environment (production)
- `PORT` - Server port (3000)

### Database Setup

Initialize the database after deployment:

```bash
cd .azure
./init-database.sh
```

This creates:
- ✅ `concert_db` database
- ✅ `users` table
- ✅ `bookings` table
- ✅ `refresh_tokens` table
- ✅ `audit_logs` table
- ✅ Default admin user

**Default Admin Credentials:**
- Username: `admin`
- Email: `admin@concert-platform.com`
- Password: `Admin123!`

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The workflow (`.github/workflows/azure-deploy.yml`) automatically triggers on:
- Push to `main` branch
- Push to `feature/azure-integration` branch
- Pull requests to `main`
- Manual workflow dispatch

### Required GitHub Secrets

Set these in your GitHub repository settings:

1. **AZURE_CREDENTIALS** - Azure service principal JSON
   ```bash
   az ad sp create-for-rbac --name "concert-platform-github" \
     --role contributor \
     --scopes /subscriptions/{subscription-id}/resourceGroups/rg-concert-platform \
     --sdk-auth
   ```

2. **ACR_USERNAME** - Container Registry username
   ```bash
   az acr credential show --name concertplatformacr --query username -o tsv
   ```

3. **ACR_PASSWORD** - Container Registry password
   ```bash
   az acr credential show --name concertplatformacr --query passwords[0].value -o tsv
   ```

4. **MYSQL_ADMIN_PASSWORD** - Database admin password
5. **JWT_SECRET_KEY** - JWT signing secret

### Deployment Workflow

```
1. Code pushed to main/feature branch
   ↓
2. GitHub Actions triggered
   ↓
3. Build Docker images (backend + frontend)
   ↓
4. Push images to Azure Container Registry
   ↓
5. Deploy to App Services
   ↓
6. Run health checks
   ↓
7. Deployment complete! 🎉
```

## 📈 Monitoring

### Health Checks

Run the health check script:

```bash
./azure-health-check.sh
```

This checks:
- ✅ Frontend App Service status
- ✅ Backend App Service status
- ✅ MySQL Server status
- ✅ Container Registry status
- ✅ HTTP endpoints accessibility

### View Logs

```bash
# Stream backend logs
az webapp log tail --name concert-platform-backend --resource-group rg-concert-platform

# Stream frontend logs
az webapp log tail --name concert-platform-frontend --resource-group rg-concert-platform

# Download logs
az webapp log download --name concert-platform-backend --resource-group rg-concert-platform
```

### Azure Portal

Monitor your services in Azure Portal:
- App Services: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Web%2Fsites
- Databases: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.DBforMySQL%2FflexibleServers
- Resource Group: https://portal.azure.com/#@/resource/subscriptions/YOUR_SUB_ID/resourceGroups/rg-concert-platform

## 🛠️ Maintenance

### Update Application

```bash
# 1. Make code changes
# 2. Commit and push to GitHub
git add .
git commit -m "Update application"
git push origin feature/azure-integration

# GitHub Actions will automatically deploy
```

Or manually:

```bash
# Rebuild and redeploy backend
cd main_backend
docker build -f Dockerfile.azure -t concertplatformacr.azurecr.io/backend:latest .
docker push concertplatformacr.azurecr.io/backend:latest
az webapp restart --name concert-platform-backend --resource-group rg-concert-platform

# Rebuild and redeploy frontend
cd ../main_frontend/concert1
docker build -f Dockerfile.azure -t concertplatformacr.azurecr.io/frontend:latest .
docker push concertplatformacr.azurecr.io/frontend:latest
az webapp restart --name concert-platform-frontend --resource-group rg-concert-platform
```

### Scale Services

```bash
# Scale up (bigger instance)
az appservice plan update --name concert-platform-plan --resource-group rg-concert-platform --sku P1V2

# Scale out (more instances)
az appservice plan update --name concert-platform-plan --resource-group rg-concert-platform --number-of-workers 3

# Enable auto-scaling
az monitor autoscale create --resource-group rg-concert-platform \
  --resource concert-platform-plan \
  --resource-type Microsoft.Web/serverfarms \
  --name concert-autoscale \
  --min-count 1 \
  --max-count 5 \
  --count 2
```

### Backup Database

```bash
# List backups
az mysql flexible-server backup list --resource-group rg-concert-platform --server-name concert-platform-mysql-server

# Restore from backup
az mysql flexible-server restore --resource-group rg-concert-platform \
  --name concert-platform-mysql-restored \
  --source-server concert-platform-mysql-server \
  --restore-time "2025-10-13T10:00:00Z"
```

## 💰 Cost Estimation

### Development Environment (~$30/month)
- App Service Plan (B1): $13
- MySQL (B_Standard_B1ms): $12
- Container Registry (Basic): $5

### Production Environment (~$355/month)
- App Service Plan (P1V2 x2): $140
- MySQL (GP_Standard_D2ds_v4): $140
- Container Registry (Standard): $20
- Application Insights: $20
- Azure Front Door: $30
- Storage & Bandwidth: $5

### Cost Optimization
- Use Azure Reserved Instances (40-60% savings)
- Enable auto-scaling for off-peak hours
- Clean up old container images
- Use Azure Hybrid Benefit if applicable

## 🔒 Security

### Implemented Security Features
- ✅ HTTPS enforced on all App Services
- ✅ Database firewall rules (Azure services only)
- ✅ JWT authentication
- ✅ CORS configured properly
- ✅ Container images from private registry
- ✅ Secrets managed via App Service settings

### Recommended Enhancements
- [ ] Azure Key Vault for secrets
- [ ] Azure Application Gateway + WAF
- [ ] Azure DDoS Protection
- [ ] Managed Identities for inter-service auth
- [ ] Private endpoints for database

## 🗑️ Cleanup

### Delete All Resources

```bash
# WARNING: This deletes everything!
az group delete --name rg-concert-platform --yes --no-wait
```

## 📚 Documentation

- **[AZURE_DEPLOYMENT_GUIDE.md](./AZURE_DEPLOYMENT_GUIDE.md)** - Complete deployment guide
- **[AZURE_ARCHITECTURE.md](./AZURE_ARCHITECTURE.md)** - Architecture documentation
- **[AZURE_QUICK_REFERENCE.md](./AZURE_QUICK_REFERENCE.md)** - Quick command reference

## 🆘 Troubleshooting

### Common Issues

#### Container won't start
```bash
# Check logs
az webapp log tail --name YOUR_APP_NAME --resource-group rg-concert-platform

# Verify WEBSITES_PORT is set
az webapp config appsettings list --name YOUR_APP_NAME --resource-group rg-concert-platform
```

#### Database connection fails
```bash
# Test connection
mysql -h concert-platform-mysql-server.mysql.database.azure.com -u myadmin -p

# Check firewall rules
az mysql flexible-server firewall-rule list --resource-group rg-concert-platform --server-name concert-platform-mysql-server
```

#### 502 Bad Gateway
- Wait 2-3 minutes for container to start
- Check health endpoint: `curl https://YOUR_APP.azurewebsites.net/actuator/health`
- Restart app: `az webapp restart --name YOUR_APP --resource-group rg-concert-platform`

## 📞 Support

For issues or questions:
1. Check the [troubleshooting section](#troubleshooting)
2. Review Azure Portal logs
3. Run health check script: `./azure-health-check.sh`
4. Check [Azure documentation](https://docs.microsoft.com/en-us/azure/)

---

**Branch**: `feature/azure-integration`  
**Last Updated**: October 13, 2025  
**Azure Region**: Southeast Asia  
**Status**: ✅ Ready for Deployment
