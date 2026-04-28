### Hexlet tests and linter status:
[![Actions Status](https://github.com/MamBoota/devops-for-developers-project-76/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/MamBoota/devops-for-developers-project-76/actions)

## Deploy Redmine with Ansible

This repository contains an Ansible setup for deploying Redmine to two app servers
behind a load balancer.

### Prerequisites

- Three Ubuntu servers accessible over SSH (`app-1`, `app-2`, `db-1`)
- Optional fourth Ubuntu server for local load balancer (`lb-1`)
- Ansible installed on local machine

### 1. Install dependencies

```bash
make install
```

### 2. Prepare inventory and variables

Copy example files and fill them with your infrastructure values:

```bash
cp inventory/hosts.ini.example inventory/hosts.ini
cp group_vars/all.yml.example group_vars/all.yml
```

Set:
- server IPs and SSH key path in `inventory/hosts.ini`
- DB host, DB port, DB credentials in `group_vars/all.yml`

### 3. Check connectivity

```bash
make ping-all
```

### 4. Deploy database host (db-1)

```bash
make deploy-db
```

### 5. Deploy Redmine app hosts (app-1/app-2)

```bash
make deploy
```

### 6. Deploy load balancer host (lb-1)

```bash
make deploy-lb
```

Or run full infrastructure deployment in one command:

```bash
make deploy-all
```

After successful deployment, each server runs Redmine in Docker and listens on port `80`.
Nginx load balancer proxies requests to both app hosts.
Open `http://<lb-1-ip>/` to access the service through the balancer.
Playbook also performs post-deploy checks on each server:
- waits until Redmine port is reachable
- calls `http://127.0.0.1/` and expects HTTP `200`, `301`, or `302`

### Additional commands

```bash
make syntax-check
make lint
```

### Project structure

- `playbook.yml` — entry point for deployment
- `playbook-db.yml` — PostgreSQL setup for Redmine database
- `playbook-lb.yml` — Nginx load balancer setup
- `site.yml` — full deployment (database + app + load balancer)
- `roles/redmine/tasks/main.yml` — Docker install and container deployment
- `roles/redmine/templates/redmine.env.j2` — container environment file template
- `roles/postgresql/tasks/main.yml` — PostgreSQL installation and DB initialization
- `roles/loadbalancer/tasks/main.yml` — Nginx installation and reverse proxy setup
- `Makefile` — shortcuts for install, ping, deploy, lint, syntax check
- `.ansible-lint` — linter configuration
- `inventory/hosts.ini.example` — inventory example
- `group_vars/all.yml.example` — project variables example