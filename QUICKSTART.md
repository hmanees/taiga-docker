# Taiga Coolify Deployment - Quick Start Guide

**Last Updated:** November 16, 2025  
**Environment:** Coolify v4.0 on srv2 (108.171.195.235)  
**Domain:** v2.oppwatch.com  
**Taiga Version:** 6.9.0

---

## 🚀 Quick Start (5-10 minutes)

### Prerequisites Checklist

- [ ] SSH access to srv2 (108.171.195.235)
- [ ] Docker & Docker Compose installed on srv2
- [ ] Coolify account with access to srv2
- [ ] Domain v2.oppwatch.com points to 108.171.195.235
- [ ] Ports 80/443 open on srv2

### Step 1: Prepare Configuration (2 min)

```bash
# Generate secure values
python3 -c "import secrets; print('SECRET_KEY:', secrets.token_urlsafe(50))"

# Copy template
cp .env .env.production

# Edit configuration
nano .env.production
```

**Update these values:**
```properties
TAIGA_DOMAIN=v2.oppwatch.com
TAIGA_SCHEME=https
SECRET_KEY=<your-generated-key>
POSTGRES_PASSWORD=<strong-password>
RABBITMQ_PASS=<strong-password>
```

### Step 2: Deploy via Coolify (3-5 min)

In Coolify Dashboard:

1. **New Service** → Docker Compose
2. **Repository:** taiga-docker (stable branch)
3. **Compose File:** `docker-compose-live.yaml`
4. **Server:** srv2
5. **Domain:** v2.oppwatch.com
6. **Deploy**

### Step 3: Create Admin Account (1 min)

```bash
# SSH to srv2
ssh user@108.171.195.235

# Create superuser
docker-compose -f docker-compose-live.yaml run --rm taiga-manage createsuperuser

# Follow prompts...
```

### Step 4: Access Taiga

- Open browser: `https://v2.oppwatch.com`
- Login with admin credentials
- Done! ✅

---

## 📋 Configuration Files

### Production Environment (`.env.production`)

**Location:** Repository root  
**Security:** ⚠️ Never commit with real credentials  
**Content:**
- Domain: v2.oppwatch.com
- Scheme: https (Coolify handles SSL)
- Database: PostgreSQL
- Queue: RabbitMQ (2 instances)
- Email: Configure your SMTP

**Template included** - Edit for your environment

### Docker Compose (`docker-compose-live.yaml`)

**Location:** Repository root  
**Key Features:**
- Coolify-optimized (no exposed ports)
- Health checks enabled
- Logging configured
- All services on isolated network
- Volume persistence

**Services:**
- `taiga-db-prod`: PostgreSQL 12.3
- `taiga-back-prod`: Django backend
- `taiga-front-prod`: Frontend UI
- `taiga-events-prod`: WebSocket events
- `taiga-gateway-prod`: Nginx reverse proxy
- `taiga-*-rabbitmq`: Message queues

---

## 🔧 Management Scripts

**Location:** `scripts/` directory

### Health & Monitoring

```bash
# Full health check
./scripts/taiga-health.sh

# View logs
./scripts/taiga-logs.sh all
FOLLOW=true ./scripts/taiga-logs.sh taiga-back

# Comprehensive diagnostics
./scripts/taiga-troubleshoot.sh
```

### Backup & Restore

```bash
# Backup database
./scripts/taiga-backup-db.sh /backups

# Backup media
./scripts/taiga-backup-media.sh /backups

# Full backup (both + config)
./scripts/taiga-backup-full.sh /backups

# Restore database
./scripts/taiga-restore-db.sh /backups/taiga-db-backup-*.sql.gz

# Restore media
./scripts/taiga-restore-media.sh /backups/taiga-media-backup-*.tar.gz
```

---

## 🐛 Troubleshooting

### Services Not Starting

```bash
docker-compose -f docker-compose-live.yaml logs
docker-compose -f docker-compose-live.yaml ps
```

### Cannot Access v2.oppwatch.com

```bash
# Check DNS
nslookup v2.oppwatch.com

# Check gateway
curl -v https://v2.oppwatch.com

# Check Coolify proxy logs
# In Coolify UI: Service → Logs
```

### Database Connection Error

```bash
# Check database
docker-compose -f docker-compose-live.yaml exec taiga-db pg_isready -U taiga_prod_user

# Check logs
docker-compose -f docker-compose-live.yaml logs taiga-db
```

### WebSocket Connection Failed

```bash
# Check events service
docker-compose -f docker-compose-live.yaml logs taiga-events

# Verify WebSocket URL
# Should be: wss://v2.oppwatch.com/events
```

### See More Issues

Run full diagnostics:
```bash
./scripts/taiga-troubleshoot.sh
```

Review DEPLOYMENT.md for detailed troubleshooting.

---

## 📅 Maintenance

### Daily

```bash
# Check health
./scripts/taiga-health.sh
```

### Weekly

```bash
# Full backup
./scripts/taiga-backup-full.sh /backups/taiga

# Review logs
./scripts/taiga-logs.sh all | grep -i error
```

### Monthly

- Update Docker images: `docker-compose -f docker-compose-live.yaml pull`
- Review Coolify settings
- Test restore procedure

---

## 📚 Documentation

- **This File**: Quick start reference
- **DEPLOYMENT.md**: Complete deployment guide with all details
- **scripts/README.md**: Script documentation
- **Taiga Docs**: https://docs.taiga.io/
- **Coolify Docs**: https://coolify.io/docs

---

## 🔐 Security Reminders

1. ✅ Change all default passwords in `.env.production`
2. ✅ Generate unique `SECRET_KEY`
3. ✅ Enable email verification for new accounts
4. ✅ Backup regularly (at least weekly)
5. ✅ Keep Docker images updated
6. ✅ Monitor logs for suspicious activity
7. ✅ Review Coolify firewall rules

---

## 📞 Support

If issues persist:

1. Check Taiga Community: https://community.taiga.io/
2. Review Taiga Docs: https://docs.taiga.io/
3. Run diagnostics: `./scripts/taiga-troubleshoot.sh`
4. Share report: `taiga-diagnostics-*.txt`

---

## ✨ Next Steps

After deployment:

1. **Create Projects**: Start building team projects
2. **Configure Team**: Add team members
3. **Set Permissions**: Configure roles and access
4. **Enable Features**: OAuth (GitHub/GitLab), Slack integration
5. **Setup Backups**: Schedule automated backups
6. **Monitor Performance**: Track usage and performance

---

**Deployment Version:** 1.0  
**Last Updated:** November 16, 2025  
**Ready for Production:** Yes ✅
