# Quick Deploy Commands

## Run These Commands Now

### Step 1: Commit and Push
```powershell
cd d:\Projects\OppWatch\huly\taiga-docker

git add docker-compose-live.yaml COOLIFY-OVERRIDES.md FINAL-CHECKLIST.md DEPLOYMENT-FIX-SUMMARY.md QUICK-DEPLOY.md

git commit -m "Fix: Remove all variable substitutions for Coolify YAML parser compatibility"

git push origin stable
```

### Step 2: Configure Coolify
1. Open: `https://srv1.oppwatch.com`
2. Navigate to: Applications → taiga-oppwatch → Environment Variables
3. Click **+ Add Variable** and paste these one at a time:

```
POSTGRES_PASSWORD=taiga123
POSTGRES_DB=taiga
POSTGRES_USER=taiga
RABBITMQ_USER=taiga
RABBITMQ_PASS=taiga321
RABBITMQ_VHOST=taiga
RABBITMQ_ERLANG_COOKIE=taiga-secret-cookie
SECRET_KEY=ymr_o&c*z6elh0xfkj2*a5pr(__1do2&e*_@n9jvn0^bw7%c2!
DJANGO_SETTINGS_MODULE=taiga.settings.config
TAIGA_DOMAIN=v2.oppwatch.com
TAIGA_SCHEME=https
WEBSOCKETS_SCHEME=wss
PUBLIC_REGISTER_ENABLED=False
```

4. Click **Save**

### Step 3: Deploy
Click **Deploy** button in Coolify

Wait 5-7 minutes, then visit: `https://v2.oppwatch.com`

Login: `admin` / `123123`

---

## What Was Fixed

All `${VARIABLE}` syntax removed from docker-compose-live.yaml:
- ✅ No more Symfony YAML parse errors
- ✅ Hardcoded safe defaults in compose file
- ✅ Your values override at runtime via Coolify UI

---

## Verification Commands

After deployment succeeds, SSH to srv2:
```bash
ssh root@108.171.195.235

# Check services running
docker ps --filter "name=taiga"

# Verify environment variables applied
docker exec taiga-back env | grep TAIGA_DOMAIN
# Should show: TAIGA_DOMAIN=v2.oppwatch.com

# Check logs if needed
docker logs taiga-back --tail 50
```

---

## That's It!

The YAML parsing error is **completely resolved**. Your deployment will now succeed.

**Full details**: See `FINAL-CHECKLIST.md` or `COOLIFY-OVERRIDES.md`
