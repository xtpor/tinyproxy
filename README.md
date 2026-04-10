# Enhanced TinyProxy Docker

This is an enhanced version of TinyProxy in Docker with automatic password generation, persistent storage, and built-in health checks.

## Features

- **Automatic Password Generation**: On first run, a random password is generated and stored in a volume
- **Persistent Storage**: Password is stored in a Docker volume for persistence across container restarts
- **Built-in Health Checks**: Continuous monitoring of proxy availability with configurable intervals
- **Customizable Configuration**: Environment variables for easy configuration
- **Graceful Shutdown**: Proper signal handling for clean shutdown

## Quick Start

1. **Build and run**:
   ```bash
   docker-compose up -d
   ```

2. **View generated password** (on first run):
   ```bash
   docker logs tinyproxy | grep "Password:"
   ```

3. **Use the proxy**:
   - Proxy URL: `http://localhost:1080`
   - Username: `user` (default, configurable via `AUTH_USER`)
   - Password: (see generated password in logs)

## Configuration

### Environment Variables

Create a `.env` file (copy from `.env.example`):

```bash
cp .env.example .env
```

Available variables:
- `HEALTH_CHECK_INTERVAL`: Seconds between health checks (default: 30)
- `PROXY_PORT`: Internal proxy port (default: 8888)
- `AUTH_USER`: Username for proxy authentication (default: "user")
- `PASSWORD_FILE`: Path to password file in container (default: `/data/password.txt`)

### Volumes

- `tinyproxy_data`: Stores the generated password file

### Ports

- `1080:8888`: Maps host port 1080 to container port 8888

## How It Works

### Entrypoint Script (`entrypoint.sh`)
1. Checks for existing password in `/data/password.txt`
2. Generates random password if none exists
3. Updates TinyProxy configuration with credentials
4. Starts TinyProxy process
5. Starts health check process
6. Manages graceful shutdown

### Health Check Script (`healthcheck.sh`)
1. Runs continuously with configurable interval
2. Uses `curl` to test proxy connectivity through itself
3. Tests against `http://httpbin.org/get`
4. Retries on failure before exiting
5. Logs health check results

## Building Custom Image

The `Dockerfile` extends the official `vimagick/tinyproxy` image and adds:
- `curl` for health checks
- Custom entrypoint and health check scripts
- Configuration management

Build manually:
```bash
docker build -t tinyproxy-enhanced .
```

## Viewing Logs

```bash
# View all logs
docker logs tinyproxy

# Follow logs
docker logs -f tinyproxy

# View only health check logs
docker logs tinyproxy 2>&1 | grep "Health check"
```

## Security Notes

1. **Password Security**: The password is generated once and stored in a volume. For production:
   - Use a strong custom password
   - Consider using Docker secrets or external secret management
   - Regularly rotate passwords

2. **Network Security**:
   - The proxy is exposed on all interfaces by default
   - Consider restricting `Allow` directives in `tinyproxy.conf`
   - Use firewall rules to restrict access

3. **Health Checks**:
   - Health checks make external requests to `httpbin.org`
   - For air-gapped environments, modify `healthcheck.sh` to use internal endpoints

## Testing

An automated test script is provided to verify the build, password generation, and proxy connectivity:

```bash
./test.sh
```

The script will:
1. Build the Docker image
2. Start a temporary container
3. Retrieve the generated password
4. Test proxy connectivity via `httpbin.org`
5. Verify health checks are running
6. Clean up the test container

## Troubleshooting

### Password Issues
```bash
# Reset password (delete volume)
docker-compose down -v
docker-compose up -d
```

### Health Check Failures
```bash
# Check connectivity
docker exec tinyproxy curl -v --proxy http://user:password@localhost:8888 http://httpbin.org/get

# View health check logs
docker logs tinyproxy 2>&1 | grep -A2 -B2 "Health check"
```

### Proxy Not Working
```bash
# Test from host
curl -v --proxy http://user:password@localhost:1080 http://httpbin.org/get

# Check container status
docker-compose ps
docker-compose logs
```

## License

MIT