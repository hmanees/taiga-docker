#!/bin/bash
# ============================================================================
# TAIGA TROUBLESHOOTING & DIAGNOSTICS SCRIPT
# ============================================================================
# Usage: ./taiga-troubleshoot.sh
# Description: Comprehensive diagnostics and automated issue detection
# ============================================================================

set -e

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose-live.yaml}"
TAIGA_DOMAIN="${TAIGA_DOMAIN:-v2.oppwatch.com}"
TAIGA_URL="https://${TAIGA_DOMAIN}"
REPORT_FILE="taiga-diagnostics-$(date +%Y%m%d-%H%M%S).txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Initialize report
exec 1> >(tee -a "$REPORT_FILE")
exec 2>&1

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           TAIGA DIAGNOSTICS - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Report saved to: $REPORT_FILE"
echo ""

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}✗ Compose file not found: $COMPOSE_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}1. SYSTEM INFORMATION${NC}"
echo "─────────────────────────────────────────────────────────────────"
echo "Hostname: $(hostname)"
echo "OS: $(uname -s)"
echo "Kernel: $(uname -r)"
echo "Date: $(date)"
echo ""

echo -e "${BLUE}2. DOCKER VERSION${NC}"
echo "─────────────────────────────────────────────────────────────────"
docker --version || echo "Docker not found"
docker-compose --version || echo "Docker Compose not found"
echo ""

echo -e "${BLUE}3. DISK SPACE${NC}"
echo "─────────────────────────────────────────────────────────────────"
df -h / | tail -1 | awk '{print "Disk usage: " $5 ", Free: " $4}'
echo ""

echo -e "${BLUE}4. MEMORY USAGE${NC}"
echo "─────────────────────────────────────────────────────────────────"
free -h | head -2 || echo "Memory info not available"
echo ""

echo -e "${BLUE}5. DOCKER DAEMON STATUS${NC}"
echo "─────────────────────────────────────────────────────────────────"
if docker ps &>/dev/null; then
    echo -e "${GREEN}✓ Docker daemon is running${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "taiga-" || echo "No Taiga containers running"
else
    echo -e "${RED}✗ Docker daemon not accessible${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}6. CONTAINER DIAGNOSTIC${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Detailed container inspection
for container in taiga-db-prod taiga-back-prod taiga-front-prod taiga-events-prod taiga-gateway-prod; do
    if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
        STATUS=$(docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | grep "$container" | awk '{$1=""; print $0}' || echo "Unknown")
        STATE=$(docker inspect "$container" --format='{{.State.Status}}' 2>/dev/null || echo "Unknown")
        RESTARTS=$(docker inspect "$container" --format='{{.RestartCount}}' 2>/dev/null || echo "0")
        
        echo "$container:"
        echo "  Status: $STATUS"
        echo "  State: $STATE"
        echo "  Restarts: $RESTARTS"
        
        # Check for recent errors
        ERROR_COUNT=$(docker logs "$container" 2>/dev/null | grep -i "error\|fatal\|exception" | wc -l)
        if [ "$ERROR_COUNT" -gt 0 ]; then
            echo -e "  ${RED}Errors in logs: $ERROR_COUNT${NC}"
        fi
    else
        echo -e "${RED}✗ Container not found: $container${NC}"
    fi
done
echo ""

echo -e "${BLUE}7. VOLUME STATUS${NC}"
echo "─────────────────────────────────────────────────────────────────"
docker volume ls --filter "name=taiga-" --format "table {{.Name}}\t{{.Size}}" || echo "Cannot list volumes"
echo ""

echo -e "${BLUE}8. NETWORK DIAGNOSTIC${NC}"
echo "─────────────────────────────────────────────────────────────────"
docker network inspect taiga-network 2>/dev/null | grep -E "Name|Subnet|Gateway" || echo "Network not found"
echo ""

echo -e "${BLUE}9. CONNECTIVITY TEST${NC}"
echo "─────────────────────────────────────────────────────────────────"

# DNS test
echo -n "DNS Resolution ($TAIGA_DOMAIN): "
if dig +short "$TAIGA_DOMAIN" &>/dev/null; then
    echo -e "${GREEN}✓ Success${NC}"
    dig +short "$TAIGA_DOMAIN"
else
    echo -e "${RED}✗ Failed${NC}"
fi
echo ""

# HTTP test
echo -n "HTTP Connectivity: "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$TAIGA_URL/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" != "000" ]; then
    echo -e "${GREEN}✓ Response Code: $HTTP_CODE${NC}"
else
    echo -e "${RED}✗ Cannot connect${NC}"
fi
echo ""

# Internal gateway test
echo -n "Gateway (internal): "
GATEWAY_TEST=$(docker-compose -f "$COMPOSE_FILE" exec -T taiga-gateway curl -s http://localhost/ 2>/dev/null || echo "failed")
if [ "$GATEWAY_TEST" != "failed" ]; then
    echo -e "${GREEN}✓ Responding${NC}"
else
    echo -e "${RED}✗ Not responding${NC}"
fi
echo ""

echo -e "${BLUE}10. DATABASE DIAGNOSTIC${NC}"
echo "─────────────────────────────────────────────────────────────────"

echo -n "PostgreSQL Status: "
DB_CHECK=$(docker-compose -f "$COMPOSE_FILE" exec -T taiga-db pg_isready -U taiga_prod_user 2>/dev/null || echo "failed")
if [[ "$DB_CHECK" == *"accepting"* ]]; then
    echo -e "${GREEN}✓ Accepting connections${NC}"
else
    echo -e "${RED}✗ Not responding${NC}"
fi

echo -n "Database Size: "
DB_SIZE=$(docker-compose -f "$COMPOSE_FILE" exec -T taiga-db psql -U taiga_prod_user -d taiga_production -t -c "SELECT pg_size_pretty(pg_database_size('taiga_production'));" 2>/dev/null || echo "Unknown")
echo "$DB_SIZE"
echo ""

echo -e "${BLUE}11. RABBITMQ DIAGNOSTIC${NC}"
echo "─────────────────────────────────────────────────────────────────"

echo -n "RabbitMQ (Events): "
RMQ_CHECK=$(docker-compose -f "$COMPOSE_FILE" exec -T taiga-events-rabbitmq rabbitmq-diagnostics ping 2>/dev/null || echo "failed")
if [[ "$RMQ_CHECK" == *"pong"* ]]; then
    echo -e "${GREEN}✓ Responding${NC}"
else
    echo -e "${RED}✗ Not responding${NC}"
fi

echo -n "RabbitMQ (Async): "
RMQ_ASYNC=$(docker-compose -f "$COMPOSE_FILE" exec -T taiga-async-rabbitmq rabbitmq-diagnostics ping 2>/dev/null || echo "failed")
if [[ "$RMQ_ASYNC" == *"pong"* ]]; then
    echo -e "${GREEN}✓ Responding${NC}"
else
    echo -e "${RED}✗ Not responding${NC}"
fi
echo ""

echo -e "${BLUE}12. API DIAGNOSTIC${NC}"
echo "─────────────────────────────────────────────────────────────────"

echo -n "Backend API: "
API_CHECK=$(docker-compose -f "$COMPOSE_FILE" exec -T taiga-gateway curl -s http://taiga-back:8000/api/v1/auth/profile/ -H "Content-Type: application/json" 2>/dev/null | head -1 || echo "failed")
if [ "$API_CHECK" != "failed" ]; then
    echo -e "${GREEN}✓ Responding${NC}"
else
    echo -e "${RED}✗ Not responding${NC}"
fi
echo ""

echo -e "${BLUE}13. RECENT ERROR LOG${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Check for errors in all services
ERROR_SUMMARY=$(docker-compose -f "$COMPOSE_FILE" logs 2>/dev/null | grep -iE "error|fatal|exception|warning" | tail -20 || echo "No errors found")
if [ -z "$ERROR_SUMMARY" ]; then
    echo -e "${GREEN}✓ No recent errors detected${NC}"
else
    echo -e "${YELLOW}⚠ Recent errors/warnings:${NC}"
    echo "$ERROR_SUMMARY"
fi
echo ""

echo -e "${BLUE}14. CONFIGURATION CHECK${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Check env variables
if [ -f ".env.production" ]; then
    echo -e "${GREEN}✓ .env.production exists${NC}"
    echo "  Settings:"
    grep "^TAIGA_" .env.production | sed 's/^/    /'
else
    echo -e "${RED}✗ .env.production not found${NC}"
fi
echo ""

echo -e "${BLUE}15. RECOMMENDATIONS${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Analyze and provide recommendations
ISSUES=0

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 85 ]; then
    echo "⚠ HIGH DISK USAGE ($DISK_USAGE%): Consider cleanup or expansion"
    ((ISSUES++))
fi

# Check container health
UNHEALTHY=$(docker-compose -f "$COMPOSE_FILE" ps 2>/dev/null | grep -E "taiga-" | grep -v "healthy\|Up" | wc -l)
if [ "$UNHEALTHY" -gt 0 ]; then
    echo "⚠ $UNHEALTHY service(s) not healthy: Review logs and restart if needed"
    ((ISSUES++))
fi

# Check errors in logs
ERROR_COUNT=$(docker-compose -f "$COMPOSE_FILE" logs 2>/dev/null | grep -iE "error|fatal" | wc -l)
if [ "$ERROR_COUNT" -gt 10 ]; then
    echo "⚠ MANY ERRORS in logs ($ERROR_COUNT): Investigate root cause"
    ((ISSUES++))
fi

if [ "$ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✓ System appears healthy - no issues detected${NC}"
fi
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                 DIAGNOSTICS COMPLETE${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Full report saved to: $REPORT_FILE${NC}"
echo ""
