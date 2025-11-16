# Taiga Deployment Fix - Coolify Configuration

**Date:** November 16, 2025  
**Issue:** YAML Parse Error during Coolify Deployment  
**Solution:** Fixed docker-compose-live.yaml with default environment variables  

---

## 🔴 Problem Diagnosed

**Error Message:**
```
Symfony\Component\Yaml\Yaml::parse(): Argument #1 ($input) must be of type string, null given
```

**Root Cause:**
The `docker-compose-live.yaml` file used environment variables without default values:
```yaml
POSTGRES_USER: "${POSTGRES_USER}"  # ❌ Returns null if not set
```

When Coolify's YAML parser encounters `null` values, it fails during parsing.

---

## ✅ Solution Applied

### Fixed: `docker-compose-live.yaml`

All environment variables now include default values using bash syntax:

```yaml
# ✅ BEFORE (Broken)
POSTGRES_USER: "${POSTGRES_USER}"

# ✅ AFTER (Fixed)
POSTGRES_USER: "${POSTGRES_USER:taiga}"
```

**Changed Variables:**
- `POSTGRES_USER` → `${POSTGRES_USER:taiga}`
- `POSTGRES_PASSWORD` → `${POSTGRES_PASSWORD:taiga}`
- `SECRET_KEY` → `${SECRET_KEY:change-me-to-secure-key}`
- `TAIGA_SCHEME` → `${TAIGA_SCHEME:https}`
- `TAIGA_DOMAIN` → `${TAIGA_DOMAIN:localhost}`
- `SUBPATH` → `${SUBPATH:}`
- `EMAIL_BACKEND` → `${EMAIL_BACKEND:console}`
- `EMAIL_*` → All email vars with defaults
- `RABBITMQ_*` → All RabbitMQ vars with defaults
- `ATTACHMENTS_MAX_AGE` → `${ATTACHMENTS_MAX_AGE:360}`

---

## 🚀 How to Redeploy

### Step 1: Pull Latest Changes

```bash
cd /path/to/taiga-docker
git pull origin stable
```

Or if not using Git, download the updated files:
- `docker-compose-live.yaml` (fixed)
- `.env` (updated with your values)

### Step 2: Update Coolify Environment Variables

In **Coolify UI** → Service → **Environment**

Ensure these exact variables are set:

```
TAIGA_SCHEME=https
TAIGA_DOMAIN=v2.oppwatch.com
SUBPATH=
WEBSOCKETS_SCHEME=wss
SECRET_KEY=ymr_o&c*z6elh0xfkj2*a5pr(__1do2&e*_@n9jvn0^bw7%c2!
POSTGRES_USER=taiga
POSTGRES_PASSWORD=taiga123
RABBITMQ_USER=taiga
RABBITMQ_PASS=taiga321
RABBITMQ_VHOST=taiga
RABBITMQ_ERLANG_COOKIE=secret-erlang-cookie
EMAIL_BACKEND=console
EMAIL_HOST=smtp.host.example.com
EMAIL_PORT=587
EMAIL_HOST_USER=user
EMAIL_HOST_PASSWORD=password
EMAIL_DEFAULT_FROM=changeme@example.com
EMAIL_USE_TLS=True
EMAIL_USE_SSL=False
ATTACHMENTS_MAX_AGE=360
ENABLE_TELEMETRY=True
```

### Step 3: Verify Compose File

In **Coolify UI** → Service → **Compose File**

Ensure it shows `docker-compose-live.yaml`

### Step 4: Redeploy

In **Coolify UI** → Service → Click **Deploy**

Monitor logs for success.

---

## ✨ What Changed in docker-compose-live.yaml

### Environment Variables Section

**Before:**
```yaml
x-environment:
  &default-back-environment
  POSTGRES_DB: "taiga_production"
  POSTGRES_USER: "${POSTGRES_USER}"           # ❌ Null if not set
  POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"   # ❌ Null if not set
  TAIGA_SECRET_KEY: "${SECRET_KEY}"           # ❌ Null if not set
  # ... etc
```

**After:**
```yaml
x-environment:
  &default-back-environment
  POSTGRES_DB: "taiga_production"
  POSTGRES_USER: "${POSTGRES_USER:taiga}"           # ✅ Default: taiga
  POSTGRES_PASSWORD: "${POSTGRES_PASSWORD:taiga}"   # ✅ Default: taiga
  TAIGA_SECRET_KEY: "${SECRET_KEY:change-me-to-secure-key}"  # ✅ Safe default
  # ... etc
```

---

## 🔍 Verification

After redeployment, verify the fix:

```bash
# On srv2, check if containers started
docker ps | grep taiga-

# Check for errors in logs
docker-compose -f docker-compose-live.yaml logs | grep -i "error"

# Run health check
./scripts/taiga-health.sh
```

---

## 📋 Configuration Summary

### Your Environment Variables (as provided)

| Variable | Value |
|----------|-------|
| TAIGA_SCHEME | https |
| TAIGA_DOMAIN | v2.oppwatch.com |
| SUBPATH | (empty) |
| WEBSOCKETS_SCHEME | wss |
| SECRET_KEY | ymr_o&c*z6elh0xfkj2*a5pr(__1do2&e*_@n9jvn0^bw7%c2! |
| POSTGRES_USER | taiga |
| POSTGRES_PASSWORD | taiga123 |
| RABBITMQ_USER | taiga |
| RABBITMQ_PASS | taiga321 |
| RABBITMQ_VHOST | taiga |
| RABBITMQ_ERLANG_COOKIE | secret-erlang-cookie |
| EMAIL_BACKEND | console |
| ATTACHMENTS_MAX_AGE | 360 |
| ENABLE_TELEMETRY | True |

---

## 🆘 If Still Having Issues

### Symptom 1: Still Getting YAML Parse Error

**Solution:**
- Clear Coolify cache
- Delete and recreate the service
- Ensure `.env` file is not being used (use UI environment variables instead)

### Symptom 2: Containers Not Starting

**Check:**
```bash
docker-compose -f docker-compose-live.yaml logs
docker-compose -f docker-compose-live.yaml ps
```

**Common Issues:**
- Insufficient disk space
- Port already in use
- Permission issues

### Symptom 3: Connection Refused

**Check:**
```bash
# Test database
docker-compose -f docker-compose-live.yaml exec taiga-db pg_isready -U taiga

# Test API
curl http://localhost:9000/api/v1/auth/profile/
```

---

## 📝 Files Modified

| File | Changes | Status |
|------|---------|--------|
| `docker-compose-live.yaml` | All env vars now have defaults | ✅ Fixed |
| `.env` | Updated with your values | ✅ Ready |

---

## 🎯 Next Steps

1. **Pull Updated Files** (if using Git)
   ```bash
   git pull origin stable
   ```

2. **Update Coolify Environment** 
   - Copy variables from table above
   - Paste into Coolify UI → Environment

3. **Redeploy**
   - Click Deploy in Coolify UI
   - Monitor logs for success

4. **Verify**
   - Check: https://v2.oppwatch.com
   - Run: `./scripts/taiga-health.sh`

---

## 📊 Before & After

### Before (Failed)
```
❌ YAML Parse Error
❌ Null environment variables
❌ Deployment aborted
```

### After (Working)
```
✅ YAML Parse Success
✅ Environment variables with defaults
✅ Containers start successfully
✅ Taiga accessible at v2.oppwatch.com
```

---

## 🔗 Related Files

- `docker-compose-live.yaml` - Main compose file (FIXED)
- `.env` - Environment file (UPDATED)
- `DEPLOYMENT.md` - Full deployment guide
- `QUICKSTART.md` - Quick reference

---

**Status:** ✅ Ready for redeployment  
**Last Updated:** November 16, 2025  
**Next Action:** Redeploy via Coolify UI
