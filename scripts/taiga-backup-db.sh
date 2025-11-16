#!/bin/bash
# ============================================================================
# TAIGA DATABASE BACKUP SCRIPT
# ============================================================================
# Usage: ./taiga-backup-db.sh [backup-dir]
# Example: ./taiga-backup-db.sh /backups/taiga
# ============================================================================

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose-live.yaml}"
BACKUP_DIR="${1:-.}"
BACKUP_NAME="taiga-db-backup-$(date +%Y%m%d-%H%M%S).sql"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           TAIGA DATABASE BACKUP - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
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

# Check if database container is running
echo "Checking database container..."
if ! docker-compose -f "$COMPOSE_FILE" exec -T taiga-db pg_isready -U taiga_prod_user &>/dev/null; then
    echo -e "${RED}✗ Database is not accessible. Is the container running?${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Database is accessible${NC}"
echo ""

# Perform backup
echo -e "${BLUE}Starting database backup...${NC}"
echo "Output: $BACKUP_PATH"
echo ""

START_TIME=$(date +%s)

if docker-compose -f "$COMPOSE_FILE" exec -T taiga-db \
   pg_dump -U taiga_prod_user -d taiga_production --verbose > "$BACKUP_PATH" 2>&1; then
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    
    echo -e "${GREEN}✓ Backup completed successfully${NC}"
    echo ""
    echo -e "${BLUE}Backup Details:${NC}"
    echo "  File: $BACKUP_PATH"
    echo "  Size: $BACKUP_SIZE"
    echo "  Time: ${DURATION}s"
    echo ""
    
    # Compress backup
    echo -e "${BLUE}Compressing backup...${NC}"
    gzip "$BACKUP_PATH" && {
        BACKUP_PATH="${BACKUP_PATH}.gz"
        COMPRESSED_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
        echo -e "${GREEN}✓ Backup compressed${NC}"
        echo "  Compressed: $BACKUP_PATH"
        echo "  Size: $COMPRESSED_SIZE"
    }
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Backup completed successfully!${NC}"
    echo -e "${GREEN}File: $BACKUP_PATH${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    
else
    echo -e "${RED}✗ Backup failed${NC}"
    rm -f "$BACKUP_PATH"
    exit 1
fi
