#!/bin/sh
set -e

echo "Starting TinyProxy with enhanced entrypoint..."

# Set default values if not provided
HEALTH_CHECK_INTERVAL=${HEALTH_CHECK_INTERVAL:-30}
PROXY_PORT=${PROXY_PORT:-8888}
PASSWORD_FILE=${PASSWORD_FILE:-/data/password.txt}
AUTH_USER=${AUTH_USER:-user}

# Create necessary directories
mkdir -p /data
mkdir -p /var/log/tinyproxy
mkdir -p /var/run/tinyproxy
chown -R nobody:nobody /var/log/tinyproxy /var/run/tinyproxy

# Generate password if it doesn't exist
if [ ! -f "$PASSWORD_FILE" ]; then
    echo "No password found at $PASSWORD_FILE, generating random password..."
    # Generate a random 20-character password
    RANDOM_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
    echo "$RANDOM_PASSWORD" > "$PASSWORD_FILE"
    echo "Generated password stored in $PASSWORD_FILE"
    echo "Password: $RANDOM_PASSWORD"
else
    echo "Using existing password from $PASSWORD_FILE"
fi

# Read the password
AUTH_PASSWORD=$(cat "$PASSWORD_FILE")

# Update TinyProxy configuration with credentials
if [ -n "$AUTH_USER" ] && [ -n "$AUTH_PASSWORD" ]; then
    echo "Configuring TinyProxy with authentication..."
    # Create basic auth line
    AUTH_LINE="BasicAuth $AUTH_USER $AUTH_PASSWORD"
    
    # Check if auth line already exists in config
    if ! grep -q "^BasicAuth" /etc/tinyproxy/tinyproxy.conf; then
        # Add auth line after port configuration
        sed -i "/^Port /a $AUTH_LINE" /etc/tinyproxy/tinyproxy.conf
    else
        # Update existing auth line
        sed -i "s/^BasicAuth.*/$AUTH_LINE/" /etc/tinyproxy/tinyproxy.conf
    fi
fi

# Update port in configuration if different from default
if [ "$PROXY_PORT" != "8888" ]; then
    echo "Setting proxy port to $PROXY_PORT"
    sed -i "s/^Port .*/Port $PROXY_PORT/" /etc/tinyproxy/tinyproxy.conf
fi

# Function to handle cleanup
cleanup() {
    echo "Received signal, shutting down..."
    if [ -n "$TINYPROXY_PID" ]; then
        kill -TERM "$TINYPROXY_PID" 2>/dev/null
    fi
    if [ -n "$HEALTHCHECK_PID" ]; then
        kill -TERM "$HEALTHCHECK_PID" 2>/dev/null
    fi
    wait
    echo "Shutdown complete"
    exit 0
}

# Trap signals
trap cleanup TERM INT

# Start TinyProxy in background
echo "Starting TinyProxy on port $PROXY_PORT..."
tinyproxy -d -c /etc/tinyproxy/tinyproxy.conf &
TINYPROXY_PID=$!

# Wait a moment for TinyProxy to start
sleep 2

# Start health check process in background
echo "Starting health check process (interval: ${HEALTH_CHECK_INTERVAL}s)..."
/healthcheck.sh &
HEALTHCHECK_PID=$!

# Wait for both processes
echo "Entrypoint: Waiting for processes..."
wait $TINYPROXY_PID $HEALTHCHECK_PID

# If we reach here, one of the processes died
echo "One of the processes terminated unexpectedly"
cleanup