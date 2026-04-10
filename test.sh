#!/bin/bash
set -e

echo "=== Testing Enhanced TinyProxy Docker ==="
echo

# Build the image
echo "1. Building Docker image..."
docker build -t tinyproxy-enhanced . > /dev/null 2>&1
echo "   ✅ Build successful"

# Start container
echo "2. Starting container..."
docker run --rm -d --name tinyproxy-test -p 1081:8888 tinyproxy-enhanced > /dev/null 2>&1

# Wait for startup
echo "3. Waiting for startup..."
sleep 5

# Get generated password
echo "4. Retrieving generated password..."
PASSWORD=$(docker logs tinyproxy-test 2>&1 | grep "Password:" | awk '{print $2}')
if [ -z "$PASSWORD" ]; then
    echo "   ❌ Failed to get password"
    docker stop tinyproxy-test > /dev/null 2>&1
    exit 1
fi
echo "   ✅ Password: $PASSWORD"

# Test proxy
echo "5. Testing proxy connectivity..."
if curl -s --max-time 10 --proxy "http://user:$PASSWORD@localhost:1081" http://httpbin.org/get > /dev/null 2>&1; then
    echo "   ✅ Proxy test successful"
else
    echo "   ❌ Proxy test failed"
    docker stop tinyproxy-test > /dev/null 2>&1
    exit 1
fi

# Check health check logs
echo "6. Checking health check logs..."
HEALTH_LOG=$(docker logs tinyproxy-test 2>&1 | grep -c "Health check")
if [ "$HEALTH_LOG" -ge 1 ]; then
    echo "   ✅ Health checks running ($HEALTH_LOG entries found)"
else
    echo "   ⚠️  No health check logs found"
fi

# Cleanup
echo "7. Cleaning up..."
docker stop tinyproxy-test > /dev/null 2>&1
echo "   ✅ Container stopped"

echo
echo "=== All tests passed! ==="
echo
echo "To run the full setup:"
echo "  docker-compose up -d"
echo
echo "To view logs:"
echo "  docker logs tinyproxy"