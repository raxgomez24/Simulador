#!/bin/bash

# Multi-Device Pre-flight Check Script
# This script verifies that all servers are running before manual testing

echo "============================================================"
echo "MULTI-DEVICE TESTING PRE-FLIGHT CHECKS"
echo "============================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: WebSocket Server on port 8080
echo "🔍 Checking WebSocket Server on port 8080..."
WS_CHECK=$(lsof -i :8080 | grep LISTEN)
if [ -n "$WS_CHECK" ]; then
    echo -e "${GREEN}✅ WebSocket Server is RUNNING${NC}"
    echo "$WS_CHECK"
else
    echo -e "${RED}❌ WebSocket Server is NOT running${NC}"
    echo "   Start with: cd websocket-server && npm start"
fi
echo ""

# Check 2: Flutter Web Server on port 9000
echo "🔍 Checking Flutter Web Server on port 9000..."
WEB_CHECK=$(lsof -i :9000 | grep LISTEN)
if [ -n "$WEB_CHECK" ]; then
    echo -e "${GREEN}✅ Flutter Web Server is RUNNING${NC}"
    echo "$WEB_CHECK"
else
    echo -e "${RED}❌ Flutter Web Server is NOT running${NC}"
    echo "   Start with: flutter run -d chrome --web-hostname 0.0.0.0 --web-port 9000"
fi
echo ""

# Check 3: Server reachability
echo "🔍 Checking Web Server reachability..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.40.1:9000)
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✅ Web Server is reachable (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}❌ Web Server returned HTTP $HTTP_CODE${NC}"
fi
echo ""

# Check 4: WebSocket connectivity
echo "🔍 Checking WebSocket connectivity..."
WS_RESPONSE=$(curl -s -I -N \
    -H "Connection: Upgrade" \
    -H "Upgrade: websocket" \
    -H "Sec-WebSocket-Version: 13" \
    -H "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==" \
    http://192.168.40.1:8080/ 2>&1)

if echo "$WS_RESPONSE" | grep -q "101\|WebSocket\|Upgrade"; then
    echo -e "${GREEN}✅ WebSocket endpoint is accessible${NC}"
else
    echo -e "${YELLOW}⚠️  WebSocket endpoint test inconclusive${NC}"
    echo "   (This may be normal depending on server configuration)"
fi
echo ""

# Summary
echo "============================================================"
echo "PRE-FLIGHT CHECK SUMMARY"
echo "============================================================"
echo ""

ALL_GOOD=true

if [ -z "$WS_CHECK" ]; then
    echo -e "${RED}❌ WebSocket Server (port 8080) - NOT RUNNING${NC}"
    ALL_GOOD=false
else
    echo -e "${GREEN}✅ WebSocket Server (port 8080) - RUNNING${NC}"
fi

if [ -z "$WEB_CHECK" ]; then
    echo -e "${RED}❌ Web Server (port 9000) - NOT RUNNING${NC}"
    ALL_GOOD=false
else
    echo -e "${GREEN}✅ Web Server (port 9000) - RUNNING${NC}"
fi

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✅ Server Reachability - OK${NC}"
else
    echo -e "${RED}❌ Server Reachability - FAILED${NC}"
    ALL_GOOD=false
fi

echo ""

if [ "$ALL_GOOD" = true ]; then
    echo -e "${GREEN}🎉 ALL CHECKS PASSED - Ready for manual testing!${NC}"
    echo ""
    echo "🌐 TESTING URL: http://192.168.40.1:9000"
    echo "👤 ADMIN CREDENTIALS: admin / admin123"
    echo ""
    echo "📋 MANUAL TESTING STEPS:"
    echo "  1. Open 3 browser windows with the URL above"
    echo "  2. Login as admin in Window 1"
    echo "  3. Register as guest users in Windows 2 & 3"
    echo "  4. Follow the test flows in MULTI_DEVICE_TESTING_REPORT.md"
    echo ""
    echo "============================================================"
    exit 0
else
    echo -e "${RED}❌ SOME CHECKS FAILED - Fix issues before testing${NC}"
    echo ""
    echo "🔧 TROUBLESHOOTING:"
    echo "  • WebSocket Server: cd websocket-server && npm start"
    echo "  • Web Server: flutter run -d chrome --web-hostname 0.0.0.0 --web-port 9000"
    echo "  • Check firewall: Ensure ports 8080 and 9000 are open"
    echo ""
    echo "============================================================"
    exit 1
fi