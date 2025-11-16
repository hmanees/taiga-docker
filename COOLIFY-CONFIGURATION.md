# Coolify Configuration Fix

## The Problem

Coolify error: `Symfony\Component\Yaml\Yaml::parse(): Argument #1 ($input) must be of type string, null given`

This means Coolify cannot find or read the Docker Compose file.

## Solution: Configure Docker Compose Location in Coolify UI

### Step 1: Go to Application Settings

1. Login to Coolify: `https://srv1.oppwatch.com`
2. Navigate to: **Applications** → **taiga-oppwatch**
3. Click on **Configuration** or **Settings** tab

### Step 2: Set Docker Compose File Path

Look for one of these settings:
- **Docker Compose Location**
- **Compose File Path**
- **Docker Compose File**
- **Build Pack** (might need to select "Docker Compose")

Set the value to:
```
docker-compose.yaml
```

Or try the **full path**:
```
./docker-compose.yaml
```

### Step 3: Common Coolify v4.0 Settings

Check these settings in your application:

| Setting | Value |
|---------|-------|
| **Build Pack** | `docker-compose` or `dockercompose` |
| **Docker Compose Location** | `docker-compose.yaml` |
| **Base Directory** | `/` or `.` (root of repo) |
| **Install Command** | Leave empty |
| **Build Command** | Leave empty |
| **Start Command** | Leave empty (uses compose file) |

### Step 4: Alternative - Check for Custom Compose File Name

Some Coolify v4.0 setups look for specific file names:
- `docker-compose.yml` (note: `.yml` not `.yaml`)
- `docker-compose.production.yaml`
- `compose.yaml`

**Try renaming**: If Coolify still fails, rename the file:

```powershell
git mv docker-compose.yaml docker-compose.yml
git commit -m "Rename to .yml extension for Coolify"
git push origin stable
```

### Step 5: Verify Build Pack Selection

In Coolify UI, ensure the application is set to use **Docker Compose** build pack:

1. Application Settings → **Build Pack**
2. Select: **Docker Compose** (not Nixpacks, Dockerfile, or Static)
3. Save changes
4. Redeploy

## Why This Error Happens

The error `Argument #1 ($input) must be of type string, null given` occurs when:

1. ❌ Coolify can't find the compose file (wrong path)
2. ❌ Wrong build pack selected (not using Docker Compose)
3. ❌ File has wrong extension (`.yml` vs `.yaml`)
4. ❌ File is in a subdirectory but path not configured

## Current File Status

✅ File exists: `docker-compose.yaml`
✅ No variable substitutions: All `${VAR}` removed
✅ Valid YAML syntax: Checked
✅ Pushed to GitHub: Commit `70e40be`

## Test Locally First

Before redeploying in Coolify, verify the file works:

```bash
# On srv2 (or your local Docker)
docker compose -f docker-compose.yaml config

# Should output the parsed YAML without errors
```

If this command works, the file is valid and the issue is Coolify configuration.

## Coolify v4.0 Known Issues

Coolify v4.0 has some quirks:

1. **Must explicitly set Docker Compose build pack**
2. **May need `.yml` extension** (not `.yaml`)
3. **Path must be relative to repo root**
4. **Sometimes needs full path like `./docker-compose.yml`**

## Next Steps

1. ✅ Check **Build Pack** = `Docker Compose` in Coolify UI
2. ✅ Set **Docker Compose Location** = `docker-compose.yaml`
3. ✅ If still failing, rename to `docker-compose.yml` (`.yml` extension)
4. ✅ Redeploy

## Screenshots Locations (Where to Look in Coolify UI)

```
Applications
└── taiga-oppwatch
    ├── Configuration (or Settings)
    │   ├── Build Pack ← Set to "Docker Compose"
    │   ├── Docker Compose Location ← Set to "docker-compose.yaml"
    │   └── Base Directory ← Set to "/" or "."
    └── Environment Variables
        └── (Add your 13 variables here)
```

## If Still Failing

Try creating a `.coolify.yaml` configuration file:

```yaml
# .coolify.yaml
version: '1'
applications:
  - name: taiga-oppwatch
    build:
      type: dockercompose
      compose_file: docker-compose.yaml
```

Commit and push this file, then redeploy.
