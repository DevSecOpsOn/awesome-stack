# Awesome Stack

[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)

![logo](https://raw.githubusercontent.com/docker-library/docs/471fa6e4cb58062ccbf91afc111980f9c7004981/swarm/logo.png)

> A curated list of Docker Stack ready to use

# Motivation

Awesome-stack follows the [awesome-compose](https://github.com/docker/awesome-compose) concept but focus on `docker swarm` and `docker stack` instead of _docker-compose_.

Main goal is to have a closer **cluster concept** for DevOps, DevSecOps, SRE and other teams.

## Pre-requisites

Make sure you have docker and docker desktop installed

1. [Docker CE](https://docs.docker.com/get-started/get-docker/) - Docker is an open platform for developing, shipping, and running applications.

* Once you have met all above requisites move forward to documentation section

### Documentation

---

- [Setup](docs/setup.md) - How to setup and prepare your local environment with necessary tools
- [Deploying](docs/deploy.md) - How to deploy awesome-stacks in a simple way via `make deploy` or `make devops`
- [Encrypting](docs/age.md) - How to encrypt sensitive data e.g: passwords, tokens, secrets with age tool


### Docker Stack applications with multiple integrated services

---

- [atuin](atuin) - Sync, search and backup shell history with Atuin.
- [consul](consul) - is a service networking solution that enables teams to manage secure network connectivity between services, across on-prem, hybrid cloud, and multi-cloud environments and runtimes.
- [db = adminer + mysql + postgres](db) - Adminer, MySQL and PostgreSQL stack
- [droneci + postgres](droneci) - Drone is a self-service Continuous Integration platform for busy development teams.
- [flask](flask) -  is an extension for Flask that adds support for quickly building REST APIs with huge flexibility around the JSONAPI 1.0 specification.
- [gitea + postgres](gitea) - easiest, fastest, and most painless way of setting up a self-hosted Git service.
- [gitness/harness + postgres](harness) - all-in-one platform that integrates source code management, CI/CD pipelines, hosted development environments, and artifact management.
- [gocd + postgres](gocd) - an open-source Continuous Integration and Continuous Delivery system.
- [gogs + postgres](gogs) - Gogs is a painless self-hosted Git service.
- [haproxy](haproxy) - Fast and reliable load balancing for UDP, QUIC, and TCP/HTTP traffic with one powerful solution.
- [jenkins](jenkins) - open source automation server which can be used to automate all sorts of tasks related to building, testing, and delivering or deploying software
- [localstack](localstack) - a cloud service emulator that runs in a single container on your laptop or in your CI environment.
- [mongodb](mongodb) - a source-available, cross-platform, document-oriented database program. Classified as a NoSQL database product
- [nginx](nginx) - HTTP web server, reverse proxy, content cache, load balancer, TCP/UDP proxy server, and mail proxy server.
- [ngrok](ngrok) - ngrok is your app's front door. ngrok is a globally distributed
reverse proxy
 that secures, protects and accelerates your applications and network services, no matter where you run them. ngrok supports delivering HTTP, TLS or TCP-based applications.
- [openstack](openstack) - OpenStack is a set of software components that provide common services for cloud infrastructure.
- [portainer](portainer) - Effortless Container Management for Kubernetes, Docker and Podman · Portainer is a universal container management platform.
- [prometheus + grafana](prometheus) - An open-source monitoring system with a dimensional data model, flexible query language, efficient time series database and modern alerting approach.
- [teamcity + postgres](teamcity) - powerful Continuous Integration and Deployment tool for Developers and DevOps Engineers.
- [traefik](traefik) - Cloud-native, GitOps-driven API runtime solutions for demanding DevOps and Platform Engineers with diverse use-cases, environments, and deployment models.
- [vault + consul](vault) - Secure, store, and tightly control access to tokens, passwords, certificates, encryption keys for protecting secrets, and other sensitive data using a UI, CLI, or HTTP API.
- [webhookrelay](webhookrelay) - Webhook Relay is a secure tunneling solution that provides: Webhook Forwarding &Bidirectional Tunnelling.

### Docker Stack single service (non integrated)

- [haproxy](haproxy)
- [linkerd](linkerd)
- [localstack](localstack)
- [nginx](nginx)
- [mongodb](mongodb)
- [traefik](traefik)

### Getting started

Run below command to setup your local environment with docker swarm cluster, docker network, docker secret and deploy essential stack(s).

```sh
make setup
```

For DevOps/DevSecOps/SRE tools run bellow command to deploy all stacks defined in `DEVOPS` variable.

```sh
make devops
```

---

### Work in progress

Below stack list still working progress mode.

- [concourse](concurse) - Centered around the simple mechanics of resources, tasks, and jobs, Concourse delivers a versatile approach to automation that excels at CI/CD.
- [elastic](elastic) -
- [linkerd](linkerd) - is a service mesh for Kubernetes. It makes running services easier and safer by giving you runtime debugging, observability, reliability, and security.

### Contribute

---

You are welcome to contribute and share new stack(s). Please check the [Contribution Guide](CONTRIBUTE.md) for more details.

`Fork me!` 🥰 🚀
