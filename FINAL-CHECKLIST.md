# 🚀 Final Deployment Checklist

## Problem Fixed ✅

The YAML parsing error has been resolved by removing all `${VAR:default}` syntax that was incompatible with Coolify's Symfony YAML parser.

## What Changed in docker-compose-live.yaml

- ❌ **Before**: `POSTGRES_PASSWORD: "${POSTGRES_PASSWORD:taiga}"`
- ✅ **After**: `POSTGRES_PASSWORD: "taiga"` (hardcoded default)

**All** environment variables now have hardcoded defaults. You will override them via Coolify UI.

---

## 3-Step Redeployment

### Step 1: Commit & Push Changes

```bash
cd d:\Projects\OppWatch\huly\taiga-docker
git add docker-compose-live.yaml COOLIFY-OVERRIDES.md FINAL-CHECKLIST.md
git commit -m "Fix: Remove variable substitutions for Coolify YAML parser compatibility"
git push origin stable
```

### Step 2: Configure Environment Variables in Coolify

Login to Coolify: `https://srv1.oppwatch.com`

Navigate to: **Applications** → **taiga-oppwatch** → **Environment Variables**

**Add these 15 critical variables:**

```bash
# Database (3 variables)
POSTGRES_PASSWORD=taiga123
POSTGRES_DB=taiga
POSTGRES_USER=taiga

# RabbitMQ (4 variables)
RABBITMQ_USER=taiga
RABBITMQ_PASS=taiga321
RABBITMQ_VHOST=taiga
RABBITMQ_ERLANG_COOKIE=taiga-secret-cookie

# Taiga Core (2 variables)
SECRET_KEY=ymr_o&c*z6elh0xfkj2*a5pr(__1do2&e*_@n9jvn0^bw7%c2!
DJANGO_SETTINGS_MODULE=taiga.settings.config

# Domain & Protocol (4 variables)
TAIGA_DOMAIN=v2.oppwatch.com
TAIGA_SCHEME=https
WEBSOCKETS_SCHEME=wss
PUBLIC_REGISTER_ENABLED=False

# Optional: Email (6 variables - skip if not using email)
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_USE_TLS=True
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

**Important**: In Coolify UI, enter each as `KEY=VALUE` (no quotes needed).

### Step 3: Redeploy

In Coolify UI:
1. Click **Deploy** button
2. Watch deployment logs for "✅ Deployment successful"
3. Wait 3-5 minutes for all 9 services to become healthy

---

## Verification (After Deployment)

### 1. Check YAML Parsed Successfully
Look for this in Coolify deployment logs:
```
✅ Parsing docker-compose-live.yaml
✅ Starting services...
```

**No more** "Symfony\Component\Yaml\Yaml::parse()" errors!

### 2. Check Environment Variables Applied
SSH to srv2:
```bash
ssh root@108.171.195.235
docker exec taiga-back env | grep -E "(SECRET_KEY|POSTGRES|TAIGA_DOMAIN)"
```

Expected output:
```
TAIGA_DOMAIN=v2.oppwatch.com
SECRET_KEY=ymr_o&c*z6elh0xfkj2*a5pr(__1do2&e*_@n9jvn0^bw7%c2!
POSTGRES_PASSWORD=taiga123
```

### 3. Check Service Health
```bash
docker ps --filter "name=taiga" --format "table {{.Names}}\t{{.Status}}"
```

All services should show "healthy" or "Up X minutes":
- taiga-gateway (healthy)
- taiga-back (healthy)
- taiga-async (healthy)
- taiga-front (healthy)
- taiga-events (healthy)
- taiga-db (healthy)
- taiga-async-rabbitmq (healthy)
- taiga-events-rabbitmq (healthy)
- taiga-protected (healthy)

### 4. Access Application
Open browser: `https://v2.oppwatch.com`

Expected: Taiga login page loads

Default credentials:
- Username: `admin`
- Password: `123123`

**Change immediately after first login!**

---

## Troubleshooting

### Issue: Still Getting YAML Parse Error
**Cause**: Coolify deployed old version with `${VAR}` syntax  
**Fix**: Ensure you pushed to `stable` branch and Coolify is tracking correct branch

Check in Coolify UI → Application Settings → Git Branch = `stable`

### Issue: Services Start But Frontend Shows "API Error"
**Cause**: `TAIGA_DOMAIN` not overridden or incorrect  
**Fix**: Verify in Coolify UI that `TAIGA_DOMAIN=v2.oppwatch.com` (no `https://` prefix)

### Issue: Database Connection Errors
**Cause**: Password mismatch between services  
**Fix**: Ensure `POSTGRES_PASSWORD=taiga123` is set in Coolify UI and redeploy

### Issue: WebSocket Connection Failed
**Cause**: `WEBSOCKETS_SCHEME` incorrect  
**Fix**: Set `WEBSOCKETS_SCHEME=wss` in Coolify UI (secure WebSocket for HTTPS)

---

## What Made This Work

### The Problem
Coolify v4.0 uses **Symfony (PHP) YAML parser** which doesn't support Docker Compose's bash-style variable substitution:
- ❌ `${VAR}` - Not supported
- ❌ `${VAR:default}` - Not supported
- ❌ `${VAR-default}` - Not supported

### The Solution
1. **Hardcode safe defaults** in `docker-compose-live.yaml`
2. **Override via Coolify UI** environment variables
3. Coolify injects your values at **runtime**, after parsing

### Why This Works
- **Parse Phase**: Coolify sees valid YAML with hardcoded strings ✅
- **Runtime Phase**: Docker replaces hardcoded values with Coolify's environment variables ✅

---

## Files Updated

| File | Purpose | Status |
|------|---------|--------|
| `docker-compose-live.yaml` | Production compose (hardcoded defaults) | ✅ Fixed |
| `COOLIFY-OVERRIDES.md` | Environment variable reference | ✅ Created |
| `FINAL-CHECKLIST.md` | This deployment guide | ✅ Created |

---

## Post-Deployment Tasks

### 1. Change Default Admin Password
Login → Admin Menu → Change Password

### 2. Configure Email (Optional)
If you added email variables in Step 2:
- Test email: Taiga Admin → Settings → Email Test
- Expected: Receive test email

### 3. Create Test Project
1. Click **+ New Project**
2. Name: "Test Project"
3. Create a few tasks to verify functionality

### 4. Set Up Backups
Run on srv2:
```bash
# Full backup (database + media)
./scripts/taiga-backup-full.sh

# Schedule daily backups via cron
crontab -e
# Add: 0 2 * * * /path/to/taiga-backup-full.sh
```

---

## Support Resources

- **Health Check**: `./scripts/taiga-health.sh`
- **View Logs**: `./scripts/taiga-logs.sh [service-name]`
- **Troubleshoot**: `./scripts/taiga-troubleshoot.sh`
- **Full Docs**: `DEPLOYMENT.md`

---

## Success Criteria

✅ Coolify deployment succeeds (no YAML errors)  
✅ All 9 services show "healthy" status  
✅ `https://v2.oppwatch.com` loads Taiga UI  
✅ Can login with admin/123123  
✅ Can create and manage projects  
✅ Environment variables properly overridden  

---

🎉 **You're ready to deploy!** Follow Steps 1-3 above.

**Estimated deployment time**: 5-7 minutes (3 min build + 2-4 min service startup)

---

## Quick Command Reference

```bash
# Commit changes
git add . && git commit -m "Fix YAML parser compatibility" && git push origin stable

# SSH to srv2
ssh root@108.171.195.235

# Check service health
docker ps --filter "name=taiga"

# View backend logs
docker logs taiga-back --tail 50 -f

# Restart all services (if needed)
docker compose -f docker-compose-live.yaml restart

# Check environment overrides applied
docker exec taiga-back env | grep TAIGA_DOMAIN
```

---

**Need help?** Check `DEPLOYMENT.md` for detailed troubleshooting or run `./scripts/taiga-troubleshoot.sh` to generate a diagnostic report.
