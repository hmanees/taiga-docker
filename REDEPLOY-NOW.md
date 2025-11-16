# ✅ Immediate Action Guide - Fix & Redeploy

**Current Status:** Deployment failed due to YAML parsing error  
**Root Cause:** Environment variables had no default values  
**Fix Applied:** docker-compose-live.yaml updated with defaults  
**Next Step:** Redeploy via Coolify

---

## 🎯 3-Step Redeploy Process

### STEP 1: Update Coolify Environment Variables (2 minutes)

Navigate to **Coolify UI** → Your Service → **Environment Variables**

**Copy-paste these EXACTLY as shown:**

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

✅ **Click Save**

---

### STEP 2: Verify Compose File (1 minute)

Navigate to **Coolify UI** → Your Service → **Compose File**

**Ensure it shows:**
```
docker-compose-live.yaml
```

If it doesn't, update to point to this file.

✅ **No changes needed if already set**

---

### STEP 3: Redeploy (5-10 minutes)

Navigate to **Coolify UI** → Your Service → **Deploy**

**Click the Deploy button**

Monitor the logs:
- ✅ Should see: "Pulling & building required images"
- ✅ Should see: "Container started successfully"
- ❌ Should NOT see: "YAML Parse Error"

---

## 🔍 Verify Success

After deployment completes, check:

### Check 1: Website Accessibility

Open browser: `https://v2.oppwatch.com`

Expected: Taiga login page appears

### Check 2: Container Status

On srv2, run:
```bash
docker ps | grep taiga-
```

Expected: All containers show "healthy" status

### Check 3: Logs Check

On srv2, run:
```bash
./scripts/taiga-health.sh
```

Expected: Green checkmarks for all services

---

## ⚙️ What Was Fixed

### The Problem

Your Docker Compose had environment variables like:
```yaml
POSTGRES_USER: "${POSTGRES_USER}"  ❌ Fails if not set
```

### The Solution

Now they have defaults:
```yaml
POSTGRES_USER: "${POSTGRES_USER:taiga}"  ✅ Uses "taiga" if not set
```

This prevents YAML parsing errors when variables aren't provided.

---

## 📋 Quick Reference

| Item | Value |
|------|-------|
| **Domain** | v2.oppwatch.com |
| **Server** | srv2 (108.171.195.235) |
| **Compose File** | docker-compose-live.yaml |
| **Deploy Time** | ~10 minutes |
| **Expected Status** | All containers healthy |

---

## 🆘 Troubleshooting

### If You Get "YAML Parse Error" Again

1. **Clear Coolify cache:**
   - Coolify UI → Settings → Clear Cache

2. **Delete and recreate service:**
   - Delete the service
   - Create new service
   - Use docker-compose-live.yaml
   - Add all environment variables

3. **Verify file exists:**
   ```bash
   ls -la /path/to/docker-compose-live.yaml
   ```

### If Containers Don't Start

1. **Check logs:**
   ```bash
   docker-compose -f docker-compose-live.yaml logs
   ```

2. **Check disk space:**
   ```bash
   df -h /
   ```

3. **Restart:**
   ```bash
   docker-compose -f docker-compose-live.yaml restart
   ```

---

## ✅ Success Checklist

After deployment:

- [ ] Website loads at https://v2.oppwatch.com
- [ ] All containers show "healthy"
- [ ] No YAML parse errors in logs
- [ ] Can login with admin account
- [ ] Health check script passes

---

## 📞 Files to Reference

| File | Purpose |
|------|---------|
| `docker-compose-live.yaml` | Main deployment file (FIXED) |
| `.env` | Environment variables (UPDATED) |
| `DEPLOYMENT-FIX.md` | Detailed explanation of the fix |
| `scripts/taiga-health.sh` | Verification script |

---

## 🚀 You're Ready!

**Current Status:** ✅ Ready to redeploy

**Next Action:** Follow the 3 steps above

**Expected Result:** Taiga running at v2.oppwatch.com

**Questions?** Check DEPLOYMENT-FIX.md for detailed explanation

---

**Time to Deploy:** ~10-15 minutes  
**Difficulty:** Easy (3 simple steps)  
**Status:** Ready to go!
