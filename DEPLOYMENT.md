# Taiga Deployment Guide - Coolify v4.0 (srv2)

**Date**: November 16, 2025  
**Domain**: v2.oppwatch.com  
**Server**: srv2 (108.171.195.235)  
**Coolify Control Plane**: manage.techsed.com (srv1 - 108.171.193.254)  
**Taiga Version**: 6.9.0  

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Configuration Setup](#configuration-setup)
3. [Coolify Integration](#coolify-integration)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Troubleshooting](#troubleshooting)
7. [Maintenance](#maintenance)

---

## Pre-Deployment Checklist

### Infrastructure Verification

- [ ] **srv2 Accessibility**: SSH access to `108.171.195.235` confirmed
- [ ] **Docker & Docker Compose**: Version 19.03.0+ installed on srv2
  ```bash
  docker --version
  docker-compose --version
  ```
- [ ] **Disk Space**: At least 20GB free for volumes
  ```bash
  df -h /
  ```
- [ ] **DNS Resolution**: `v2.oppwatch.com` resolves to `108.171.195.235`
  ```bash
  nslookup v2.oppwatch.com
  dig v2.oppwatch.com
  ```
- [ ] **Firewall Rules**: Ports 80, 443 open on srv2
- [ ] **Coolify Access**: Able to access `https://manage.techsed.com`

### Repository Access

- [ ] Clone/pull latest `taiga-docker` repository (stable branch)
  ```bash
  cd /path/to/taiga-docker
  git checkout stable
  git pull origin stable
  ```

---

## Configuration Setup

### Step 1: Generate Secure Credentials

Generate secure values for all sensitive configuration:

```bash
# Generate SECRET_KEY (run on any Python system)
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
# Output example: "Drmhze6EPcv0fN_81Bj-nA"

# Generate RABBITMQ_ERLANG_COOKIE
python3 -c "import secrets; print(secrets.token_hex(16))"
# Output example: "a3f4c8b9e2d1f5g6h7i8j9k0"

# Generate RABBITMQ password
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Generate POSTGRES_PASSWORD
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

### Step 2: Configure .env.production

Copy the template and edit with your values:

```bash
cd /path/to/taiga-docker

# Copy template
cp .env.production .env.production.backup

# Edit with your values
nano .env.production
```

**Critical Fields to Update**:

```properties
# Change these from defaults!
SECRET_KEY="paste-your-generated-secret-key-here"
POSTGRES_PASSWORD="paste-your-secure-postgres-password"
RABBITMQ_PASS="paste-your-secure-rabbitmq-password"
RABBITMQ_ERLANG_COOKIE="paste-your-erlang-cookie-value"

# Email Configuration (choose one method)
# Option 1: Gmail SMTP
EMAIL_BACKEND=smtp
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-specific-password
EMAIL_USE_TLS=True

# Option 2: Other SMTP Provider
EMAIL_HOST=mail.yourdomain.com
# ... adjust for your provider

# Option 3: Console (testing only)
EMAIL_BACKEND=console
```

### Step 3: Prepare Repository Structure

Ensure all necessary files are in place:

```bash
ls -la /path/to/taiga-docker/
# Expected files:
# - .env.production          ✓ (created)
# - docker-compose-live.yaml ✓ (created)
# - docker-compose.yaml      ✓ (original)
# - taiga-gateway/taiga.conf ✓ (existing)
```

---

## Coolify Integration

### Step 1: Access Coolify Dashboard

1. Navigate to: `https://manage.techsed.com`
2. Login with your Coolify credentials
3. Select **srv2** (108.171.195.235) from the server list

### Step 2: Create New Service

In Coolify Dashboard:

1. **Click**: "New" → "Docker Compose"
2. **Name**: `taiga-v2`
3. **Description**: "Taiga Project Management - v2.oppwatch.com"
4. **Server**: srv2 (108.171.195.235)
5. **Source Type**: "Git" or "Manual Upload"

### Step 3: Configure Service

**Option A: Git Repository** (Recommended)

```
Repository URL: https://github.com/hmanees/taiga-docker.git
Repository Branch: stable
Compose File: docker-compose-live.yaml
```

**Option B: Manual Upload**

Upload files directly:
- `docker-compose-live.yaml`
- `.env.production`
- `taiga-gateway/taiga.conf`

### Step 4: Set Environment Variables in Coolify

In Coolify Service Settings, add environment variables:

```
POSTGRES_USER=taiga_prod_user
POSTGRES_PASSWORD=[your-secure-password]
SECRET_KEY=[your-generated-secret-key]
TAIGA_SCHEME=https
TAIGA_DOMAIN=v2.oppwatch.com
SUBPATH=
WEBSOCKETS_SCHEME=wss
EMAIL_BACKEND=smtp
EMAIL_HOST=smtp.gmail.com
[... other EMAIL settings ...]
RABBITMQ_USER=taiga_rmq_user
RABBITMQ_PASS=[your-secure-password]
RABBITMQ_VHOST=taiga_prod
RABBITMQ_ERLANG_COOKIE=[your-cookie-value]
ATTACHMENTS_MAX_AGE=360
ENABLE_TELEMETRY=False
```

### Step 5: Configure Domain & SSL

**In Coolify Service**:

1. **Domains Tab**: 
   - Add Domain: `v2.oppwatch.com`
   - Container Port: `80` (taiga-gateway)
   - Protocol: `https` (Coolify handles SSL)

2. **Port Configuration**:
   - External: 443 (HTTPS)
   - Internal: 9000 → taiga-gateway:80
   - OR: Use Coolify's auto-routing

3. **SSL Certificate**:
   - Let's Encrypt: Enable auto-renewal
   - Expires: Auto-managed by Coolify

---

## Deployment Steps

### Step 1: Deploy from Coolify

In Coolify Dashboard:

```
1. Click service: "taiga-v2"
2. Click: "Deploy"
3. Wait for all containers to reach "healthy" status
4. Monitor logs in real-time
```

### Step 2: Manual Verification (SSH to srv2)

```bash
# Connect to srv2
ssh user@108.171.195.235

# Navigate to deployment directory
cd /opt/coolify/services/taiga-v2  # (or your Coolify service path)

# Verify Docker Compose file exists
ls -la docker-compose-live.yaml

# Verify .env file
ls -la .env.production

# Start services with Coolify or manually:
docker-compose -f docker-compose-live.yaml up -d

# Monitor startup
docker-compose -f docker-compose-live.yaml logs -f
```

### Step 3: Wait for Service Initialization

Expected startup sequence (3-5 minutes):

```
1. taiga-db: PostgreSQL initializing
2. taiga-*-rabbitmq: RabbitMQ starting
3. taiga-back: Backend API initializing
4. taiga-front: Frontend serving static files
5. taiga-events: WebSocket event server
6. taiga-gateway: Nginx routing ready
```

Check health:

```bash
docker-compose -f docker-compose-live.yaml ps

# Expected output (all HEALTHY):
CONTAINER ID   NAMES              STATUS           PORTS
...            taiga-db-prod      Up (healthy)
...            taiga-back-prod    Up (healthy)
...            taiga-front-prod   Up (healthy)
...            taiga-events-prod  Up (healthy)
...            taiga-gateway-prod Up (healthy)
```

### Step 4: Create Administrator Account

```bash
# Create superuser via Coolify exec or direct:
docker-compose -f docker-compose-live.yaml run --rm taiga-back \
  python manage.py createsuperuser

# Follow prompts:
# Username: admin
# Email: admin@v2.oppwatch.com
# Password: [strong-password]
# Repeat password: [confirm]
```

Alternatively, in Coolify UI:
- Open "Terminal" or "Exec Shell"
- Run the command above

---

## Post-Deployment Verification

### Step 1: Accessibility Check

```bash
# Test HTTP → HTTPS redirect
curl -i https://v2.oppwatch.com/
# Expected: 200 OK

# Test API endpoint
curl -i https://v2.oppwatch.com/api/v1/auth/profile/
# Expected: 401 Unauthorized (not authenticated)

# Test WebSocket connection
# Use your browser dev tools or:
# wscat -c wss://v2.oppwatch.com/events
```

### Step 2: Browser Access

1. **Open**: `https://v2.oppwatch.com`
2. **Expected**: Taiga login page appears
3. **Login**: Use admin credentials created above
4. **Verify**: Dashboard loads without errors

### Step 3: Logs Verification

```bash
# Check for errors
docker-compose -f docker-compose-live.yaml logs taiga-back | grep -i error

# Check database connectivity
docker-compose -f docker-compose-live.yaml logs taiga-db | grep -i error

# Check frontend
docker-compose -f docker-compose-live.yaml logs taiga-front | grep -i error

# Check gateway/nginx
docker-compose -f docker-compose-live.yaml logs taiga-gateway | tail -50
```

### Step 4: Functionality Tests

Within Taiga UI:

- [ ] Create a new project
- [ ] Add team members (if applicable)
- [ ] Upload a file/attachment
- [ ] Create a user story
- [ ] Test real-time updates (WebSocket)
- [ ] Test email notifications (if configured)

---

## Troubleshooting

### Issue 1: Services Not Starting

**Symptom**: Containers exit or remain in "starting" state

```bash
# Check logs
docker-compose -f docker-compose-live.yaml logs

# Common causes:
# 1. Insufficient disk space
df -h

# 2. Port conflicts (if manually deployed)
netstat -tln | grep -E ':(80|443|8000|8888|5432)'

# 3. Permission errors
docker-compose -f docker-compose-live.yaml ps

# 4. Restart services
docker-compose -f docker-compose-live.yaml restart
```

### Issue 2: Database Connection Failed

**Symptom**: `taiga-back` fails to connect to database

```bash
# Check database container
docker-compose -f docker-compose-live.yaml logs taiga-db

# Verify credentials in .env.production
grep POSTGRES /path/to/.env.production

# Test direct connection
docker-compose -f docker-compose-live.yaml exec taiga-db \
  psql -U taiga_prod_user -d taiga_production -c "SELECT 1;"

# If failed, check:
# - POSTGRES_PASSWORD is correct
# - Database initialized properly
docker-compose -f docker-compose-live.yaml restart taiga-db
```

### Issue 3: SSL Certificate Issues

**Symptom**: Browser warning about invalid certificate or mixed content

```bash
# If using Coolify SSL:
# 1. Check certificate validity in Coolify UI
# 2. Force renewal if expired:
# Navigate to Service → SSL → Renew

# If using manual cert:
# Verify cert in taiga-gateway volume:
docker-compose -f docker-compose-live.yaml exec taiga-gateway \
  ls -la /etc/nginx/certs/

# Common fix: Update X-Forwarded-Proto header
# Already configured in taiga-gateway/taiga.conf
cat taiga-gateway/taiga.conf | grep "X-Forwarded-Proto"
```

### Issue 4: WebSocket Connection Fails

**Symptom**: Real-time updates not working, "Cannot establish WebSocket"

```bash
# Verify WebSocket endpoint
curl -i https://v2.oppwatch.com/events

# Check taiga-events logs
docker-compose -f docker-compose-live.yaml logs taiga-events

# Check RabbitMQ connectivity
docker-compose -f docker-compose-live.yaml logs taiga-events-rabbitmq

# Verify WEBSOCKETS_SCHEME=wss
grep WEBSOCKETS_SCHEME /path/to/.env.production

# Test from browser console:
# new WebSocket("wss://v2.oppwatch.com/events")
# Should show: WebSocket {url: "wss://...", readyState: 0, ...}
```

### Issue 5: 502 Bad Gateway

**Symptom**: "502 Bad Gateway" error from Coolify proxy

```bash
# Check gateway logs
docker-compose -f docker-compose-live.yaml logs taiga-gateway

# Check backend health
docker-compose -f docker-compose-live.yaml exec taiga-gateway \
  curl http://taiga-back:8000/api/v1/auth/profile/

# Check if services are running
docker-compose -f docker-compose-live.yaml ps

# Restart gateway
docker-compose -f docker-compose-live.yaml restart taiga-gateway
```

### Debug Mode: Verbose Logging

Enable detailed logs:

```bash
# Follow all logs
docker-compose -f docker-compose-live.yaml logs -f

# Follow specific service
docker-compose -f docker-compose-live.yaml logs -f taiga-back

# Get last 100 lines
docker-compose -f docker-compose-live.yaml logs --tail=100 taiga-back

# Export logs to file for analysis
docker-compose -f docker-compose-live.yaml logs > taiga-deployment.log 2>&1
```

---

## Maintenance

### Regular Monitoring

```bash
# Check container status daily
docker-compose -f docker-compose-live.yaml ps

# Monitor disk usage
df -h /var/lib/docker/volumes/

# Check for errors in logs
docker-compose -f docker-compose-live.yaml logs | grep -i error | tail -20

# Monitor resource usage
docker stats
```

### Backup Strategy

**Database Backup**:

```bash
# Create backup
docker-compose -f docker-compose-live.yaml exec taiga-db \
  pg_dump -U taiga_prod_user taiga_production > taiga-db-backup-$(date +%Y%m%d).sql

# Store securely (off-server recommended)
```

**Media Backup**:

```bash
# Backup media volume
docker run --rm -v taiga-media-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/taiga-media-$(date +%Y%m%d).tar.gz -C /data .
```

### Updates

**Taiga Version Update**:

```bash
# Pull latest images
docker-compose -f docker-compose-live.yaml pull

# Restart services
docker-compose -f docker-compose-live.yaml up -d

# Monitor logs
docker-compose -f docker-compose-live.yaml logs -f

# Verify functionality
# Test login and core features
```

### Cleanup

**Remove Old Logs**:

```bash
# Docker automatically rotates json-file logs (see max-size in compose file)
# Manual cleanup:
docker-compose -f docker-compose-live.yaml logs --timestamps taiga-back > archive.log
docker-compose -f docker-compose-live.yaml logs -f --tail=0
```

---

## Security Best Practices

1. **Never commit `.env.production`** with real credentials
2. **Rotate `SECRET_KEY`** if compromised
3. **Use strong, unique passwords** for all services
4. **Keep certificates current** (Coolify handles auto-renewal)
5. **Monitor logs** for suspicious activity
6. **Backup regularly** (at least weekly)
7. **Update Docker images** regularly
8. **Restrict admin access** in Taiga UI
9. **Enable email verification** for new accounts
10. **Review Coolify firewall rules** regularly

---

## Support & References

- **Taiga Documentation**: https://docs.taiga.io/
- **Taiga API Docs**: https://docs.taiga.io/api.html
- **Coolify Docs**: https://coolify.io/docs
- **Docker Compose Reference**: https://docs.docker.com/compose/compose-file/
- **PostgreSQL Docs**: https://www.postgresql.org/docs/12/

---

## Contact & Escalation

For issues:

1. **Check logs**: Most problems are in container logs
2. **Verify configuration**: Review .env.production settings
3. **Test connectivity**: Use curl/wget to test endpoints
4. **Restart services**: Often resolves temporary issues
5. **Consult community**: https://community.taiga.io/

---

**Last Updated**: November 16, 2025  
**Created for**: v2.oppwatch.com (Coolify srv2 deployment)  
**Taiga Version**: 6.9.0
