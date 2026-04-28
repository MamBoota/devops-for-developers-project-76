SHELL := /bin/bash

.PHONY: install ping ping-all deploy deploy-db deploy-lb deploy-all lint syntax-check

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
