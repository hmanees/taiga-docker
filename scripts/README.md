# Taiga Deployment Scripts

This directory contains utility scripts for managing Taiga deployment on Coolify srv2.

## Available Scripts

### Health & Monitoring

#### `taiga-health.sh`
Comprehensive health check of all Taiga services.

**Usage:**
```bash
./taiga-health.sh
```

**What it checks:**
- Docker container status
- Container health state
- DNS resolution
- External connectivity
- Internal connectivity (database, API, RabbitMQ)
- Resource usage (disk, memory)
- Volume status
- Recent error logs

**Output:**
- Color-coded status indicators
- Service health summary
- Issue recommendations

---

#### `taiga-logs.sh`
View and stream logs from Taiga services.

**Usage:**
```bash
# View last 20 lines from all services
./taiga-logs.sh all

# View last 50 lines from backend
./taiga-logs.sh taiga-back 50

# Stream backend logs in real-time
FOLLOW=true ./taiga-logs.sh taiga-back

# View database logs
./taiga-logs.sh taiga-db 100
```

**Parameters:**
- `service` - Service name or "all" for all services
- `tail-lines` - Number of lines to show (default: 20)
- `FOLLOW` - Set to "true" for real-time streaming

**Available Services:**
- `taiga-db-prod` - PostgreSQL database
- `taiga-back-prod` - Backend API
- `taiga-front-prod` - Frontend
- `taiga-events-prod` - WebSocket events
- `taiga-gateway-prod` - Nginx gateway

---

#### `taiga-troubleshoot.sh`
Comprehensive diagnostics and automated issue detection.

**Usage:**
```bash
./taiga-troubleshoot.sh
```

**Output:**
- System information
- Docker version check
- Disk and memory usage
- Container diagnostics
- Volume status
- Network diagnostics
- Database status
- API connectivity
- Configuration check
- Recommendations for issues

**Report:**
- Saves to `taiga-diagnostics-TIMESTAMP.txt`
- Contains full diagnostic report for troubleshooting

---

### Backup & Restore

#### `taiga-backup-db.sh`
Backup PostgreSQL database.

**Usage:**
```bash
# Backup to current directory
./taiga-backup-db.sh

# Backup to specific directory
./taiga-backup-db.sh /backups/taiga

# Backup as cron job
0 2 * * * /path/to/taiga-backup-db.sh /backups/taiga
```

**Output:**
- SQL dump file (compressed with gzip)
- Filename: `taiga-db-backup-YYYYMMDD-HHMMSS.sql.gz`
- Includes timing and size information

**Features:**
- Automatic compression
- Validation of database connectivity
- Transaction-safe backup

---

#### `taiga-restore-db.sh`
Restore PostgreSQL database from backup.

**Usage:**
```bash
./taiga-restore-db.sh taiga-db-backup-20251116-120000.sql.gz
```

**Warning:**
- Replaces current database
- Requires confirmation before proceeding
- Database must be running

**Process:**
1. Validates backup file
2. Checks database connectivity
3. Decompresses if needed
4. Restores data
5. Verifies restoration

---

#### `taiga-backup-media.sh`
Backup media files (uploads, attachments).

**Usage:**
```bash
# Backup to current directory
./taiga-backup-media.sh

# Backup to specific directory
./taiga-backup-media.sh /backups/taiga

# Backup as cron job
0 3 * * * /path/to/taiga-backup-media.sh /backups/taiga
```

**Output:**
- Compressed tar archive
- Filename: `taiga-media-backup-YYYYMMDD-HHMMSS.tar.gz`
- Size and timing information

---

#### `taiga-restore-media.sh`
Restore media files from backup.

**Usage:**
```bash
./taiga-restore-media.sh taiga-media-backup-20251116-120000.tar.gz
```

**Warning:**
- Replaces current media files
- Requires confirmation before proceeding

**Process:**
1. Validates backup file
2. Checks media volume
3. Extracts files
4. Verifies file count

---

#### `taiga-backup-full.sh`
Full backup of database, media, and configuration.

**Usage:**
```bash
# Backup to default location
./taiga-backup-full.sh

# Backup to specific directory
./taiga-backup-full.sh /backups/taiga
```

**What it backs up:**
1. Database (SQL dump, gzipped)
2. Media files (tar.gz archive)
3. Configuration (.env.production)

**Output:**
- Directory: `taiga-full-YYYYMMDD-HHMMSS/`
- Contains all three backup types
- MANIFEST.txt with file list and sizes

**Restore:**
```bash
# Restore individual components
./taiga-restore-db.sh /path/to/backup/taiga-db-backup-*.sql.gz
./taiga-restore-media.sh /path/to/backup/taiga-media-backup-*.tar.gz
```

---

## Setup

### Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### Configure Environment

Scripts use these environment variables (optional):

```bash
# Specify compose file location
export COMPOSE_FILE=/path/to/docker-compose-live.yaml

# Specify Taiga domain
export TAIGA_DOMAIN=v2.oppwatch.com

# Enable log following
export FOLLOW=true
```

### Add to PATH (Optional)

```bash
# Add scripts directory to PATH
export PATH="$PATH:/path/to/taiga-docker/scripts"

# Then use scripts from anywhere
taiga-health.sh
taiga-logs.sh all
```

---

## Common Tasks

### Daily Health Check
```bash
./taiga-health.sh
```

### Monitor Logs in Real-Time
```bash
FOLLOW=true ./taiga-logs.sh all
```

### View Backend Errors
```bash
./taiga-logs.sh taiga-back 100 | grep -i error
```

### Full Diagnostics with Report
```bash
./taiga-troubleshoot.sh
# Review taiga-diagnostics-*.txt
```

### Schedule Backups
```bash
# Add to crontab
crontab -e

# Daily backup at 2 AM
0 2 * * * cd /path/to/taiga-docker && ./scripts/taiga-backup-full.sh /backups/taiga >> /var/log/taiga-backup.log 2>&1
```

### Emergency Restore
```bash
# Restore latest backup
cd /path/to/taiga-docker

# Find latest backup
ls -t /backups/taiga/taiga-full-*/ | head -1

# Restore database
./scripts/taiga-restore-db.sh /backups/taiga/taiga-full-LATEST/taiga-db-backup-*.sql.gz

# Restore media
./scripts/taiga-restore-media.sh /backups/taiga/taiga-full-LATEST/taiga-media-backup-*.tar.gz
```

---

## Troubleshooting Scripts

### Script Not Executing

```bash
# Check execute permission
ls -la scripts/

# Add execute permission
chmod +x scripts/*.sh
```

### "Compose file not found"

```bash
# Specify correct compose file
export COMPOSE_FILE=docker-compose-live.yaml
./scripts/taiga-health.sh
```

### "Docker daemon not accessible"

```bash
# Check Docker is running
docker ps

# Check user permissions
sudo usermod -aG docker $USER
```

### Backup/Restore Permission Denied

```bash
# Run with sudo if needed
sudo ./scripts/taiga-backup-db.sh /backups

# Or fix directory permissions
chmod 755 /backups
```

---

## Performance Notes

- **Health Check**: ~30 seconds
- **Database Backup**: Varies with DB size (typically 1-5 minutes)
- **Media Backup**: Varies with media volume size
- **Restore**: Similar time as backup
- **Log Viewing**: Instantaneous to real-time

---

## Support

For issues with scripts:

1. Run `./taiga-troubleshoot.sh` for diagnostics
2. Check script logs for error messages
3. Review DEPLOYMENT.md for common issues
4. Check Taiga documentation: https://docs.taiga.io/

---

**Last Updated:** November 16, 2025  
**Version:** 1.0  
**Compatible with:** Taiga 6.9.0 + Coolify v4.0
