# Kamal Stack

Deploy web apps anywhere from bare metal to cloud VMs using Docker with zero downtime.

## Overview

Kamal is a modern deployment tool from 37signals (creators of Ruby on Rails and Basecamp) that allows you to deploy web applications to any server with Docker installed. It provides zero-downtime deployments, health checks, and easy rollbacks.

## Features

- **Zero-downtime deployments**: Rolling deployments with health checks
- **Multi-server support**: Deploy to multiple servers simultaneously
- **Accessory services**: Manage databases, Redis, and other services
- **Environment management**: Easy configuration for different environments
- **Rollback support**: Quick rollback to previous versions
- **SSL/TLS support**: Automatic SSL certificate management
- **Docker-based**: Uses Docker for containerization

## Prerequisites

- Docker Swarm initialized
- `docker2docker` network created
- Traefik running (for routing)

## Deployment

Deploy the Kamal stack using:

```bash
# Deploy kamal stack
docker stack deploy -c kamal/kamal.yaml kamal

# Or use the Makefile
make devops  # Deploys all DevOps stacks including kamal
```

## Access

Once deployed, access Kamal at:
- **URL**: http://kamal.docker.local (via Traefik)
- **Direct Port**: 3000 (if uncommented in yaml)

## Usage

### Access the Kamal container

```bash
# Get the container ID
docker ps | grep kamal

# Execute commands in the container
docker exec -it <container-id> sh

# Or use docker service
docker service ps kamal_kamal
```

### Initialize a new Kamal project

```bash
# Inside the container
cd /app
kamal init

# This creates:
# - config/deploy.yml (main configuration)
# - .env.sample (environment variables template)
```

### Configuration

Edit the `config/deploy.yml` file to configure your deployment:

```yaml
service: myapp
image: myapp/myapp
servers:
  - 192.168.1.10
  - 192.168.1.11
registry:
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD
env:
  secret:
    - RAILS_MASTER_KEY
```

### Deploy an application

```bash
# Setup the servers (first time only)
kamal setup

# Deploy the application
kamal deploy

# Check status
kamal app status

# View logs
kamal app logs

# Rollback to previous version
kamal rollback
```

## Volumes

The stack uses three persistent volumes:

- **kamal_data**: Kamal configuration and cache (`/root/.kamal`)
- **kamal_ssh**: SSH keys for server access (`/root/.ssh`)
- **kamal_config**: Application configurations (`/app`)

## Configuration Files

Mount your SSH keys and configuration files:

```bash
# Copy SSH keys to the volume
docker cp ~/.ssh/id_rsa <container-id>:/root/.ssh/
docker cp ~/.ssh/id_rsa.pub <container-id>:/root/.ssh/

# Set proper permissions
docker exec <container-id> chmod 600 /root/.ssh/id_rsa
```

## Environment Variables

- **SERVICE_NAME**: kamal
- **SERVICE_TAGS**: deployment,devops,automation

## Resources

- **Memory Limit**: 1GB
- **CPU Limit**: 1.0 cores
- **Replicas**: 1

## Documentation

- [Official Kamal Documentation](https://kamal-deploy.org/)
- [Kamal GitHub Repository](https://github.com/basecamp/kamal)
- [Installation Guide](https://kamal-deploy.org/docs/installation/)
- [Configuration Reference](https://kamal-deploy.org/docs/configuration/)

## Common Commands

```bash
# Check Kamal version
kamal version

# Setup servers
kamal setup

# Deploy application
kamal deploy

# Check app status
kamal app status

# View logs
kamal app logs --follow

# Execute commands on servers
kamal app exec 'ls -la'

# Rollback deployment
kamal rollback

# Remove application
kamal remove
```

## Troubleshooting

### Check service status
```bash
docker service ls | grep kamal
docker service ps kamal_kamal
```

### View logs
```bash
docker service logs kamal_kamal -f
```

### Restart service
```bash
docker service update --force kamal_kamal
```

## Notes

- Kamal requires SSH access to target servers
- Store sensitive data (SSH keys, registry passwords) securely
- The container runs indefinitely with `tail -f /dev/null` to keep it alive
- Docker socket is mounted to allow Kamal to manage containers
- Placement constraint ensures it runs on manager nodes only

## Integration with Other Stacks

Kamal works well with:
- **Traefik**: For routing and load balancing
- **Consul**: For service discovery
- **Vault**: For secrets management
- **Prometheus/Grafana**: For monitoring deployed applications
