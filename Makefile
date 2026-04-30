SHELL := /bin/bash

DOMAIN ?= myproj76.ru
VPS_IP ?= 168.222.143.207
SSH_KEY ?= /Users/mamboota/.ssh/multipass_ansible
LB_ORIGIN ?= 192.168.2.5:80

.PHONY: install ping ping-all deploy deploy-db deploy-lb deploy-all lint syntax-check run stop status logs test

install:
	ansible-galaxy collection install -r requirements.yml

ping:
	ansible webservers -m ping

ping-all:
	ansible all -m ping

deploy:
	ansible-playbook playbook.yml

deploy-db:
	ansible-playbook playbook-db.yml

deploy-lb:
	ansible-playbook playbook-lb.yml

deploy-all:
	ansible-playbook site.yml

lint:
	ansible-lint playbook.yml playbook-db.yml playbook-lb.yml site.yml

syntax-check:
	ansible-playbook --syntax-check playbook.yml
	ansible-playbook --syntax-check playbook-db.yml
	ansible-playbook --syntax-check playbook-lb.yml
	ansible-playbook --syntax-check site.yml

run:
	@echo "Starting reverse relay tunnel to $(VPS_IP) ..."
	@pkill -f "ssh -i $(SSH_KEY).*root@$(VPS_IP)" 2>/dev/null || true
	@nohup ssh -i "$(SSH_KEY)" \
		-o ExitOnForwardFailure=yes \
		-o ServerAliveInterval=30 \
		-o ServerAliveCountMax=3 \
		-o StrictHostKeyChecking=no \
		-N -R 127.0.0.1:18080:$(LB_ORIGIN) \
		root@$(VPS_IP) >/tmp/vps-relay.log 2>&1 &
	@sleep 2
	@pgrep -fl "ssh -i $(SSH_KEY).*root@$(VPS_IP)" >/dev/null && \
		echo "Relay tunnel is running." || \
		(echo "Relay tunnel failed to start. Check /tmp/vps-relay.log"; exit 1)

stop:
	@echo "Stopping reverse relay tunnel to $(VPS_IP) ..."
	@pkill -f "ssh -i $(SSH_KEY).*root@$(VPS_IP)" 2>/dev/null || true
	@sleep 1
	@if pgrep -fl "ssh -i $(SSH_KEY).*root@$(VPS_IP)" >/dev/null; then \
		echo "Relay tunnel is still running."; \
		exit 1; \
	else \
		echo "Relay tunnel stopped."; \
	fi

status:
	@echo "Relay process:"
	@pgrep -fl "ssh -i $(SSH_KEY).*root@$(VPS_IP)" || echo "not running"
	@echo "Domain check:"
	@curl --max-time 8 -s -o /dev/null -w "https://$(DOMAIN) -> %{http_code}\n" "https://$(DOMAIN)" || true
	@echo "VPS relay check:"
	@curl --max-time 8 -s -o /dev/null -w "http://$(VPS_IP) -> %{http_code}\n" "http://$(VPS_IP)" || true

logs:
	@echo "Last relay logs (/tmp/vps-relay.log):"
	@tail -n 40 /tmp/vps-relay.log 2>/dev/null || echo "no log file"

test:
	@echo "Testing https://$(DOMAIN) ..."
	@echo "Warm-up request ..."
	@curl --max-time 8 -s -o /dev/null "https://$(DOMAIN)" || true
	@sleep 1
	@ok=1; \
	for i in {1..10}; do \
		code=$$(curl --max-time 8 -s -o /dev/null -w "%{http_code}" "https://$(DOMAIN)"); \
		echo "$$i:$$code"; \
		if [[ "$$code" != "200" ]]; then ok=0; fi; \
		sleep 1; \
	done; \
	if [[ $$ok -eq 1 ]]; then \
		echo "PASS: 10/10 responses are HTTP 200"; \
	else \
		echo "FAIL: non-200 response detected"; \
		exit 1; \
	fi