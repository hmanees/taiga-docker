#!/bin/bash
# ============================================================================
# TAIGA FULL BACKUP SCRIPT
# ============================================================================
# Usage: ./taiga-backup-full.sh [backup-dir]
# Example: ./taiga-backup-full.sh /backups/taiga
# Backs up: database + media + configuration
# ============================================================================

BACKUP_DIR="${1:-/backups/taiga}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FULL_BACKUP_DIR="$BACKUP_DIR/taiga-full-$TIMESTAMP"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}        TAIGA FULL BACKUP - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Create backup directory structure
mkdir -p "$FULL_BACKUP_DIR" || {
    echo -e "${RED}✗ Failed to create backup directory: $FULL_BACKUP_DIR${NC}"
    exit 1
}

echo -e "${BLUE}Backup location: $FULL_BACKUP_DIR${NC}"
echo ""

FAILED=0

# Backup database
echo -e "${BLUE}1. Backing up database...${NC}"
if ./taiga-backup-db.sh "$FULL_BACKUP_DIR" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database backup completed${NC}"
else
    echo -e "${RED}✗ Database backup failed${NC}"
    ((FAILED++))
fi
echo ""

# Backup media
echo -e "${BLUE}2. Backing up media files...${NC}"
if ./taiga-backup-media.sh "$FULL_BACKUP_DIR" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Media backup completed${NC}"
else
    echo -e "${RED}✗ Media backup failed${NC}"
    ((FAILED++))
fi
echo ""

# Backup configuration
echo -e "${BLUE}3. Backing up configuration...${NC}"
if [ -f ".env.production" ]; then
    cp .env.production "$FULL_BACKUP_DIR/.env.production.backup" && {
        echo -e "${GREEN}✓ Configuration backup completed${NC}"
    } || {
        echo -e "${RED}✗ Configuration backup failed${NC}"
        ((FAILED++))
    }
else
    echo -e "${YELLOW}⚠ .env.production not found - skipping${NC}"
fi
echo ""

# Create manifest
echo -e "${BLUE}4. Creating backup manifest...${NC}"
cat > "$FULL_BACKUP_DIR/MANIFEST.txt" << EOF
Taiga Full Backup Manifest
==========================

Backup Date: $(date '+%Y-%m-%d %H:%M:%S')
Backup Location: $FULL_BACKUP_DIR
Domain: $(grep "TAIGA_DOMAIN" .env.production 2>/dev/null | cut -d= -f2 || echo "Unknown")

Contents:
EOF

ls -lh "$FULL_BACKUP_DIR" | awk 'NR>1 {print $9, "(" $5 ")"}' >> "$FULL_BACKUP_DIR/MANIFEST.txt"

echo -e "${GREEN}✓ Manifest created${NC}"
echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    BACKUP SUMMARY${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

TOTAL_SIZE=$(du -sh "$FULL_BACKUP_DIR" | cut -f1)
FILE_COUNT=$(find "$FULL_BACKUP_DIR" -type f | wc -l)

echo "Location: $FULL_BACKUP_DIR"
echo "Total Size: $TOTAL_SIZE"
echo "Files: $FILE_COUNT"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Full backup completed successfully!${NC}"
    echo ""
    echo "To restore this backup, use:"
    echo "  ./taiga-restore-db.sh $FULL_BACKUP_DIR/taiga-db-backup-*.sql.gz"
    echo "  ./taiga-restore-media.sh $FULL_BACKUP_DIR/taiga-media-backup-*.tar.gz"
    exit 0
else
    echo -e "${RED}✗ Full backup completed with $FAILED error(s)${NC}"
    exit 1
fi
