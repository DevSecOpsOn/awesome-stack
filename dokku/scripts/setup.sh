#!/bin/bash
# Dokku Initial Setup Script
# This script configures Dokku after the first deployment

set -e

echo "🚀 Starting Dokku setup..."

# Wait for Dokku to be ready
echo "⏳ Waiting for Dokku to be ready..."
sleep 30

# Set global domain
echo "🌐 Setting global domain..."
docker exec $(docker ps -q -f name=dokku_dokku) dokku domains:set-global dokku.docker.local

# Install essential plugins
echo "🔌 Installing essential plugins..."
docker exec $(docker ps -q -f name=dokku_dokku) dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
docker exec $(docker ps -q -f name=dokku_dokku) dokku plugin:install https://github.com/dokku/dokku-redis.git redis
docker exec $(docker ps -q -f name=dokku_dokku) dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git letsencrypt
docker exec $(docker ps -q -f name=dokku_dokku) dokku plugin:install https://github.com/dokku/dokku-maintenance.git maintenance

# Create default databases
echo "💾 Creating default database services..."
# docker exec $(docker ps -q -f name=dokku_dokku) dokku postgres:create dokku-db || true
# docker exec $(docker ps -q -f name=dokku_dokku) dokku redis:create dokku-cache || true

# Set up SSH keys (if available)
if [ -f ~/.ssh/id_rsa.pub ]; then
    echo "🔑 Adding SSH key..."
    touch /home/dokku/.ssh/authorized_keys
    cat ${HOME}/.ssh/id_rsa.pub | docker exec -i $(docker ps -q -f name=dokku_dokku) dokku ssh-keys:add admin
fi

# Create a sample app
echo "📱 Creating sample app..."
docker exec $(docker ps -q -f name=dokku_dokku) dokku apps:create sample-app || true
docker exec $(docker ps -q -f name=dokku_dokku) dokku postgres:link dokku-db sample-app || true
docker exec $(docker ps -q -f name=dokku_dokku) dokku redis:link dokku-cache sample-app || true

# Set up proxy settings
echo "🔧 Configuring proxy settings..."
# docker exec $(docker ps -q -f name=dokku_dokku) dokku proxy:ports-set sample-app http:80:5000

echo "✅ Dokku setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Access Dokku at: http://dokku.docker.local"
echo "2. Deploy your first app:"
echo "   git remote add dokku dokku@dokku.docker.local:sample-app"
echo "   git push dokku main"
echo ""
echo "🔗 Useful commands:"
echo "   docker exec -it \$(docker ps -q -f name=dokku_dokku) dokku apps:list"
echo "   docker exec -it \$(docker ps -q -f name=dokku_dokku) dokku postgres:list"
echo "   docker exec -it \$(docker ps -q -f name=dokku_dokku) dokku redis:list"
