#!/bin/bash
# ============================================================================
# TAIGA LOGS MONITORING SCRIPT
# ============================================================================
# Usage: ./taiga-logs.sh [service] [tail-lines]
# Example: ./taiga-logs.sh taiga-back 50
# Services: taiga-db, taiga-back, taiga-front, taiga-events, taiga-gateway
# ============================================================================

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose-live.yaml}"
SERVICE="${1:-all}"
TAIL_LINES="${2:-20}"
FOLLOW="${FOLLOW:-false}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           TAIGA LOGS VIEWER - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

# Validate compose file
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}✗ Compose file not found: $COMPOSE_FILE${NC}"
    exit 1
fi

# Display usage
if [ "$SERVICE" = "help" ] || [ "$SERVICE" = "-h" ]; then
    echo -e "\n${GREEN}Usage:${NC}"
    echo "  ./taiga-logs.sh [service] [tail-lines] [follow]"
    echo ""
    echo -e "${GREEN}Options:${NC}"
    echo "  service      - Service name or 'all' for all services"
    echo "  tail-lines   - Number of lines to show (default: 20)"
    echo "  follow       - Set FOLLOW=true to stream logs (Ctrl+C to exit)"
    echo ""
    echo -e "${GREEN}Services:${NC}"
    docker-compose -f "$COMPOSE_FILE" ps --services 2>/dev/null | sed 's/^/  - /'
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  ./taiga-logs.sh all 50              # Show last 50 lines from all services"
    echo "  FOLLOW=true ./taiga-logs.sh taiga-back  # Stream backend logs"
    echo "  ./taiga-logs.sh taiga-db 100        # Show database logs"
    exit 0
fi

# Function to display logs
display_logs() {
    local svc=$1
    local lines=$2
    
    echo -e "\n${CYAN}▶ Logs from: $svc${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    
    if [ "$FOLLOW" = "true" ]; then
        docker-compose -f "$COMPOSE_FILE" logs -f --tail="$lines" "$svc" 2>/dev/null || {
            echo -e "${RED}✗ Error: Cannot fetch logs from $svc${NC}"
            return 1
        }
    else
        docker-compose -f "$COMPOSE_FILE" logs --tail="$lines" "$svc" 2>/dev/null || {
            echo -e "${RED}✗ Error: Cannot fetch logs from $svc${NC}"
            return 1
        }
    fi
}

# Get all services
get_services() {
    docker-compose -f "$COMPOSE_FILE" ps --services 2>/dev/null | grep -E "taiga-"
}

# Display logs based on service parameter
if [ "$SERVICE" = "all" ]; then
    echo -e "\n${GREEN}Displaying logs from all services...${NC}"
    
    for svc in $(get_services); do
        display_logs "$svc" "$TAIL_LINES" || true
    done
    
    if [ "$FOLLOW" != "true" ]; then
        echo -e "\n${YELLOW}Tip: Use 'FOLLOW=true ./taiga-logs.sh all' to stream all logs${NC}"
    fi
else
    # Verify service exists
    if get_services | grep -q "$SERVICE"; then
        display_logs "$SERVICE" "$TAIL_LINES"
        
        if [ "$FOLLOW" != "true" ]; then
            echo -e "\n${YELLOW}Tip: Use 'FOLLOW=true ./taiga-logs.sh $SERVICE' to stream logs${NC}"
        fi
    else
        echo -e "${RED}✗ Service not found: $SERVICE${NC}\n"
        echo -e "${GREEN}Available services:${NC}"
        get_services | sed 's/^/  - /'
        exit 1
    fi
fi

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
