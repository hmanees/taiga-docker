# Coolify Environment Variable Overrides

## Critical: Override Hardcoded Values

The `docker-compose-live.yaml` file now has **hardcoded default values** to bypass Coolify's YAML parser limitations. You **MUST** override these via Coolify's UI.

## Why This Approach?

Coolify v4.0 uses a Symfony (PHP) YAML parser that doesn't support Docker Compose's `${VAR:default}` syntax. To make the file parseable, we hardcoded safe defaults. Coolify will inject your environment variables at **runtime**, overriding these defaults.

## Required Overrides (Security Critical)

Add these in Coolify UI → Your Application → Environment Variables:

### Database Configuration
```
POSTGRES_PASSWORD=taiga123
POSTGRES_DB=taiga
POSTGRES_USER=taiga
```

### RabbitMQ Configuration
```
RABBITMQ_USER=taiga
RABBITMQ_PASS=taiga321
RABBITMQ_VHOST=taiga
RABBITMQ_ERLANG_COOKIE=taiga-secret-cookie
```

### Taiga Backend
```
SECRET_KEY=ymr_o&c*z6elh0xfkj2*a5pr(__1do2&e*_@n9jvn0^bw7%c2!
DJANGO_SETTINGS_MODULE=taiga.settings.config
```

### Domain & Protocol
```
TAIGA_DOMAIN=v2.oppwatch.com
TAIGA_SCHEME=https
WEBSOCKETS_SCHEME=wss
PUBLIC_REGISTER_ENABLED=False
```

### Email Configuration (Optional)
```
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_USE_TLS=True
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
DEFAULT_FROM_EMAIL=noreply@v2.oppwatch.com
```

## How Coolify Processes This

1. **Parse Phase**: Coolify parses `docker-compose-live.yaml` with hardcoded values ✅
2. **Build Phase**: Docker builds images successfully ✅
3. **Runtime Phase**: Coolify injects your environment variables, overriding defaults ✅

## Verification Steps

After adding environment variables in Coolify:

1. **Check Backend Container**:
   ```bash
   docker exec taiga-back env | grep -E "(SECRET_KEY|POSTGRES|TAIGA_DOMAIN)"
   ```
   Should show your overridden values, not the hardcoded defaults.

2. **Check Database Connection**:
   ```bash
   docker exec taiga-db env | grep POSTGRES_PASSWORD
   ```
   Should show `taiga123`, not `taiga`.

3. **Test Frontend URL**:
   Open `https://v2.oppwatch.com` - should load Taiga UI (may take 2-3 minutes).

## Hardcoded Values in docker-compose-live.yaml

These are the **fallback defaults** if you don't override them:

| Variable | Hardcoded Default | Your Override |
|----------|-------------------|---------------|
| POSTGRES_PASSWORD | `taiga` | `taiga123` |
| POSTGRES_USER | `taiga` | `taiga` (same) |
| RABBITMQ_PASS | `taiga` | `taiga321` |
| SECRET_KEY | `change-me-to-secure-key` | `ymr_o&c*z6elh0xfkj2*a5pr(__1do2&e*_@n9jvn0^bw7%c2!` |
| TAIGA_DOMAIN | `localhost` | `v2.oppwatch.com` |
| TAIGA_SCHEME | `https` | `https` (same) |

## Security Notice

⚠️ **Never commit sensitive values to Git!** 

The hardcoded defaults are intentionally weak (like `taiga`, `change-me-to-secure-key`). Coolify's environment variable injection keeps your real credentials secure and separate from the codebase.

## Troubleshooting

### Frontend Shows "API Error"
- **Cause**: TAIGA_DOMAIN not overridden
- **Fix**: Add `TAIGA_DOMAIN=v2.oppwatch.com` in Coolify UI

### Database Connection Refused
- **Cause**: POSTGRES_PASSWORD mismatch
- **Fix**: Ensure both `taiga-db` and `taiga-back` use same `POSTGRES_PASSWORD`

### WebSocket Connection Failed
- **Cause**: WEBSOCKETS_SCHEME incorrect
- **Fix**: Set `WEBSOCKETS_SCHEME=wss` (with SSL) or `ws` (without)

### "Invalid SECRET_KEY" Error
- **Cause**: SECRET_KEY not overridden or too short
- **Fix**: Use your 50+ character secret key in Coolify UI

## Quick Reference: Coolify UI Steps

1. Login to Coolify at `https://srv1.oppwatch.com`
2. Navigate to **Applications** → **taiga-oppwatch**
3. Click **Environment Variables** tab
4. Click **+ Add Variable** for each override
5. Format: `Key=Value` (no quotes needed in Coolify UI)
6. Click **Save** and **Redeploy**

## Why Not Just Use .env File?

Coolify doesn't automatically load `.env` files from your repository. It requires explicit environment variable configuration in its UI. This approach:
- ✅ Keeps secrets out of Git
- ✅ Centralizes configuration in Coolify
- ✅ Works with Coolify's deployment pipeline
- ✅ Bypasses YAML parser limitations

## What Changed?

**Before** (Didn't work with Coolify):
```yaml
environment:
  POSTGRES_PASSWORD: "${POSTGRES_PASSWORD:taiga}"
```

**After** (Works with Coolify):
```yaml
environment:
  POSTGRES_PASSWORD: "taiga"  # Override via Coolify UI
```

Coolify will replace `"taiga"` with your UI-defined value at runtime.

## Next Steps

1. ✅ Commit this fixed `docker-compose-live.yaml` to Git
2. ✅ Push to your `stable` branch
3. ✅ Add all environment variables in Coolify UI (see "Required Overrides" above)
4. ✅ Trigger redeployment in Coolify
5. ✅ Wait 3-5 minutes for all services to start
6. ✅ Access `https://v2.oppwatch.com`

Default admin credentials:
- Username: `admin`
- Password: `123123`

Change these immediately after first login! 🔒
