# Taiga Coolify Deployment - Complete Package Summary

**Created:** November 16, 2025  
**For:** v2.oppwatch.com (Coolify srv2 - 108.171.195.235)  
**Taiga Version:** 6.9.0  
**Status:** ✅ Ready for Production Deployment

---

## 📦 Package Contents

### Core Configuration Files

#### 1. `.env.production`
- **Purpose:** Production environment configuration
- **Key Settings:**
  - Domain: `v2.oppwatch.com`
  - Scheme: `https` (Coolify proxy handles SSL)
  - WebSockets: `wss` (secure)
  - Database: PostgreSQL credentials
  - RabbitMQ: Message queue settings
  - Email: SMTP configuration
- **Security:** ⚠️ Template provided - customize with secure values
- **Usage:** Copy as `.env` on srv2, update credentials

#### 2. `docker-compose-live.yaml`
- **Purpose:** Production-grade Docker Compose configuration for Coolify
- **Optimizations:**
  - ✅ No exposed host ports (Coolify proxy routes traffic)
  - ✅ Health checks for all services
  - ✅ Logging configured (json-file with rotation)
  - ✅ Isolated network (taiga-network with specific subnet)
  - ✅ Volume persistence for data
  - ✅ Restart policy: `unless-stopped`
- **Services:** 9 services (database, backend, frontend, events, queue, gateway, etc.)
- **Usage:** Main deployment file for Coolify integration

#### 3. `DEPLOYMENT.md`
- **Purpose:** Complete deployment guide with step-by-step instructions
- **Sections:**
  - Pre-deployment checklist
  - Configuration setup (credential generation)
  - Coolify integration (service creation, domain setup)
  - Deployment steps (startup sequence)
  - Post-deployment verification
  - Troubleshooting guide
  - Maintenance procedures
- **Usage:** Reference during and after deployment

#### 4. `QUICKSTART.md`
- **Purpose:** 5-10 minute quick reference guide
- **Contents:**
  - Prerequisites checklist
  - 4-step deployment process
  - Configuration file overview
  - Script reference
  - Common troubleshooting
  - Maintenance schedule
- **Usage:** Quick reference for fast deployment

### Management & Utility Scripts

**Location:** `scripts/` directory

#### Health & Monitoring Scripts

##### `taiga-health.sh`
- **Purpose:** Real-time health check of all services
- **Checks:**
  - Container status and health
  - DNS resolution
  - External connectivity
  - Internal connectivity (DB, API, RabbitMQ)
  - Resource usage (disk, memory)
  - Volume status
  - Recent error logs
- **Output:** Color-coded status report
- **Runtime:** ~30 seconds
- **Usage:** `./scripts/taiga-health.sh`

##### `taiga-logs.sh`
- **Purpose:** View and stream container logs
- **Features:**
  - View last N lines from services
  - Real-time log streaming
  - Filter by service
  - Color-coded output
- **Usage:**
  - `./scripts/taiga-logs.sh all 50` (view)
  - `FOLLOW=true ./scripts/taiga-logs.sh taiga-back` (stream)

##### `taiga-troubleshoot.sh`
- **Purpose:** Comprehensive system diagnostics
- **Generates:** `taiga-diagnostics-TIMESTAMP.txt` report
- **Checks:**
  - System information
  - Docker daemon status
  - Container diagnostics
  - Network connectivity
  - Database status
  - API connectivity
  - Configuration validation
  - Issue recommendations
- **Usage:** `./scripts/taiga-troubleshoot.sh`

#### Backup & Restore Scripts

##### `taiga-backup-db.sh`
- **Purpose:** Backup PostgreSQL database
- **Output:** `taiga-db-backup-YYYYMMDD-HHMMSS.sql.gz`
- **Features:** Auto-compression, validation, transaction-safe
- **Usage:** `./scripts/taiga-backup-db.sh /backups`
- **Cron:** `0 2 * * * /path/to/taiga-backup-db.sh /backups`

##### `taiga-restore-db.sh`
- **Purpose:** Restore PostgreSQL from backup
- **Safety:** Requires confirmation before proceeding
- **Usage:** `./scripts/taiga-restore-db.sh backup.sql.gz`
- **Features:** Decompression, verification, error handling

##### `taiga-backup-media.sh`
- **Purpose:** Backup media files and uploads
- **Output:** `taiga-media-backup-YYYYMMDD-HHMMSS.tar.gz`
- **Usage:** `./scripts/taiga-backup-media.sh /backups`
- **Features:** Volume-based backup, compression

##### `taiga-restore-media.sh`
- **Purpose:** Restore media files from backup
- **Safety:** Requires confirmation
- **Usage:** `./scripts/taiga-restore-media.sh backup.tar.gz`
- **Verification:** File count validation

##### `taiga-backup-full.sh`
- **Purpose:** Full system backup (database + media + config)
- **Output:** Timestamped directory with all backups
- **Includes:** MANIFEST.txt with file listing
- **Usage:** `./scripts/taiga-backup-full.sh /backups`

#### Script Documentation

##### `scripts/README.md`
- **Purpose:** Complete script reference documentation
- **Contents:**
  - Detailed description of each script
  - Usage examples
  - Parameter reference
  - Common tasks
  - Troubleshooting
  - Performance notes

---

## 🚀 Deployment Workflow

### Phase 1: Preparation (15 minutes)

1. **Generate Credentials**
   ```bash
   python3 -c "import secrets; print(secrets.token_urlsafe(50))"
   ```

2. **Configure `.env.production`**
   - Set domain: `v2.oppwatch.com`
   - Set scheme: `https`
   - Set all credentials (unique, strong values)
   - Configure email backend

3. **Prepare Repository**
   - Clone/pull stable branch
   - Verify all files present
   - Make scripts executable: `chmod +x scripts/*.sh`

### Phase 2: Coolify Setup (10-15 minutes)

1. **Access Coolify Dashboard**
   - Navigate to: `https://manage.techsed.com`
   - Select srv2 (108.171.195.235)

2. **Create New Service**
   - Type: Docker Compose
   - Source: Git repository or manual upload
   - Compose File: `docker-compose-live.yaml`

3. **Configure Domain**
   - Domain: `v2.oppwatch.com`
   - Port: 80 (taiga-gateway internal)
   - SSL: Let's Encrypt (auto-enabled)

4. **Deploy**
   - Click "Deploy"
   - Monitor logs in real-time
   - Wait for all containers to reach "healthy"

### Phase 3: Initialization (5 minutes)

1. **Create Admin Account**
   ```bash
   docker-compose -f docker-compose-live.yaml run --rm taiga-manage createsuperuser
   ```

2. **Verify Access**
   - Open browser: `https://v2.oppwatch.com`
   - Login with admin account
   - Check dashboard loads

3. **Run Health Check**
   ```bash
   ./scripts/taiga-health.sh
   ```

### Phase 4: Post-Deployment (10 minutes)

1. **Run Diagnostics**
   ```bash
   ./scripts/taiga-troubleshoot.sh
   ```

2. **Test Features**
   - Create project
   - Upload file
   - Test real-time updates
   - Test email notifications

3. **Schedule Backups**
   - Add to crontab
   - Test backup procedure

---

## 📋 Quick Reference

### Essential Commands

```bash
# Health check
./scripts/taiga-health.sh

# View logs
FOLLOW=true ./scripts/taiga-logs.sh all

# Diagnostics
./scripts/taiga-troubleshoot.sh

# Backup
./scripts/taiga-backup-full.sh /backups

# Restart services
docker-compose -f docker-compose-live.yaml restart

# Update images
docker-compose -f docker-compose-live.yaml pull && docker-compose -f docker-compose-live.yaml up -d
```

### Important Files

| File | Purpose | Location |
|------|---------|----------|
| `.env.production` | Configuration | Root |
| `docker-compose-live.yaml` | Services | Root |
| `DEPLOYMENT.md` | Full guide | Root |
| `QUICKSTART.md` | Quick ref | Root |
| `taiga-gateway/taiga.conf` | Nginx config | taiga-gateway/ |
| Scripts | Utilities | scripts/ |

### Service Information

| Service | Port | Purpose |
|---------|------|---------|
| taiga-gateway | 80 (internal) | Nginx reverse proxy |
| taiga-back | 8000 | Django API |
| taiga-front | 80 | Frontend UI |
| taiga-events | 8888 | WebSocket events |
| taiga-db | 5432 | PostgreSQL |
| RabbitMQ x2 | 5672 | Message queues |

---

## ✅ Deployment Checklist

### Before Deployment

- [ ] All credentials generated and secure
- [ ] `.env.production` configured correctly
- [ ] Domain `v2.oppwatch.com` resolves to `108.171.195.235`
- [ ] Ports 80/443 open on srv2
- [ ] Docker and Compose installed on srv2
- [ ] Coolify account with srv2 access
- [ ] Scripts made executable

### During Deployment

- [ ] Services deployed via Coolify
- [ ] All containers reach "healthy" status
- [ ] Admin account created
- [ ] Website accessible at `https://v2.oppwatch.com`
- [ ] Health check passes

### After Deployment

- [ ] Login works with admin account
- [ ] Create project succeeds
- [ ] File upload works
- [ ] Real-time updates functional
- [ ] Email notifications working (if configured)
- [ ] Backups scheduled
- [ ] Monitoring in place

---

## 🔐 Security Checklist

- [ ] All default passwords changed
- [ ] Unique SECRET_KEY generated
- [ ] HTTPS enforced (Coolify proxy)
- [ ] Email configured for notifications
- [ ] Regular backups scheduled
- [ ] Database credentials secure
- [ ] RabbitMQ credentials secure
- [ ] Coolify firewall rules reviewed
- [ ] Admin account has strong password
- [ ] Public registration disabled initially

---

## 📞 Support & Resources

### Documentation Files Included

1. **DEPLOYMENT.md** - Comprehensive deployment guide
2. **QUICKSTART.md** - 5-minute quick start
3. **scripts/README.md** - Script documentation
4. **This file** - Package overview

### External Resources

- **Taiga Documentation:** https://docs.taiga.io/
- **Taiga API Reference:** https://docs.taiga.io/api.html
- **Taiga Community:** https://community.taiga.io/
- **Coolify Documentation:** https://coolify.io/docs
- **Docker Documentation:** https://docs.docker.com/

### Troubleshooting

1. Run `./scripts/taiga-troubleshoot.sh` for diagnostics
2. Review DEPLOYMENT.md troubleshooting section
3. Check container logs: `FOLLOW=true ./scripts/taiga-logs.sh all`
4. Search Taiga community for similar issues

---

## 🎯 Next Steps

### Immediate (After Deployment)

1. Create team projects
2. Invite team members
3. Configure team roles
4. Setup email notifications

### Short-term (First Week)

1. Configure OAuth (GitHub/GitLab)
2. Enable Slack integration
3. Test all features
4. Review user feedback

### Long-term (Ongoing)

1. Monitor performance
2. Plan capacity upgrades
3. Schedule maintenance windows
4. Keep images updated
5. Review security settings

---

## 📈 Performance Expectations

| Metric | Typical Value |
|--------|---------------|
| Startup Time | 3-5 minutes |
| Health Check | ~30 seconds |
| Login Response | <1 second |
| Project Creation | <3 seconds |
| File Upload (10MB) | 5-10 seconds |
| WebSocket Connection | <500ms |

---

## 🔄 Maintenance Schedule

### Daily
- Monitor health: `./scripts/taiga-health.sh`

### Weekly
- Full backup: `./scripts/taiga-backup-full.sh`
- Review errors: `./scripts/taiga-logs.sh all | grep error`

### Monthly
- Update images: `docker-compose -f docker-compose-live.yaml pull`
- Review Coolify settings
- Test restore procedure

### Quarterly
- Capacity review
- Security audit
- Disaster recovery drill

---

## 📝 Version Information

- **Package Version:** 1.0
- **Taiga Version:** 6.9.0
- **Coolify Version:** 4.0
- **Docker Compose:** 3.5
- **PostgreSQL:** 12.3
- **Nginx:** 1.19-alpine
- **Created:** November 16, 2025

---

## ✨ Summary

This complete deployment package includes:

✅ Production-grade configuration  
✅ Coolify-optimized Docker Compose  
✅ Comprehensive deployment guide  
✅ Quick-start reference  
✅ Health monitoring scripts  
✅ Backup & restore procedures  
✅ Troubleshooting diagnostics  
✅ Security best practices  
✅ Maintenance procedures  

**Ready for production deployment on v2.oppwatch.com (srv2)**

---

**Questions?** Review DEPLOYMENT.md or visit https://community.taiga.io/

**Last Updated:** November 16, 2025  
**Status:** ✅ Production Ready
