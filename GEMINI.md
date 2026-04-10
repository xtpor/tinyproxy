# GEMINI.md - Project Context & Instructions

## Project Overview
**Enhanced TinyProxy Docker** is a containerized TinyProxy solution designed for reliability and ease of use. It features automated secure password generation, persistent credential storage via Docker volumes, and a built-in health monitoring system.

### Core Stack
- **Base Image:** `vimagick/tinyproxy:latest` (Alpine-based)
- **Orchestration:** Docker & Docker Compose
- **Scripting:** POSIX-compliant Shell (sh)
- **Key Tools:** `curl` (for health checks), `sed` (for dynamic configuration)

### Architecture
- **`entrypoint.sh`**: The brain of the container. It handles:
  - Initial password generation (if missing).
  - Dynamic injection of credentials into `tinyproxy.conf`.
  - Parallel execution of the TinyProxy daemon and the health check monitor.
  - Graceful signal handling (SIGTERM/SIGINT) for clean shutdowns.
- **`healthcheck.sh`**: A background process that periodically validates the proxy's connectivity against an external endpoint (`httpbin.org`) using `curl`.
- **`tinyproxy.conf`**: The base configuration, stripped of obsolete options and optimized for containerized use.

## Building and Running

### Development & Testing
- **Run automated tests:** `./test.sh` (Builds, runs, tests connectivity, and cleans up).
- **Manual build:** `docker build -t tinyproxy-enhanced .`
- **Manual run:** `docker run --rm -it -p 1080:8888 tinyproxy-enhanced`

### Production Deployment
- **Standard start:** `docker-compose up -d`
- **View password:** `docker logs tinyproxy | grep "Password:"`
- **Stop and clean:** `docker-compose down` (Add `-v` to reset password/volumes).

## Development Conventions

### Scripting Guidelines
- **Portability:** Use `#!/bin/sh` for scripts to maintain Alpine/BusyBox compatibility.
- **Signal Handling:** Always implement `trap` for cleanup in long-running scripts (see `entrypoint.sh`).
- **Logging:** Use consistent timestamped logging for health checks and system events.

### Docker Practices
- **Persistence:** All sensitive or stateful data (like `password.txt`) must reside in the `/data` directory, which is mapped to a persistent volume.
- **Least Privilege:** TinyProxy runs as `nobody:nobody`. Ensure any directory creation in `entrypoint.sh` accounts for these permissions.
- **Layer Optimization:** Keep `Dockerfile` instructions grouped to minimize layers, specifically when installing dependencies via `apk`.

### Configuration Management
- **Dynamic Config:** Prefer environment variables for runtime configuration. Use `sed` in the entrypoint to patch `tinyproxy.conf` rather than maintaining multiple static config files.
- **Secrets:** Do not hardcode credentials. Leverage the auto-generation feature or Docker Secrets for custom passwords.

## File Map
- `Dockerfile`: Image definition and dependency management.
- `docker-compose.yml`: Default orchestration and volume mapping.
- `entrypoint.sh`: Process management and configuration patching.
- `healthcheck.sh`: Monitoring logic.
- `tinyproxy.conf`: Base proxy configuration.
- `test.sh`: CI/CD and local validation script.
- `AGENT.md`: Historical context of project rework.
