### Hexlet tests and linter status:
[![Actions Status](https://github.com/MamBoota/devops-for-developers-project-76/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/MamBoota/devops-for-developers-project-76/actions)

## Server Preparation for Deploy

This project prepares `webservers` hosts for application deployment:
- installs `pip` via Ansible Galaxy role
- installs Docker engine via Ansible Galaxy role
- installs Python module `docker` via `pip`

## Current project setup (actual)

Production-like stack for this project is split into two parts:

- Local infrastructure (Multipass on your machine):
  - `app-1`, `app-2` - Redmine app nodes
  - `db-1` - PostgreSQL
  - `lb-1` - Nginx load balancer
- Public relay:
  - external VPS with public IP and Nginx
  - domain `myproj76.ru` points to VPS
  - reverse SSH tunnel forwards VPS traffic to local `lb-1`

### Important limitation

App VMs and DB are local, so they depend on the host device and network:

- if your laptop/PC is off, local VMs are unavailable;
- if reverse tunnel is down, public access from the internet is unavailable;
- internet visibility is provided by relay, but service data plane is still local.

### Prerequisites

- Three Ubuntu servers accessible over SSH (`app-1`, `app-2`, `db-1`)
- Optional fourth Ubuntu server for local load balancer (`lb-1`)
- Ansible installed on local machine

### 1. Install dependencies

```bash
make install
```

### 2. Prepare inventory and variables

Edit `inventory.ini` in the project root and set your two web servers:
- aliases (`web-1`, `web-2`)
- `ansible_host`
- `ansible_user`

Set shared variables in `group_vars/all.yml`.

### 3. Check connectivity

```bash
make ping-all
```

### 4. Prepare servers

```bash
make prepare
```

This command runs root `playbook.yml` with `hosts: all`.

### Additional commands

```bash
make syntax-check
make lint
make prepare
make run
make status
make test
make stop
```

### Public relay commands

- `make run` - start reverse relay tunnel (`Mac -> VPS -> lb-1`)
- `make status` - check relay process and HTTP status codes
- `make test` - run external HTTPS checks for `myproj76.ru`
- `make stop` - stop relay tunnel

### Project structure

- `playbook.yml` — entry point for server preparation (`hosts: all`)
- `inventory.ini` — inventory with `webservers` group
- `group_vars/all.yml` — shared variables
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