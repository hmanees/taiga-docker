#!/bin/bash
# ============================================================================
# TAIGA MEDIA RESTORE SCRIPT
# ============================================================================
# Usage: ./taiga-restore-media.sh [backup-file]
# Example: ./taiga-restore-media.sh taiga-media-backup-20251116-120000.tar.gz
# WARNING: This will replace the current media files!
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
echo -e "${BLUE}           TAIGA MEDIA RESTORE - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
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
    echo "Usage: ./taiga-restore-media.sh [backup-file]"
    exit 1
fi

echo -e "${YELLOW}⚠ WARNING: This will replace the current media files!${NC}"
echo "Backup file: $BACKUP_FILE"
echo ""
read -p "Continue with restore? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Restore cancelled${NC}"
    exit 0
fi

# Check if media volume exists
echo ""
echo -e "${BLUE}Checking media volume...${NC}"
if ! docker volume inspect taiga-media-data &>/dev/null; then
    echo -e "${RED}✗ Media volume not found: taiga-media-data${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Media volume found${NC}"
echo ""

# Perform restore
echo -e "${BLUE}Starting media restore...${NC}"

START_TIME=$(date +%s)

if docker run --rm \
   -v taiga-media-data:/data \
   -v "$(cd "$(dirname "$BACKUP_FILE")" && pwd)":/backup \
   alpine tar xzf /backup/"$(basename "$BACKUP_FILE")" -C /data 2>&1; then
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    echo -e "${GREEN}✓ Restore completed successfully${NC}"
    echo ""
    echo -e "${BLUE}Restore Details:${NC}"
    echo "  Source: $BACKUP_FILE"
    echo "  Volume: taiga-media-data"
    echo "  Time: ${DURATION}s"
    echo ""
    
    # Verify restore
    echo -e "${BLUE}Verifying restore...${NC}"
    FILE_COUNT=$(docker run --rm -v taiga-media-data:/data alpine find /data -type f | wc -l)
    
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Media verification successful${NC}"
        echo "  Files found: $FILE_COUNT"
    else
        echo -e "${YELLOW}⚠ Warning: Media volume appears empty${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Media restore completed successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    
else
    echo -e "${RED}✗ Restore failed${NC}"
    exit 1
fi
