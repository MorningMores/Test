# Azure Architecture - Concert Event Platform

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Cloud Platform                      │
│                                                                   │
│  ┌────────────────┐         ┌────────────────┐                  │
│  │   Azure CDN    │         │  Application   │                  │
│  │   (Optional)   │────────▶│   Insights     │                  │
│  └────────────────┘         └────────────────┘                  │
│         │                            │                           │
│         │                            │ (Monitoring)              │
│         ▼                            │                           │
│  ┌────────────────────────────────────────────┐                 │
│  │        Azure Load Balancer                 │                 │
│  │        (Traffic Distribution)              │                 │
│  └────────────────────────────────────────────┘                 │
│         │                            │                           │
│         ▼                            ▼                           │
│  ┌─────────────────┐        ┌─────────────────┐                │
│  │  Frontend       │        │  Backend        │                 │
│  │  App Service    │───────▶│  App Service    │                │
│  │  (Nuxt 4)       │        │  (Spring Boot)  │                 │
│  │  Port: 3000     │        │  Port: 8080     │                 │
│  └─────────────────┘        └─────────────────┘                 │
│         │                            │                           │
│         │                            ▼                           │
│         │                   ┌─────────────────┐                 │
│         │                   │  Azure Database │                 │
│         │                   │  for MySQL      │                 │
│         │                   │  (Flexible)     │                 │
│         │                   └─────────────────┘                 │
│         │                            │                           │
│         ▼                            ▼                           │
│  ┌─────────────────┐        ┌─────────────────┐                │
│  │  Azure Blob     │        │  Azure Key      │                 │
│  │  Storage        │        │  Vault          │                 │
│  │  (events.json)  │        │  (Secrets)      │                 │
│  └─────────────────┘        └─────────────────┘                 │
│                                                                   │
│  ┌────────────────────────────────────────────┐                 │
│  │  Azure Container Registry (ACR)            │                 │
│  │  - Frontend Image                          │                 │
│  │  - Backend Image                           │                 │
│  └────────────────────────────────────────────┘                 │
└─────────────────────────────────────────────────────────────────┘

         │
         ▼
   ┌──────────────┐
   │   GitHub     │
   │   Actions    │
   │   CI/CD      │
   └──────────────┘
```

## 📦 Azure Resources

### 1. Resource Group
- **Name**: `rg-concert-platform`
- **Location**: Southeast Asia
- **Purpose**: Container for all related resources

### 2. Azure Container Registry (ACR)
- **Name**: `concertplatformacr`
- **SKU**: Basic
- **Purpose**: Store Docker images for frontend and backend
- **Images**:
  - `concert-platform-frontend:latest`
  - `concert-platform-backend:latest`

### 3. App Service Plan
- **Name**: `concert-platform-plan`
- **SKU**: B2 (2 cores, 3.5 GB RAM)
- **OS**: Linux
- **Purpose**: Host both frontend and backend services

### 4. App Services

#### Frontend App Service
- **Name**: `concert-platform-frontend`
- **Runtime**: Node.js 20 LTS
- **Port**: 3000
- **URL**: `https://concert-platform-frontend.azurewebsites.net`
- **Features**:
  - Nuxt 4 SSR
  - Auto-scaling enabled
  - Health checks
  - Application logging

#### Backend App Service
- **Name**: `concert-platform-backend`
- **Runtime**: Java 21
- **Port**: 8080
- **URL**: `https://concert-platform-backend.azurewebsites.net`
- **Features**:
  - Spring Boot REST API
  - JWT authentication
  - Actuator health endpoints
  - Application logging

### 5. Azure Database for MySQL (Flexible Server)
- **Name**: `concert-platform-mysql-server`
- **Version**: MySQL 8.0
- **SKU**: Standard_B1ms (Burstable)
- **Storage**: 20 GB
- **Backup**: 7-day retention
- **High Availability**: Zone redundant (optional)
- **Databases**:
  - `concert_db` (main application database)

### 6. Azure Blob Storage (Optional)
- **Name**: `concertplatformstorage`
- **Purpose**: Store events.json and media files
- **Container**: `events-data`
- **Access**: Private with SAS tokens

### 7. Azure Key Vault (Recommended)
- **Name**: `concert-platform-keyvault`
- **Purpose**: Secure storage for:
  - Database passwords
  - JWT secrets
  - API keys
  - Connection strings

### 8. Application Insights (Optional)
- **Name**: `concert-platform-insights`
- **Purpose**: Application performance monitoring
- **Features**:
  - Request tracking
  - Dependency monitoring
  - Exception tracking
  - Custom metrics

## 🔐 Security Architecture

### Network Security
```
Internet
   │
   ▼
Azure Front Door / CDN
   │
   ▼
Web Application Firewall (WAF)
   │
   ▼
App Services (HTTPS only)
   │
   ▼
Private Endpoint
   │
   ▼
Azure Database for MySQL
(Private network)
```

### Authentication Flow
```
User Login
   │
   ▼
Frontend (Nuxt)
   │
   ▼
Backend API (/api/auth/login)
   │
   ▼
MySQL (users table)
   │
   ▼
JWT Token Generation
   │
   ▼
Token stored in localStorage
   │
   ▼
Subsequent requests include
Authorization: Bearer {token}
```

## 📊 Data Flow

### Event Booking Flow
```
1. User selects event
   │
   ▼
2. Frontend validates selection
   │
   ▼
3. POST /api/bookings (with JWT)
   │
   ▼
4. Backend validates token
   │
   ▼
5. Create booking in MySQL
   │
   ▼
6. Fetch user profile
   │
   ▼
7. Update participants in events.json
   │
   ▼
8. Return success response
   │
   ▼
9. Update UI with participant list
```

### Event Creation Flow
```
1. User creates event (authenticated)
   │
   ▼
2. Frontend sends POST /api/events/json
   │
   ▼
3. Backend validates JWT
   │
   ▼
4. Write to events.json
   │
   ▼
5. Return created event
   │
   ▼
6. Redirect to My Events page
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
```
Push to main/feature/azure-integration
   │
   ▼
1. Checkout code
   │
   ▼
2. Login to Azure
   │
   ▼
3. Login to ACR
   │
   ▼
4. Build Docker images
   │  ├── Backend (Java 21)
   │  └── Frontend (Node 20)
   │
   ▼
5. Push images to ACR
   │
   ▼
6. Deploy to App Services
   │  ├── Update backend container
   │  └── Update frontend container
   │
   ▼
7. Health checks
   │  ├── Backend: /actuator/health
   │  └── Frontend: /
   │
   ▼
8. Deployment complete
```

## 🔌 API Architecture

### Backend Endpoints

#### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user profile

#### Events
- `GET /api/events/json` - List all events
- `GET /api/events/json/{id}` - Get event details
- `POST /api/events/json` - Create event (auth required)
- `PUT /api/events/json/{id}` - Update event (auth required)
- `DELETE /api/events/json/{id}` - Delete event (auth required)
- `POST /api/events/json/{id}/add-participant` - Add participant

#### Bookings
- `GET /api/bookings` - List user bookings (auth required)
- `POST /api/bookings` - Create booking (auth required)
- `DELETE /api/bookings/{id}` - Cancel booking (auth required)

#### Health
- `GET /actuator/health` - Health check
- `GET /actuator/info` - Application info

## 📈 Scaling Strategy

### Horizontal Scaling (Scale Out)
```
Normal Load (1-100 users)
└── 1 instance of each service

Medium Load (100-500 users)
└── 2-3 instances of each service

High Load (500+ users)
└── 3-5 instances of each service
```

### Auto-scaling Rules
```yaml
Frontend:
  - CPU > 70% for 5 min → Scale out +1
  - CPU < 30% for 10 min → Scale in -1
  - Min instances: 1
  - Max instances: 5

Backend:
  - CPU > 70% for 5 min → Scale out +1
  - Memory > 80% for 5 min → Scale out +1
  - CPU < 30% for 10 min → Scale in -1
  - Min instances: 1
  - Max instances: 5

Database:
  - Storage > 80% → Auto-grow +10GB
  - CPU > 80% → Recommend scale up
```

## 💾 Backup Strategy

### Database Backups
- **Automated backups**: Daily at 2:00 AM UTC
- **Retention**: 7 days
- **Point-in-time restore**: Available
- **Geo-redundant**: Optional (recommended for production)

### Application Data Backups
- **events.json**: Backed up to Azure Blob Storage daily
- **Container images**: Retained in ACR
- **Configuration**: Stored in Git repository

## 🔍 Monitoring and Alerting

### Key Metrics to Monitor
1. **Application Performance**
   - Response time (< 200ms target)
   - Error rate (< 1% target)
   - Request throughput

2. **Resource Utilization**
   - CPU usage (< 70% normal)
   - Memory usage (< 80% normal)
   - Storage usage

3. **Database Performance**
   - Query execution time
   - Connection count
   - Deadlocks

4. **Availability**
   - Uptime (99.9% SLA target)
   - Health check success rate

### Alert Configuration
```
Critical Alerts (Immediate):
- App Service down
- Database connection failure
- Error rate > 5%

Warning Alerts (15 min):
- CPU > 80%
- Memory > 85%
- Response time > 1s

Info Alerts (Daily):
- Backup completion
- Deployment success
- Cost summary
```

## 💰 Cost Estimation

### Monthly Costs (Southeast Asia region)

#### Development Environment
```
App Service Plan (B1): $13
MySQL (B_Standard_B1ms): $12
Container Registry (Basic): $5
Storage (5GB): $0.10
Total: ~$30/month
```

#### Production Environment
```
App Service Plan (P1V2 x2): $140
MySQL (GP_Standard_D2ds_v4): $140
Container Registry (Standard): $20
Storage (20GB + bandwidth): $5
Application Insights: $20
Azure Front Door: $30
Total: ~$355/month
```

### Cost Optimization Tips
1. Use reserved instances for 40% savings
2. Enable auto-scaling to scale down during off-peak
3. Use Azure Hybrid Benefit if applicable
4. Implement caching to reduce database load
5. Clean up old container images regularly

## 🌍 Multi-Region Deployment (Future)

For global scale, consider:

```
Primary Region: Southeast Asia
├── All services (read/write)
└── Master database

Secondary Region: East Asia
├── Read replicas
└── CDN edge locations

Disaster Recovery Region: Japan East
└── Failover replica
```

## 📚 Technology Stack

### Frontend
- **Framework**: Nuxt 4 (Vue 3)
- **Runtime**: Node.js 20 LTS
- **Styling**: Tailwind CSS
- **State Management**: Vue Composition API
- **HTTP Client**: $fetch (ofetch)

### Backend
- **Framework**: Spring Boot 3.2.0
- **Runtime**: Java 21
- **Database ORM**: Spring Data JPA / Hibernate
- **Security**: Spring Security + JWT
- **API Documentation**: Spring REST Docs

### Database
- **Type**: MySQL 8.0 (Azure Flexible Server)
- **ORM**: Hibernate
- **Migration**: Flyway (optional)

### DevOps
- **CI/CD**: GitHub Actions
- **Containers**: Docker
- **Registry**: Azure Container Registry
- **IaC**: Azure CLI scripts (can migrate to Terraform/Bicep)

---

**Architecture Version**: 1.0  
**Last Updated**: October 13, 2025  
**Review Date**: January 13, 2026
