#!/bin/bash
# deploy.sh
# Caso Practico 2 - DevOps & Cloud - UNIR
# Ejecuta el playbook de Ansible para configurar la VM y desplegar Nginx

cd "$(dirname "$0")"
ansible-playbook -i hosts playbook.yml
