# GitLab CI Pipeline Documentation

This directory contains the modular GitLab CI pipeline configuration for Docker Swarm deployment.

## Pipeline Structure

### Main Configuration
- `.gitlab-ci.yml` - Main pipeline orchestrator that includes all modules

### Pipeline Modules

#### 1. Security Scan (`security-scan.yml`)
**Purpose**: Comprehensive security scanning and vulnerability detection

**Jobs**:
- `security-scan`: Trivy configuration and secret scanning
- `secret-detection`: GitLeaks credential detection
- `dockerfile-lint`: Hadolint Dockerfile linting

**Features**:
- Scans YAML files for misconfigurations
- Detects secrets and sensitive data
- Validates Dockerfile best practices
- Generates security reports

#### 2. Stack Validation (`validate-stacks.yml`)
**Purpose**: Validates Docker Compose files and stack structure

**Jobs**:
- `validate-stacks`: Complete stack validation

**Features**:
- Docker Compose syntax validation
- Stack structure verification
- Network configuration checks
- Hardcoded password detection

#### 3. Docker Swarm Deployment (`deploy-swarm.yml`)
**Purpose**: Handles Docker Swarm setup and stack deployment

**Jobs**:
- `setup-swarm`: Initialize Docker Swarm and networks
- `deploy-base-stacks`: Deploy infrastructure stacks
- `deploy-devops-stacks`: Deploy DevOps tools
- `deploy-security-stacks`: Deploy security tools
- `health-check`: Verify deployment health

**Features**:
- Staged deployment approach
- Health monitoring
- Service status reporting
- Deployment summaries

#### 4. Notifications (`notifications.yml`)
**Purpose**: Handles notifications and reporting

**Jobs**:
- `slack-notification-success`: Success notifications
- `slack-notification-failure`: Failure notifications
- `mr-comment`: Merge request comments

**Features**:
- Slack integration for #commits channel
- Detailed deployment reports
- Merge request status updates
- Rich formatting with links

#### 5. Cleanup (`cleanup.yml`)
**Purpose**: Resource cleanup and maintenance

**Jobs**:
- `cleanup-resources`: Automatic cleanup after deployment
- `manual-cleanup`: Manual full cleanup option

**Features**:
- Selective stack removal
- Resource pruning
- Full environment reset option
- Status reporting

## Pipeline Flow

```
Merge Request Created/Updated
├── Security Stage
│   ├── security-scan
│   ├── secret-detection
│   └── dockerfile-lint
├── Validate Stage
│   └── validate-stacks
├── Deploy Stage
│   ├── setup-swarm
│   ├── deploy-base-stacks
│   ├── deploy-devops-stacks
│   ├── deploy-security-stacks
│   └── health-check
├── Notify Stage
│   ├── slack-notification-success/failure
│   └── mr-comment
└── Cleanup Stage
    ├── cleanup-resources
    └── manual-cleanup (manual)
```

## Required Variables

### GitLab CI/CD Variables
Set these in your GitLab project settings under CI/CD > Variables:

- `SLACK_WEBHOOK_URL`: Slack webhook URL for notifications
- `GITLAB_TOKEN`: GitLab API token for MR comments
- `GITLAB_USERNAME`: GitLab username for git operations
- `DOCKER_SECRET_DB`: Database password (for production)
- `SLACK_ALERTS_HOOK`: Slack alerts webhook

### Environment Variables
The pipeline uses these GitLab predefined variables:
- `CI_MERGE_REQUEST_IID`: Merge request ID
- `CI_MERGE_REQUEST_SOURCE_BRANCH_NAME`: Source branch
- `CI_PROJECT_NAME`: Project name
- `CI_COMMIT_SHA`: Commit hash
- `GITLAB_USER_NAME`: User who triggered the pipeline

## Triggers

### Automatic Triggers
- **Merge Request Events**: Pipeline runs on MR creation/updates
- **Master Branch**: Cleanup job runs on master branch pushes

### Manual Triggers
- **Manual Cleanup**: Full environment cleanup via GitLab UI
- **Web Trigger**: Manual pipeline execution

## Security Features

### Vulnerability Scanning
- Configuration vulnerability detection with Trivy
- Secret and credential scanning with GitLeaks
- Dockerfile security linting with Hadolint

### Data Protection
- No hardcoded passwords allowed
- Environment variable validation
- Secret detection in code changes

### Access Control
- Pipeline only runs on merge requests
- Cleanup requires manual approval
- Token-based authentication for notifications

## Deployment Strategy

### Staged Deployment
1. **Base Stacks**: Core infrastructure (Traefik, DB, Ngrok, DroneCI)
2. **DevOps Stacks**: Development and operations tools
3. **Security Stacks**: Security and compliance tools

### Health Monitoring
- Service readiness checks
- Container status monitoring
- Network connectivity validation
- Resource utilization reporting

## Notifications

### Slack Integration
- Success/failure notifications to #commits channel
- Rich message formatting with deployment details
- Direct links to pipelines and merge requests

### Merge Request Comments
- Comprehensive deployment summaries
- Security scan results
- Service status reports
- Direct links to relevant resources

## Maintenance

### Regular Cleanup
- Automatic resource cleanup after each deployment
- Selective stack removal to preserve base infrastructure
- Docker system pruning to free up space

### Manual Maintenance
- Full environment reset option
- Complete resource cleanup
- Docker Swarm reset capability

## Troubleshooting

### Common Issues
1. **Docker Daemon**: Ensure Docker-in-Docker service is available
2. **Network Issues**: Check overlay network creation
3. **Secret Creation**: Verify secret creation permissions
4. **Service Health**: Monitor service startup times

### Debug Information
- Pipeline logs include detailed status information
- Deployment summaries show service counts
- Health checks provide service status
- Cleanup logs show resource removal

## Extending the Pipeline

### Adding New Stacks
1. Add stack directory to validation lists
2. Include in appropriate deployment stage
3. Update cleanup configuration if needed

### Adding New Security Scans
1. Add new job to `security-scan.yml`
2. Configure appropriate rules and dependencies
3. Update notification templates

### Custom Notifications
1. Modify notification templates in `notifications.yml`
2. Add new notification channels as needed
3. Configure additional webhook integrations
