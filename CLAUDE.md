# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Self-hosted AI Starter Kit is a Docker Compose-based template that provides a complete local AI development environment. It's designed to be **learning-focused, not production-ready** - users should go from `git clone` to working AI workflows in minutes.

### Core Stack
- **n8n**: Low-code workflow automation platform (port 5678)
- **Ollama**: Local LLM inference (port 11434)
- **Qdrant**: Vector database for embeddings (port 6333)
- **PostgreSQL**: Data persistence for n8n
- **pgAdmin**: Database management interface (port 5050)

## Essential Commands

### Starting the Environment

**For Mac/Apple Silicon users (Ollama running locally):**
```bash
./start-n8n.sh  # Automated script with checks and browser opening
# OR manually:
docker compose up
```

**For Nvidia GPU users:**
```bash
docker compose --profile gpu-nvidia up
```

**For AMD GPU users:**
```bash
docker compose --profile gpu-amd up
```

**For CPU-only users:**
```bash
docker compose --profile cpu up
```

### Stopping the Environment

```bash
./stop-n8n.sh  # Interactive script with Ollama stop option
# OR manually:
docker compose down
```

### Upgrading Services

**Mac/Apple Silicon:**
```bash
docker compose pull
docker compose create && docker compose up
```

**GPU (Nvidia):**
```bash
docker compose --profile gpu-nvidia pull
docker compose create && docker compose --profile gpu-nvidia up
```

**CPU:**
```bash
docker compose --profile cpu pull
docker compose create && docker compose --profile cpu up
```

### Viewing Logs
```bash
docker compose logs -f n8n
docker compose logs -f ollama-cpu  # or ollama-gpu/ollama-gpu-amd
```

### Initial Setup
```bash
cp .env.example .env  # Edit secrets before starting
```

## Architecture

### Docker Compose Structure

The `docker-compose.yml` uses YAML anchors (`x-n8n`, `x-ollama`, `x-init-ollama`) to define reusable service templates that are instantiated with different profiles (cpu, gpu-nvidia, gpu-amd).

**Service dependency chain:**
1. `postgres` starts first (with healthcheck)
2. `n8n-import` runs once to import demo credentials and workflows from `n8n/demo-data/`
3. `n8n` starts after import completes
4. `ollama-*` services start based on profile
5. `ollama-pull-llama-*` runs once to download llama3.2 model

### Volume Mounts

- `n8n_storage`: Persistent n8n data at `/home/node/.n8n`
- `./n8n/demo-data`: Demo workflows/credentials mounted at `/demo-data` (read-only)
- `./shared`: Local filesystem access at `/data/shared` (read-write)
- `postgres_storage`: PostgreSQL data
- `ollama_storage`: Ollama models (shared across profile variants)
- `qdrant_storage`: Qdrant vector database
- `pgadmin_storage`: pgAdmin configuration

### Network Architecture

All services run on a single Docker network called `demo`. Services communicate using container hostnames:
- n8n connects to Postgres via `postgres:5432`
- n8n connects to Ollama via `${OLLAMA_HOST}` (defaults to `ollama:11434`)
- n8n connects to Qdrant via `qdrant:6333`

**Mac-specific networking:** When running Ollama locally on macOS (outside Docker), set `OLLAMA_HOST=host.docker.internal:11434` in `.env` to allow n8n container to reach the host's Ollama service.

### Local File Access

n8n can access local files through the `/data/shared` mount point (maps to `./shared` directory). This is used by:
- Read/Write Files from Disk node
- Local File Trigger node
- Execute Command node

## Environment Configuration

The `.env` file contains critical secrets that should be unique per installation:

**Required variables:**
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`: PostgreSQL credentials
- `N8N_ENCRYPTION_KEY`: Encrypts credentials in database (generate with `openssl rand -hex 32`)
- `N8N_USER_MANAGEMENT_JWT_SECRET`: JWT signing key (generate with `openssl rand -hex 32`)

**Mac-specific configuration:**
- `OLLAMA_HOST=host.docker.internal:11434`: Required when Ollama runs on host Mac instead of in Docker
- After starting n8n, manually update the Ollama credential at http://localhost:5678/home/credentials to use `http://host.docker.internal:11434/`

## Project Philosophy

### Simplicity Over Completeness
The kit prioritizes ease of use over comprehensive features. It's better to do fewer things well than attempt every use case.

### What Belongs
- Core components (n8n, Ollama, Qdrant, PostgreSQL)
- Basic Docker Compose profiles for different hardware
- Demo workflows showcasing AI capabilities
- Essential configuration with sensible defaults

### What Doesn't Belong
- Production infrastructure (reverse proxies, SSL/TLS, load balancers)
- Advanced networking or security hardening
- Alternative technology stacks
- Enterprise features (auth systems, multi-tenancy)
- Monitoring, backup, or orchestration beyond Docker Compose

## Development Guidelines

### Contributing
- **Small PRs only**: One feature or fix per PR
- **No typo-only PRs**: These will be rejected
- Focus on maintaining simplicity and the "just works" experience
- See CONTRIBUTING.md for full guidelines

### Shell Scripts
The repository includes two convenience scripts (in French):
- `start-n8n.sh`: Checks Docker/Ollama, creates/configures `.env`, starts services, waits for n8n, opens browser
- `stop-n8n.sh`: Stops Docker services, optionally stops Ollama

These scripts are Mac-optimized but demonstrate the startup sequence for other platforms.

## Accessing Services

- **n8n interface**: http://localhost:5678
- **Demo workflow**: http://localhost:5678/workflow/srOnR8PAY3u4RSwb
- **Ollama API**: http://localhost:11434
- **Qdrant dashboard**: http://localhost:6333/dashboard
- **pgAdmin**: http://localhost:5050 (credentials in docker-compose.yml)

## Common Issues

**First workflow run is slow:** Ollama may still be downloading llama3.2. Check logs: `docker compose logs -f ollama-cpu`

**Mac users with local Ollama:** Ensure `OLLAMA_HOST=host.docker.internal:11434` in `.env` AND update the n8n credential at http://localhost:5678/home/credentials

**Permission issues with shared folder:** Ensure `./shared` directory exists and is writable

## References

- [n8n AI documentation](https://docs.n8n.io/advanced-ai/)
- [n8n AI workflow templates](https://n8n.io/workflows/categories/ai/)
- [Ollama documentation](https://github.com/ollama/ollama)
- [Qdrant documentation](https://qdrant.tech/documentation/)