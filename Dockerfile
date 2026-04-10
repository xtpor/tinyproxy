FROM vimagick/tinyproxy:latest

# Install curl for health checks
RUN apk add --no-cache curl

# Create directory for persistent data
RUN mkdir -p /data

# Copy configuration files
COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf
COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh

# Make scripts executable
RUN chmod +x /entrypoint.sh /healthcheck.sh

# Set environment variables with defaults
ENV HEALTH_CHECK_INTERVAL=30
ENV PROXY_PORT=8888
ENV PASSWORD_FILE=/data/password.txt
ENV AUTH_USER=user

# Expose proxy port
EXPOSE ${PROXY_PORT}

# Use custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]