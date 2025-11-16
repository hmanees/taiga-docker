#!/bin/bash
# ============================================================================
# TAIGA HEALTH CHECK & MONITORING SCRIPT
# ============================================================================
# Usage: ./taiga-health.sh
# Description: Performs comprehensive health checks on Taiga deployment
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="${1:-docker-compose-live.yaml}"
TAIGA_DOMAIN="${TAIGA_DOMAIN:-v2.oppwatch.com}"
TAIGA_URL="https://${TAIGA_DOMAIN}"

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           TAIGA HEALTH CHECK - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

# Function to check command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${YELLOW}⚠ Warning: $1 not found. Skipping related checks.${NC}"
        return 1
    fi
    return 0
}

# Function to print result
print_result() {
    local status=$1
    local message=$2
    
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✓ $message${NC}"
    else
        echo -e "${RED}✗ $message${NC}"
    fi
}

echo -e "\n${BLUE}1. DOCKER SERVICES STATUS${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}✗ Compose file not found: $COMPOSE_FILE${NC}"
    exit 1
fi
print_result 0 "Compose file found: $COMPOSE_FILE"

# Get service status
docker-compose -f "$COMPOSE_FILE" ps --services > /dev/null 2>&1 || {
    echo -e "${RED}✗ Cannot access Docker Compose services${NC}"
    exit 1
}

SERVICES=("taiga-db-prod" "taiga-back-prod" "taiga-front-prod" "taiga-events-prod" "taiga-gateway-prod")

for service in "${SERVICES[@]}"; do
    STATUS=$(docker-compose -f "$COMPOSE_FILE" ps "$service" 2>/dev/null | grep -E "Up|Exited" | awk '{print $NF}' || echo "Not Found")
    
    if [[ "$STATUS" == *"Up"* ]]; then
        print_result 0 "Service running: $service"
    else
        print_result 1 "Service NOT running: $service (Status: $STATUS)"
    fi
done

echo -e "\n${BLUE}2. CONTAINER HEALTH STATUS${NC}"
echo "─────────────────────────────────────────────────────────────────"

for service in "${SERVICES[@]}"; do
    HEALTH=$(docker inspect "$service" 2>/dev/null | grep '"Health"' -A 5 | grep '"Status"' | sed 's/.*"Status": "\([^"]*\)".*/\1/' || echo "N/A")
    
    if [ "$HEALTH" = "healthy" ]; then
        print_result 0 "Container healthy: $service"
    elif [ "$HEALTH" = "starting" ]; then
        echo -e "${YELLOW}◐ Container starting: $service${NC}"
    else
        print_result 1 "Container unhealthy: $service (Status: $HEALTH)"
    fi
done

echo -e "\n${BLUE}3. NETWORK CONNECTIVITY${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Check DNS resolution
if check_command "dig" || check_command "nslookup"; then
    if dig +short "$TAIGA_DOMAIN" &>/dev/null || nslookup "$TAIGA_DOMAIN" &>/dev/null; then
        print_result 0 "DNS resolves: $TAIGA_DOMAIN"
    else
        print_result 1 "DNS resolution failed: $TAIGA_DOMAIN"
    fi
fi

# Check external connectivity
if check_command "curl"; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$TAIGA_URL/" || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        print_result 0 "HTTP endpoint accessible (Code: $HTTP_CODE)"
    else
        print_result 1 "HTTP endpoint unreachable (Code: $HTTP_CODE)"
    fi
fi

echo -e "\n${BLUE}4. INTERNAL CONNECTIVITY${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Check database
DB_RESULT=$(docker-compose -f "$COMPOSE_FILE" exec -T taiga-db pg_isready -U taiga_prod_user 2>/dev/null || echo "failed")
if [[ "$DB_RESULT" == *"accepting"* ]]; then
    print_result 0 "PostgreSQL accepting connections"
else
    print_result 1 "PostgreSQL connection issue"
fi

# Check backend API
API_RESULT=$(docker-compose -f "$COMPOSE_FILE" exec -T taiga-gateway curl -s http://taiga-back:8000/api/v1/auth/profile/ 2>/dev/null || echo "failed")
if [[ "$API_RESULT" == *"401"* ]] || [[ "$API_RESULT" == *"token"* ]]; then
    print_result 0 "Backend API responding"
else
    print_result 1 "Backend API not responding"
fi

# Check RabbitMQ
RABBITMQ_STATUS=$(docker-compose -f "$COMPOSE_FILE" exec -T taiga-events-rabbitmq rabbitmq-diagnostics ping 2>/dev/null || echo "failed")
if [[ "$RABBITMQ_STATUS" == *"pong"* ]]; then
    print_result 0 "RabbitMQ (events) responding"
else
    print_result 1 "RabbitMQ (events) not responding"
fi

echo -e "\n${BLUE}5. RESOURCE USAGE${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    print_result 0 "Disk usage healthy: ${DISK_USAGE}%"
else
    print_result 1 "Disk usage critical: ${DISK_USAGE}%"
fi

# Memory usage (Docker)
if check_command "docker"; then
    MEM_USAGE=$(docker stats --no-stream 2>/dev/null | grep -E "taiga-" | awk '{sum+=$3} END {print sum}' || echo "N/A")
    if [ "$MEM_USAGE" != "N/A" ]; then
        echo -e "${GREEN}◈ Docker memory usage: $MEM_USAGE${NC}"
    fi
fi

echo -e "\n${BLUE}6. VOLUME STATUS${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Check volumes
VOLUMES=("taiga-static-data" "taiga-media-data" "taiga-db-data" "taiga-async-rabbitmq-data" "taiga-events-rabbitmq-data")

for volume in "${VOLUMES[@]}"; do
    if docker volume inspect "$volume" &>/dev/null; then
        print_result 0 "Volume exists: $volume"
    else
        print_result 1 "Volume missing: $volume"
    fi
done

echo -e "\n${BLUE}7. LOG ANALYSIS (Last 10 errors)${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Check for recent errors
ERROR_COUNT=$(docker-compose -f "$COMPOSE_FILE" logs 2>/dev/null | grep -i "error" | wc -l)
if [ "$ERROR_COUNT" -eq 0 ]; then
    print_result 0 "No errors found in logs"
else
    print_result 1 "Found $ERROR_COUNT error(s) in logs"
    docker-compose -f "$COMPOSE_FILE" logs 2>/dev/null | grep -i "error" | tail -10 | sed 's/^/  /'
fi

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    HEALTH CHECK COMPLETE${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

# Overall status
OVERALL_HEALTH="$(docker-compose -f "$COMPOSE_FILE" ps | grep -c "Up (healthy)" || echo 0)"
TOTAL_SERVICES="${#SERVICES[@]}"

echo -e "\n${BLUE}Summary:${NC} $OVERALL_HEALTH/$TOTAL_SERVICES services healthy"

if [ "$OVERALL_HEALTH" -eq "$TOTAL_SERVICES" ]; then
    echo -e "${GREEN}✓ System appears to be operating normally${NC}\n"
    exit 0
else
    echo -e "${RED}✗ Some services need attention${NC}\n"
    exit 1
fi
