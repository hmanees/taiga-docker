#!/bin/bash
# ============================================================================
# TAIGA DATABASE RESTORE SCRIPT
# ============================================================================
# Usage: ./taiga-restore-db.sh [backup-file]
# Example: ./taiga-restore-db.sh taiga-db-backup-20251116-120000.sql.gz
# WARNING: This will replace the current database!
# ============================================================================

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose-live.yaml}"
BACKUP_FILE="${1:-.}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           TAIGA DATABASE RESTORE - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Validate compose file
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}✗ Compose file not found: $COMPOSE_FILE${NC}"
    exit 1
fi

# Validate backup file
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}✗ Backup file not found: $BACKUP_FILE${NC}"
    echo "Usage: ./taiga-restore-db.sh [backup-file]"
    exit 1
fi

echo -e "${YELLOW}⚠ WARNING: This will replace the current database!${NC}"
echo "Backup file: $BACKUP_FILE"
echo ""
read -p "Continue with restore? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Restore cancelled${NC}"
    exit 0
fi

# Check if database container is running
echo ""
echo -e "${BLUE}Checking database container...${NC}"
if ! docker-compose -f "$COMPOSE_FILE" exec -T taiga-db pg_isready -U taiga_prod_user &>/dev/null; then
    echo -e "${RED}✗ Database is not accessible. Is the container running?${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Database is accessible${NC}"
echo ""

# Create temporary file if backup is compressed
TEMP_FILE=""
RESTORE_FILE="$BACKUP_FILE"

if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo -e "${BLUE}Decompressing backup...${NC}"
    TEMP_FILE=$(mktemp)
    gunzip -c "$BACKUP_FILE" > "$TEMP_FILE" || {
        echo -e "${RED}✗ Failed to decompress backup${NC}"
        rm -f "$TEMP_FILE"
        exit 1
    }
    RESTORE_FILE="$TEMP_FILE"
    echo -e "${GREEN}✓ Backup decompressed${NC}"
    echo ""
fi

# Perform restore
echo -e "${BLUE}Starting database restore...${NC}"

START_TIME=$(date +%s)

if cat "$RESTORE_FILE" | docker-compose -f "$COMPOSE_FILE" exec -T taiga-db \
   psql -U taiga_prod_user -d taiga_production > /dev/null 2>&1; then
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo -e "${GREEN}✓ Restore completed successfully${NC}"
    echo ""
    echo -e "${BLUE}Restore Details:${NC}"
    echo "  Source: $BACKUP_FILE"
    echo "  Database: taiga_production"
    echo "  Time: ${DURATION}s"
    echo ""
    
    # Verify restore
    echo -e "${BLUE}Verifying restore...${NC}"
    TABLE_COUNT=$(docker-compose -f "$COMPOSE_FILE" exec -T taiga-db \
        psql -U taiga_prod_user -d taiga_production -t -c \
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ' || echo "0")
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Database verification successful${NC}"
        echo "  Tables found: $TABLE_COUNT"
    else
        echo -e "${YELLOW}⚠ Warning: Database appears empty${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Database restore completed successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    
    # Cleanup
    [ -n "$TEMP_FILE" ] && rm -f "$TEMP_FILE"
    
else
    echo -e "${RED}✗ Restore failed${NC}"
    [ -n "$TEMP_FILE" ] && rm -f "$TEMP_FILE"
    exit 1
fi
