#!/bin/bash
# ============================================================================
# TAIGA MEDIA BACKUP SCRIPT
# ============================================================================
# Usage: ./taiga-backup-media.sh [backup-dir]
# Example: ./taiga-backup-media.sh /backups/taiga
# ============================================================================

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose-live.yaml}"
BACKUP_DIR="${1:-.}"
BACKUP_NAME="taiga-media-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           TAIGA MEDIA BACKUP - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Validate compose file
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}✗ Compose file not found: $COMPOSE_FILE${NC}"
    exit 1
fi

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}Creating backup directory: $BACKUP_DIR${NC}"
    mkdir -p "$BACKUP_DIR" || {
        echo -e "${RED}✗ Failed to create backup directory${NC}"
        exit 1
    }
fi

# Check if media volume exists
echo "Checking media volume..."
if ! docker volume inspect taiga-media-data &>/dev/null; then
    echo -e "${RED}✗ Media volume not found: taiga-media-data${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Media volume found${NC}"
echo ""

# Get volume size
VOLUME_SIZE=$(docker run --rm -v taiga-media-data:/data alpine du -sh /data 2>/dev/null | cut -f1 || echo "Unknown")
echo -e "${BLUE}Volume size: $VOLUME_SIZE${NC}"
echo ""

# Perform backup
echo -e "${BLUE}Starting media backup...${NC}"
echo "Output: $BACKUP_PATH"
echo ""

START_TIME=$(date +%s)

if docker run --rm \
   -v taiga-media-data:/data \
   -v "$BACKUP_DIR":/backup \
   alpine tar czf /backup/"$BACKUP_NAME" -C /data . 2>&1 | while read line; do
       [ -z "$line" ] || echo "$line"
   done; then
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" 2>/dev/null | cut -f1 || echo "Unknown")
    
    echo ""
    echo -e "${GREEN}✓ Backup completed successfully${NC}"
    echo ""
    echo -e "${BLUE}Backup Details:${NC}"
    echo "  File: $BACKUP_PATH"
    echo "  Size: $BACKUP_SIZE"
    echo "  Time: ${DURATION}s"
    echo ""
    
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Media backup completed successfully!${NC}"
    echo -e "${GREEN}File: $BACKUP_PATH${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    
else
    echo -e "${RED}✗ Backup failed${NC}"
    rm -f "$BACKUP_PATH"
    exit 1
fi
