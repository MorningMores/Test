# Azure Deployment Checklist

Use this checklist to ensure a smooth deployment to Azure.

## ✅ Pre-Deployment Checklist

### Prerequisites
- [ ] Azure account created with active subscription
- [ ] Azure CLI installed and working (`az --version`)
- [ ] Docker installed and running (`docker --version`)
- [ ] Git installed (`git --version`)
- [ ] MySQL client installed (for database initialization)

### Access Verification
- [ ] Can login to Azure (`az login`)
- [ ] Correct subscription selected (`az account show`)
- [ ] Have necessary permissions (Contributor role or higher)

### Code Preparation
- [ ] On `feature/azure-integration` branch
- [ ] All changes committed
- [ ] No uncommitted changes (`git status`)

## 🚀 Deployment Checklist

### Step 1: Review Configuration
- [ ] Review `.azure/config.json` - resource names and regions
- [ ] Review `.azure/backend.env.template` - backend settings
- [ ] Review `.azure/frontend.env.template` - frontend settings
- [ ] Update JWT_SECRET to a strong value (if not using env vars)
- [ ] Update MySQL admin password (if not using default)

### Step 2: Run Deployment
- [ ] Login to Azure: `az login`
- [ ] Verify subscription: `az account show`
- [ ] Make deployment script executable: `chmod +x azure-deploy.sh`
- [ ] Run deployment: `./azure-deploy.sh`
- [ ] Wait for completion (20-30 minutes)
- [ ] Note down the URLs displayed at the end

### Step 3: Initialize Database
- [ ] Navigate to .azure directory: `cd .azure`
- [ ] Make init script executable: `chmod +x init-database.sh`
- [ ] Run initialization: `./init-database.sh`
- [ ] Enter MySQL admin password when prompted
- [ ] Verify tables created successfully

### Step 4: Verify Deployment
- [ ] Run health check: `./azure-health-check.sh`
- [ ] All services show as "Running"
- [ ] Frontend URL accessible
- [ ] Backend URL accessible
- [ ] Backend health endpoint returns 200: `/actuator/health`

### Step 5: Test Application
- [ ] Open frontend URL in browser
- [ ] Register a new user account
- [ ] Login with registered user
- [ ] Create a test event
- [ ] View event details
- [ ] Book tickets for event
- [ ] Verify booking appears in "My Bookings"
- [ ] Verify participant appears in event details

### Step 6: Configure Monitoring
- [ ] Enable Application Insights (optional)
- [ ] Set up log alerts
- [ ] Configure auto-scaling rules (if needed)
- [ ] Set up budget alerts

## 🔄 CI/CD Setup Checklist

### GitHub Secrets Configuration
- [ ] Go to GitHub repository → Settings → Secrets and variables → Actions
- [ ] Add `AZURE_CREDENTIALS` secret:
  ```bash
  az ad sp create-for-rbac \
    --name "concert-platform-github" \
    --role contributor \
    --scopes /subscriptions/{sub-id}/resourceGroups/rg-concert-platform \
    --sdk-auth
  ```
- [ ] Add `ACR_USERNAME` secret:
  ```bash
  az acr credential show --name concertplatformacr --query username -o tsv
  ```
- [ ] Add `ACR_PASSWORD` secret:
  ```bash
  az acr credential show --name concertplatformacr --query passwords[0].value -o tsv
  ```
- [ ] Add `MYSQL_ADMIN_PASSWORD` secret (use your password)
- [ ] Add `JWT_SECRET_KEY` secret (generate with `openssl rand -base64 32`)

### GitHub Actions Workflow
- [ ] Workflow file exists: `.github/workflows/azure-deploy.yml`
- [ ] Workflow is enabled in GitHub Actions tab
- [ ] Test workflow with manual trigger
- [ ] Verify build succeeds
- [ ] Verify deployment succeeds
- [ ] Verify health checks pass

## 🔒 Security Checklist

### Application Security
- [ ] HTTPS enforced on both App Services
- [ ] JWT secret is strong and unique
- [ ] Database password is strong and unique
- [ ] CORS configured correctly
- [ ] Default admin password changed

### Network Security
- [ ] Database firewall rules configured
- [ ] Only Azure services can access database
- [ ] App Services using private container registry
- [ ] No hardcoded secrets in code

### Access Management
- [ ] Service Principal has minimum required permissions
- [ ] Admin accounts use strong passwords
- [ ] MFA enabled on Azure account (recommended)

## 📊 Post-Deployment Checklist

### Monitoring Setup
- [ ] Log streaming working: `az webapp log tail ...`
- [ ] Health endpoints responding
- [ ] Database connection successful
- [ ] No errors in application logs

### Performance Verification
- [ ] Frontend loads within 3 seconds
- [ ] Backend API responds within 1 second
- [ ] Database queries are fast (< 100ms)
- [ ] No memory leaks observed

### Backup Configuration
- [ ] Database automated backups enabled (should be default)
- [ ] Backup retention set to 7 days minimum
- [ ] events.json backed up (consider Azure Blob Storage)

### Documentation
- [ ] Document deployment date
- [ ] Document resource names
- [ ] Document URLs
- [ ] Document admin credentials (securely)
- [ ] Update team wiki/docs

## 💰 Cost Management Checklist

### Cost Optimization
- [ ] Review current SKUs (B2 for dev, P1V2 for prod)
- [ ] Set up Azure Cost Management alerts
- [ ] Configure auto-scaling to scale down during off-peak
- [ ] Delete unused resources
- [ ] Clean up old container images
- [ ] Consider Reserved Instances for production

### Budget Alerts
- [ ] Set budget alert at 50% of expected costs
- [ ] Set budget alert at 75% of expected costs
- [ ] Set budget alert at 90% of expected costs
- [ ] Set budget alert at 100% of expected costs

## 🔧 Maintenance Checklist

### Regular Maintenance (Weekly)
- [ ] Review application logs for errors
- [ ] Check resource utilization (CPU, memory)
- [ ] Review security alerts
- [ ] Clean up old container images in ACR

### Regular Maintenance (Monthly)
- [ ] Review and optimize database queries
- [ ] Update dependencies (npm, Maven)
- [ ] Review cost reports
- [ ] Test backup restoration
- [ ] Review and update documentation

### Regular Maintenance (Quarterly)
- [ ] Security audit
- [ ] Performance optimization review
- [ ] SKU review (scale up/down as needed)
- [ ] Disaster recovery drill

## 📱 Contact Information

### Azure Resources
- Resource Group: `rg-concert-platform`
- Location: `Southeast Asia`
- Frontend: `https://concert-platform-frontend.azurewebsites.net`
- Backend: `https://concert-platform-backend.azurewebsites.net`
- Database: `concert-platform-mysql-server.mysql.database.azure.com`

### Support
- Azure Support: https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade
- Azure Status: https://status.azure.com/
- Documentation: See AZURE_README.md

## ✅ Final Verification

Before marking deployment as complete:
- [ ] All items in Pre-Deployment checked
- [ ] All items in Deployment checked
- [ ] All items in Post-Deployment checked
- [ ] Application is fully functional
- [ ] Team members can access the application
- [ ] Documentation is updated
- [ ] Stakeholders are notified

## 🎉 Deployment Complete!

Once all checklist items are complete:
- [ ] Update project status to "Deployed"
- [ ] Notify team members
- [ ] Share URLs with stakeholders
- [ ] Schedule follow-up review in 1 week

---

**Deployment Date**: _________________  
**Deployed By**: _________________  
**Reviewed By**: _________________  
**Status**: [ ] Complete [ ] In Progress [ ] Blocked

**Notes**:
_____________________________________________
_____________________________________________
_____________________________________________
