# Concourse + Slack Quick Reference

This document is a quick reference for Concourse + Slack integration 

## 🚀 Quick Commands

### Pipeline Management

```bash
# Set team
fly -t example set-team --team-name my-team --local-user foo
# Login
fly -t docker-local login -c http://concourse.docker.local -u admin -p ${DOCKER_SECRET_DB}

# Set pipeline
fly -t docker-local set-pipeline -p PIPELINE_NAME -c pipeline.yaml -l credentials.yml

# Update pipeline
fly -t docker-local set-pipeline -p PIPELINE_NAME -c pipeline.yaml -l credentials.yml

# List pipelines
fly -t docker-local pipelines

# Unpause pipeline
fly -t docker-local unpause-pipeline -p PIPELINE_NAME

# Pause pipeline
fly -t docker-local pause-pipeline -p PIPELINE_NAME

# Delete pipeline
fly -t docker-local destroy-pipeline -p PIPELINE_NAME
```

### Job Management

```bash
# Trigger job
fly -t docker-local trigger-job -j PIPELINE_NAME/JOB_NAME

# Trigger and watch
fly -t docker-local trigger-job -j PIPELINE_NAME/JOB_NAME -w

# Watch job
fly -t docker-local watch -j PIPELINE_NAME/JOB_NAME

# List jobs
fly -t docker-local jobs -p PIPELINE_NAME

# Unpause job
fly -t docker-local unpause-job -j PIPELINE_NAME/JOB_NAME

# Pause job
fly -t docker-local pause-job -j PIPELINE_NAME/JOB_NAME
```

### Build Management

```bash
# List builds
fly -t docker-local builds

# List builds for job
fly -t docker-local builds -j PIPELINE_NAME/JOB_NAME

# Get build logs
fly -t docker-local watch -b BUILD_ID

# Abort build
fly -t docker-local abort-build -j PIPELINE_NAME/JOB_NAME -b BUILD_NUMBER
```

### Validation

```bash
# Validate pipeline syntax
fly validate-pipeline -c pipeline.yaml

# Format pipeline
fly format-pipeline -c pipeline.yaml
```

## 📝 Minimal Pipeline Template (test only)

```yaml
---
resource_types:
  - name: slack-notification
    type: registry-image
    source:
      repository: cfcommunity/slack-notification-resource

resources:
  - name: slack-alert
    type: slack-notification
    source:
      url: ((slack-webhook-url))

jobs:
  - name: my-job
    plan:
      - task: my-task
        config:
          platform: linux
          image_resource:
            type: registry-image
            source: {repository: alpine}
          run:
            path: sh
            args:
              - -c
              - echo "Hello World"
    on_success:
      put: slack-alert
      params:
        text: "✅ Success!"
    on_failure:
      put: slack-alert
      params:
        text: "❌ Failed!"
```

## 🎨 Slack Message Templates

### Basic Success

```yaml
on_success:
  put: slack-alert
  params:
    text: "✅ Deployment successful"
    channel: "#deployments"
```

### Detailed Success

```yaml
on_success:
  put: slack-alert
  params:
    text: |
      ✅ *Deployment Successful*
      *Job:* $BUILD_JOB_NAME
      *Build:* #$BUILD_NAME
      <$ATC_EXTERNAL_URL/teams/$BUILD_TEAM_NAME/pipelines/$BUILD_PIPELINE_NAME/jobs/$BUILD_JOB_NAME/builds/$BUILD_NAME|View Build>
    channel: "#deployments"
    username: "Concourse CI"
    icon_emoji: ":rocket:"
```

### Failure Alert

```yaml
on_failure:
  put: slack-alert
  params:
    text: |
      ❌ *Deployment Failed*
      @channel Immediate attention required!
      <$ATC_EXTERNAL_URL/teams/$BUILD_TEAM_NAME/pipelines/$BUILD_PIPELINE_NAME/jobs/$BUILD_JOB_NAME/builds/$BUILD_NAME|View Logs>
    channel: "#alerts"
    icon_emoji: ":rotating_light:"
```

## 🔧 Common Task Configurations

### Alpine Linux

```yaml
task: my-task
config:
  platform: linux
  image_resource:
    type: registry-image
    source:
      repository: alpine
      tag: latest
  run:
    path: sh
    args: [-exc, "echo 'Hello'"]
```

### Node.js

```yaml
task: build-node
config:
  platform: linux
  image_resource:
    type: registry-image
    source:
      repository: node
      tag: "18-alpine"
  inputs:
    - name: source-code
  run:
    path: sh
    args:
      - -exc
      - |
        cd source-code
        npm install
        npm run build
```

### Docker

```yaml
task: docker-deploy
config:
  platform: linux
  image_resource:
    type: registry-image
    source:
      repository: docker
      tag: latest
  run:
    path: sh
    args:
      - -exc
      - |
        docker stack deploy -c docker-compose.yml myapp
```

### Python

```yaml
task: python-script
config:
  platform: linux
  image_resource:
    type: registry-image
    source:
      repository: python
      tag: "3.11-alpine"
  run:
    path: sh
    args:
      - -exc
      - |
        pip install -r requirements.txt
        python script.py
```

## 🔐 Credentials Management

### Using Variables File

```bash
# credentials.yml
slack-webhook-url: https://hooks.slack.com/services/XXX/YYY/ZZZ
git-private-key: |
  -----BEGIN RSA PRIVATE KEY-----
  ...
  -----END RSA PRIVATE KEY-----

# Load credentials
fly -t docker-local set-pipeline -p my-pipeline -c pipeline.yaml -l credentials.yml
```

### Using Command Line

```bash
fly -t docker-local set-pipeline \
  -p my-pipeline \
  -c pipeline.yaml \
  -v slack-webhook-url="https://hooks.slack.com/services/XXX/YYY/ZZZ"
```

### Using Vault (if configured)

```yaml
# In pipeline, reference as:
url: ((slack-webhook-url))

# Concourse will fetch from Vault automatically
```

## 🎯 Useful Emojis for Notifications (Slack)

| Emoji | Code | Use Case |
|-------|------|----------|
| ✅ | `:white_check_mark:` | Success |
| ❌ | `:x:` | Failure |
| 🚀 | `:rocket:` | Deployment |
| 🎉 | `:tada:` | Production release |
| ⚠️ | `:warning:` | Warning |
| 🚨 | `:rotating_light:` | Critical alert |
| 🔧 | `:wrench:` | Maintenance |
| 📦 | `:package:` | Build |
| 🧪 | `:test_tube:` | Tests |
| ⏪ | `:rewind:` | Rollback |
| 🔄 | `:arrows_counterclockwise:` | Retry |
| 📊 | `:bar_chart:` | Metrics |

## 🆘 Getting Help

```bash
# Concourse help
fly -h
fly set-pipeline -h
fly trigger-job -h

# Check Concourse version
fly -t docker-local sync

# View workers
fly -t docker-local workers

# View containers
fly -t docker-local containers

# View volumes
fly -t docker-local volumes
```
