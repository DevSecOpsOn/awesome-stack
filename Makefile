# Global variables for Makefile targets and resources
DOCKER_CLI := $(shell which docker 2>/dev/null)
PODMAN_CLI := $(shell which podman 2>/dev/null)
CONTAINER_ENGINE := $(if $(DOCKER_CLI),$(DOCKER_CLI),$(if $(PODMAN_CLI),$(PODMAN_CLI),docker))
SWARM_ADDR_ := $(shell ifconfig | grep -E "inet 192.168.2" | awk '{print $$2}')
# Stack list
AI := activepieces n8n
AIML := aiml
PROXY := traefik ngrok squid
DATABASES := db redis
DOCS := hedgedoc
CI_CD := concourse droneci harness gocd jenkins teamcity
INFRA := consul localstack runatlantis sablier
MONITORING := beszel dozzle grafana jaeger otelcol prometheus
OBSERVABILITY :=
PASS := dokku dokploy
PORTALS := homarr portainer
VCS := gogs gitea
SECURITY := vault passbolt
BACKUP := repliqate
STORAGE := minio
DEVOPS := $(PROXY) $(DATABASES) $(CI_CD) $(PASS) $(INFRA) $(PORTALS) $(MONITORING) $(VCS) $(STORAGE)
DEVSECOPS := $(DEVOPS) $(OBSERVABILITY) $(SECURITY)
HOSTS_VERSION := v15

# Resources to prune
RESOURCES := container volume image

define HOST_ENTRIES
#### docker-stack: $(HOSTS_VERSION) ####
# AI
127.0.0.1 activepieces.docker.local n8n.docker.local hedgedoc.docker.local
# AI/ML
127.0.0.1 langchain.docker.local qwen.docker.local pytorch.docker.local tensorflow.docker.local airflow.docker.local
# Databases
127.0.0.1 mongodb.docker.local mongo-express.docker.local mongo-compass.docker.local redis.docker.local clickhouse.docker.local
# Ingress & Proxy stack
127.0.0.1 traefik.docker.local haproxy.docker.local squid.docker.local
127.0.0.1 ngrok-bb.docker.local ngrok-gh.docker.local
# Infrastructure stack
127.0.0.1 atlantis.docker.local coolify.docker.local consul.docker.local dokku.docker.local dokploy.docker.local easypanel.docker.local kamal.docker.local sablier.docker.local
# VCS, CI/CD stack
127.0.0.1 gogs.docker.local
127.0.0.1 droneci-bb.docker.local droneci-gh.docker.local
127.0.0.1 concourse.docker.local harness.docker.local gitea.docker.local gocd.docker.local jenkins.docker.local teamcity.docker.local
# WebUI & Portal stack
127.0.0.1 adminer.docker.local portainer.docker.local devsecopson.docker.local
# Monitoring stack
127.0.0.1 alertmanager.docker.local beszel.docker.local dozzle.docker.local grafana.docker.local prometheus.docker.local jaeger.docker.local
# Logging stack (ELK)
127.0.0.1 elasticsearch.docker.local fluentbit.docker.local kibana.docker.local logstash.docker.local
# Cloud Cost Management stack
127.0.0.1 komiser.docker.local
# Networking stack
# Security stack
127.0.0.1 vault.docker.local passbolt.docker.local
# Storage stack
127.0.0.1 minio.docker.local s3.docker.local openio.docker.local repliqate.docker.local
#### docker-stack ####

endef
export HOST_ENTRIES

# Define PHONY targets to ensure they always execute
.PHONY: all check_docker init network secrets devops devsecops podman update-hosts show-stacks vault_unseal remove-stack remove-podman droneci help

# Default target (shows available parameters)
default: help

# Show available parameters
help:
	@echo "Usage: make [target]"
	@echo "Available targets:"
	@echo "  check          - Verify if Docker is running"
	@echo "  init           - Initialize Docker Swarm"
	@echo "  network        - Create Docker overlay network"
	@echo "  secrets        - Create Docker secret for database password"
	@echo "  setup          - Run all setup steps"
	@echo "  devops         - Deploy Dev / Ops essential stack"
	@echo "  devsecops      - Deploy Dev/ Sec/ Ops essential stack"
	@echo "  podman         - Deploy stacks using Podman (when Docker daemon is not running)"
	@echo "  update-hosts   - Update /et/hosts file with stack FQDN"
	@echo "  show-stacks    - Show all running Docker containers"
	@echo "  remove-stack   - Remove only the stacks defined in this Makefile"
	@echo "  remove-podman  - Remove Podman stacks and containers"
	@echo "---------------------------------------------------------------------------------------"
	@echo "  🚨 At least one parameter must be provided. 🚨"

# Default target (runs all steps)
setup: check init network secrets

# Check if container engine is running
check:

	@clear
	@$(CONTAINER_ENGINE) info > /dev/null 2>&1 || (echo "Container engine ($(CONTAINER_ENGINE)) is not running. Please start it." && exit 1)
	@echo "⚙️ Container engine ($(CONTAINER_ENGINE)) is running."

# Initialize Docker Swarm (if not already initialized)
init:

	@$(CONTAINER_ENGINE) info | grep 'Swarm: active' || $(CONTAINER_ENGINE) swarm init
	@echo "🤖 Container swarm initialized."

# Create a container network with overlay driver and attachable parameter
network:

	@$(CONTAINER_ENGINE) network ls | grep 'docker2docker' || $(CONTAINER_ENGINE) network create --driver=bridge --attachable --ipv6=true  --ipam-driver=default --scope=local compose2compose
	@$(CONTAINER_ENGINE) network ls | grep 'docker2docker' || $(CONTAINER_ENGINE) network create --driver=overlay --subnet 10.1.0.0/16 --attachable --ipv6=true  --ipam-driver=default --scope=swarm docker2docker
	@echo "🎯 Container network 'compose2compose' and 'docker2docker' created or already exists."

# Create a container secret for the database password
secrets:

	@echo "🔐 Creating container secret for database password..."
	@if [ -z "$$DOCKER_SECRET_DB" ] && [ -z "$$SLACK_ALERTS_HOOK" ]; then \
		echo "🔒 Environment variable DOCKER_SECRET_DB and SLACK_ALERTS_HOOK are not set. Generating a dummy password..."; \
		export DOCKER_SECRET_DB="dummy-db-password"; \
		export SLACK_ALERTS_HOOK="xbox-xxxx-yyyy-zzzz"; \
		echo "$$DOCKER_SECRET_DB" | $(CONTAINER_ENGINE) secret create DOCKER_SECRET_DB -; \
		echo "$$SLACK_ALERTS_HOOK" | $(CONTAINER_ENGINE) secret create SLACK_ALERTS_HOOK -; \
		echo "✅ Container secret 'DOCKER_SECRET_DB' and 'SLACK_ALERTS_HOOK' created with dummy password."; \
		echo "✅ Container secret 'SLACK_ALERTS_HOOK' and 'SLACK_ALERTS_HOOK' created with dummy password."; \
	else \
		echo "✅ DOCKER_SECRET_DB and SLACK_ALERTS_HOOK are already set. Using existing value."; \
		echo "$$DOCKER_SECRET_DB" | $(CONTAINER_ENGINE) secret create DOCKER_SECRET_DB - 2>/dev/null || echo "⚠️  Container secret 'DOCKER_SECRET_DB' already exists or failed to create."; \
		echo "$$SLACK_ALERTS_HOOK" | $(CONTAINER_ENGINE) secret create SLACK_ALERTS_HOOK - 2>/dev/null || echo "⚠️  Container secret 'SLACK_ALERTS_HOOK' already exists or failed to create."; \
	fi

# Deploy DevOps stacks
devops: show-stacks update-hosts

	@echo "Deploying container stack ..."
	@for stack in $(DEVOPS); do \
	  FILE=$$(find $$stack -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) | head -n 1); \
	  if [ -n "$$FILE" ]; then \
	    $(CONTAINER_ENGINE) stack deploy -c $$FILE $$stack; \
	    echo "🛫 Stack $$stack deployed using $$FILE"; \
		echo "----"; \
	  else \
	    echo "‼️ No YAML file found for $$stack, skipping deployment ‼️"; \
	  fi; \
	done

# Deploy DevSecOps stacks
devsecops: show-stacks update-hosts

	@echo "Deploying container stack ..."
	@for stack in $(DEVSECOPS); do \
	  FILE=$$(find $$stack -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) | head -n 1); \
	  if [ -n "$$FILE" ]; then \
	    $(CONTAINER_ENGINE) stack deploy -c $$FILE $$stack; \
	    echo "🛫 Stack $$stack deployed using $$FILE"; \
		echo "----"; \
	  else \
	    echo "‼️ No YAML file found for $$stack, skipping deployment ‼️"; \
	  fi; \
	done

# Deploy stacks using Podman (when Docker daemon is not running)
podman:

	@for stack in $(DEVSECOPS); do \
		FILE=$$(find $$stack -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) | head -n 1); \
		if [ -n "$$FILE" ]; then \
				echo "🐳 Deploying $$stack using Podman... "; \
				podman compose -f $$FILE -p $$stack up -d; \
			echo "✅ Stack $$stack deployed using $$FILE"; \
			echo "----"; \
		else \
			echo "‼️ No YAML file found for $$stack, skipping deployment ‼️"; \
		fi; \
		done
	@podman ps -a

# Update /etc/hosts file with stack FQDN
update-hosts:
	@echo "Checking /etc/hosts for Docker stack entries ..."
	@BACKUP_DATE=$$(date "+%Y%m%d_%H%M%S"); \
	BACKUP_FILE="/etc/hosts_back_$$BACKUP_DATE"; \
	START_MARKER="#### docker-stack: $(HOSTS_VERSION) ####"; \
	END_MARKER="#### docker-stack ####"; \
	TEMP_FILE="/tmp/hosts_entries_$$$$"; \
	EXISTING_FILE="/tmp/existing_entries_$$$$"; \
	TEMP_HOSTS="/tmp/hosts_temp_$$$$"; \
	echo "$$HOST_ENTRIES" > "$$TEMP_FILE"; \
	if ! grep -q "$$START_MARKER" /etc/hosts; then \
		echo "Docker stack entries not found in /etc/hosts. Adding them ..."; \
		sudo cp /etc/hosts "$$BACKUP_FILE"; \
		echo "Backup created: $$BACKUP_FILE"; \
		echo "" | sudo tee -a /etc/hosts > /dev/null; \
		cat "$$TEMP_FILE" | sudo tee -a /etc/hosts > /dev/null; \
		echo "Docker stack entries added to /etc/hosts"; \
	else \
		awk "/$$START_MARKER/,/$$END_MARKER/" /etc/hosts > "$$EXISTING_FILE" 2>/dev/null || echo "" > "$$EXISTING_FILE"; \
		if ! diff -q "$$EXISTING_FILE" "$$TEMP_FILE" >/dev/null 2>&1; then \
			echo "Docker stack entries differ. Updating /etc/hosts ..."; \
			sudo cp /etc/hosts "$$BACKUP_FILE"; \
			echo "Backup created: $$BACKUP_FILE"; \
			awk "BEGIN{skip=0} /$$START_MARKER/{skip=1} !skip{print} /$$END_MARKER/{skip=0; next}" /etc/hosts > "$$TEMP_HOSTS"; \
			sudo cp "$$TEMP_HOSTS" /etc/hosts; \
			cat "$$TEMP_FILE" | sudo tee -a /etc/hosts > /dev/null; \
			echo "Docker stack entries updated in /etc/hosts"; \
		else \
			echo "Docker stack entries in /etc/hosts are up to date. No changes needed."; \
		fi; \
	fi; \
	rm -f "$$TEMP_FILE" "$$EXISTING_FILE" "$$TEMP_HOSTS"

# Remove Docker stacks and containers
remove-stack:

	@echo "🧹 Removing Docker stacks and containers..."
	@for stack in $(DEVSECOPS); do \
		$(CONTAINER_ENGINE) stack ls | grep -w $$stack > /dev/null && $(CONTAINER_ENGINE) stack rm $$stack && echo "Stack $$stack removed." || echo "Stack $$stack not found, skipping."; \
	done

	@for resources in $(RESOURCES); do \
	  $(CONTAINER_ENGINE) $$resources prune -f; \
	done
	@echo "Pruned unused container resources."

# Remove Podman stacks and containers
remove-podman:

	@echo "🧹 Removing Podman stacks and containers..."
	@if command -v podman-compose >/dev/null 2>&1; then \
		for stack in $(DEVSECOPS) $(DEVOPS); do \
			FILE=$$(find $$stack -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) | head -n 1); \
			if [ -n "$$FILE" ]; then \
				echo "🗑️  Removing stack $$stack..."; \
				podman compose -f $$FILE -p $$stack down 2>/dev/null || echo "Stack $$stack not found or already removed"; \
			fi; \
		done; \
	else \
		echo "🗑️  Removing all Podman containers..."; \
		podman rm -af 2>/dev/null || echo "No containers to remove"; \
		echo "🗑️  Removing all Podman pods..."; \
		podman pod rm -af 2>/dev/null || echo "No pods to remove"; \
	fi
	@echo "🧹 Pruning Podman resources..."
	@podman system prune -af 2>/dev/null || echo "Podman prune completed"
	@echo "✅ Podman cleanup completed"

# Show all running containers
show-stacks: check
	@echo "⚙️ Listing all running containers. "
	@$(CONTAINER_ENGINE) stack ls
	@$(CONTAINER_ENGINE) service ls
	@$(CONTAINER_ENGINE) container ps

# Drone CI setup: enable repositories in Drone

ORG := rdgacarvalho
REPOS := docker helm kubernetes terraform

droneci:

	@echo "Enabling repositories in Drone..."
	@for repo in $(REPOS); do \
		echo "Enabling repository $$repo in Drone..."; \
		drone repo sync $(ORG)/$$repo; \
		drone repo enable $(ORG)/$$repo; \
		drone repo update --trusted $(ORG)/$$repo; \
		drone repo chown $(ORG)/$$repo; \
	done

	@echo "✅ Repositories enabled in Drone.";
	drone repo ls $(ORG)

	@echo "🔐 Creating Drone organization secrets..."
	@if [ -n "$$DOCKER_SECRET_DB" ]; then \
		echo "Creating DOCKER_DB_SECRET in Drone..."; \
		echo "$$DOCKER_SECRET_DB" | base64 > DOCKER_SECRET_DB.base64; \
		echo "$$SLACK_ALERTS_HOOK" | base64 > SLACK_ALERTS_HOOK.base64; \
		echo "$$slack_deploys_hook" | base64 > SLACK_WEBHOOK.base64; \
		drone orgsecret add --allow-pull-request  $(ORG) DOCKER_SECRET_DB --data "$$DOCKER_SECRET_DB" || echo "⚠️  DOCKER_DB_SECRET already exists or failed to create"; \
		drone orgsecret add --allow-pull-request  $(ORG) SLACK_ALERTS_HOOK --data "$$SLACK_ALERTS_HOOK" || echo "⚠️  SLACK_ALERTS_HOOK already exists or failed to create"; \
		drone orgsecret add --allow-pull-request  $(ORG) SLACK_WEBHOOK --data "$$SLACK_WEBHOOK" || echo "⚠️  SLACK_WEBHOOK already exists or failed to create"; \
		echo "✅ Drone organization secrets setup completed"; \
		rm -f DOCKER_SECRET_DB.base64 SLACK_ALERTS_HOOK.base64 SLACK_WEBHOOK.base64; \
	else \
		echo "⚠️  Drone CLI not found, skipping organization secrets creation"; \
		echo "💡 Install Drone CLI: curl -L https://github.com/harness/drone-cli/releases/latest/download/drone_darwin_$$(uname -p).tar.gz | tar zx"; \
	fi
	@drone orgsecret ls $(ORG)
