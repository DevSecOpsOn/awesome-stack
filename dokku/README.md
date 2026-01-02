# Dokku Stack

A complete Dokku Platform-as-a-Service (PaaS) deployment using Docker Swarm, following Heroku-like deployment patterns.

## Overview

This stack provides:
- **Dokku**: Main PaaS platform for app deployment
- **PostgreSQL**: Default database service
- **Redis**: Caching and session storage
- **Traefik Integration**: Automatic SSL and load balancing

## Quick Start

1. **Copy environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

2. **Deploy the stack:**
   ```bash
   docker stack deploy -c dokku.yaml dokku
   ```

3. **Run initial setup:**
   ```bash
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

4. **Access Dokku:**
   - Web Interface: http://dokku.docker.local
   - SSH: `ssh dokku@dokku.docker.local`

## Deploying Applications

### Method 1: Git Push (Recommended)
```bash
# Add Dokku remote to your app
git remote add dokku dokku@dokku.docker.local:myapp

# Deploy
git push dokku main
```

### Method 2: Docker Image
```bash
# Tag and push your image
docker tag myapp:latest dokku/myapp:latest
docker exec $(docker ps -q -f name=dokku_dokku) dokku tags:deploy myapp latest
```

## Common Commands

### App Management
```bash
# List apps
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku apps:list

# Create app
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku apps:create myapp

# Delete app
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku apps:destroy myapp
```

### Database Management
```bash
# Create PostgreSQL database
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku postgres:create mydb

# Link database to app
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku postgres:link mydb myapp

# Create Redis cache
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku redis:create mycache
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku redis:link mycache myapp
```

### Domain Management
```bash
# Add domain to app
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku domains:add myapp myapp.example.com

# Enable SSL
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku letsencrypt:enable myapp
```

### Environment Variables
```bash
# Set environment variable
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku config:set myapp NODE_ENV=production

# View app config
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku config myapp
```

## Supported Buildpacks

Dokku automatically detects and uses appropriate buildpacks:
- **Node.js** (package.json)
- **Python** (requirements.txt, Pipfile)
- **Ruby** (Gemfile)
- **PHP** (composer.json)
- **Go** (go.mod)
- **Java** (pom.xml, build.gradle)
- **Static Sites** (index.html)
- **Docker** (Dockerfile)

## Configuration

### Environment Variables
- `DOKKU_POSTGRES_PASSWORD`: PostgreSQL password
- `DOKKU_REDIS_PASSWORD`: Redis password
- `DOKKU_HOSTNAME`: Main hostname for Dokku
- `DOKKU_LETSENCRYPT_EMAIL`: Email for SSL certificates

### Volumes
- `dokku_data`: Main Dokku data
- `dokku_storage`: App storage
- `dokku_config`: Configuration files
- `postgres_data`: PostgreSQL data
- `redis_data`: Redis data

## Monitoring

### Health Checks
```bash
# Check Dokku status
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku version

# Check app status
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku ps myapp
```

### Logs
```bash
# View app logs
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku logs myapp

# Follow logs
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku logs myapp -t
```

## Backup & Restore

### Database Backup
```bash
# Backup PostgreSQL
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku postgres:export mydb > backup.sql

# Restore PostgreSQL
docker exec -i $(docker ps -q -f name=dokku_dokku) dokku postgres:import mydb < backup.sql
```

### App Backup
```bash
# Export app
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku tar:export myapp > myapp-backup.tar

# Import app
docker exec -i $(docker ps -q -f name=dokku_dokku) dokku tar:import myapp < myapp-backup.tar
```

## Troubleshooting

### Common Issues

1. **App won't start:**
   ```bash
   docker exec -it $(docker ps -q -f name=dokku_dokku) dokku logs myapp
   docker exec -it $(docker ps -q -f name=dokku_dokku) dokku config myapp
   ```

2. **Database connection issues:**
   ```bash
   docker exec -it $(docker ps -q -f name=dokku_dokku) dokku postgres:info mydb
   ```

3. **SSL certificate issues:**
   ```bash
   docker exec -it $(docker ps -q -f name=dokku_dokku) dokku letsencrypt:list
   ```

### Debug Mode
```bash
# Enable trace mode
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku trace:on

# Disable trace mode
docker exec -it $(docker ps -q -f name=dokku_dokku) dokku trace:off
```

## Security

- Change default passwords in `.env`
- Use SSH keys for Git deployments
- Enable SSL for production domains
- Regular security updates
- Monitor access logs

## Resources

- [Dokku Documentation](http://dokku.viewdocs.io/dokku/)
- [Dokku Plugins](https://github.com/dokku/dokku/wiki/Plugins)
- [Buildpack Documentation](https://devcenter.heroku.com/articles/buildpacks)
