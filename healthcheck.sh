#!/bin/sh
set -e

echo "Starting health check process..."

# Set defaults
HEALTH_CHECK_INTERVAL=${HEALTH_CHECK_INTERVAL:-30}
PROXY_PORT=${PROXY_PORT:-8888}
PASSWORD_FILE=${PASSWORD_FILE:-/data/password.txt}
AUTH_USER=${AUTH_USER:-user}

# Read password
if [ -f "$PASSWORD_FILE" ]; then
    AUTH_PASSWORD=$(cat "$PASSWORD_FILE")
else
    echo "ERROR: Password file not found at $PASSWORD_FILE"
    exit 1
fi

# Construct proxy URL with authentication
PROXY_URL="http://$AUTH_USER:$AUTH_PASSWORD@localhost:$PROXY_PORT"

# Test URL (using a reliable, lightweight endpoint)
TEST_URL="http://httpbin.org/get"

echo "Health check configured:"
echo "  Interval: ${HEALTH_CHECK_INTERVAL}s"
echo "  Proxy: localhost:$PROXY_PORT"
echo "  Test URL: $TEST_URL"

# Wait for proxy to be ready
echo "Waiting for proxy to be ready..."
for i in $(seq 1 30); do
    if curl -s --max-time 1 --proxy "$PROXY_URL" "http://localhost:$PROXY_PORT" > /dev/null 2>&1; then
        echo "Proxy is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "ERROR: Proxy not ready after 30 seconds"
        exit 1
    fi
    sleep 1
    echo -n "."
    if [ $((i % 10)) -eq 0 ]; then
        echo ""
    fi
done
echo ""

# Health check counter
CHECK_COUNT=0

while true; do
    CHECK_COUNT=$((CHECK_COUNT + 1))
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$TIMESTAMP] Health check #$CHECK_COUNT..."
    
    # Use curl to test the proxy
    if curl -s --max-time 10 --proxy "$PROXY_URL" "$TEST_URL" > /dev/null; then
        echo "[$TIMESTAMP] ✓ Proxy is working correctly"
    else
        echo "[$TIMESTAMP] ✗ Proxy check failed!"
        # Don't exit immediately, give it a few retries
        FAILURE_COUNT=1
        RETRY=3
        
        while [ $FAILURE_COUNT -le $RETRY ]; do
            sleep 5
            echo "[$TIMESTAMP] Retry $FAILURE_COUNT/$RETRY..."
            if curl -s --max-time 10 --proxy "$PROXY_URL" "$TEST_URL" > /dev/null; then
                echo "[$TIMESTAMP] ✓ Proxy recovered after retry"
                break
            fi
            FAILURE_COUNT=$((FAILURE_COUNT + 1))
        done
        
        if [ $FAILURE_COUNT -gt $RETRY ]; then
            echo "[$TIMESTAMP] ✗ Proxy failed after $RETRY retries, exiting..."
            exit 1
        fi
    fi
    
    # Wait for the next check
    sleep "$HEALTH_CHECK_INTERVAL"
done