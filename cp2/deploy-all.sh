#!/bin/bash
# deploy-all.sh
# Caso Practico 2 - DevOps & Cloud - UNIR
#
# Script de despliegue completo. Ejecuta en orden:
#   1. Terraform apply (crea la infraestructura en Azure)
#   2. Build y push de las imagenes al ACR
#   3. Genera el inventario de Ansible con los outputs de Terraform
#   4. Ejecuta el playbook de Ansible contra la VM
#
# Requisitos en la maquina del evaluador:
#   - az login realizado previamente
#   - ARM_SUBSCRIPTION_ID exportado
#   - terraform, podman, ansible instalados
#   - Clave SSH configurada en terraform/terraform.tfvars
#
# Uso:
#   cd cp2
#   ./deploy-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"
ANSIBLE_DIR="$SCRIPT_DIR/ansible"
IMAGES_DIR="$SCRIPT_DIR/images"

echo "=============================================="
echo " Caso Practico 2 - Despliegue completo"
echo " DevOps & Cloud - UNIR"
echo "=============================================="
echo ""

# -----------------------------------------------
# Paso 1: Terraform apply
# -----------------------------------------------
echo "=== Paso 1/4: Creando infraestructura con Terraform ==="
cd "$TERRAFORM_DIR"
terraform init -input=false
terraform apply -auto-approve
echo ""

# Leer outputs
ACR_NAME=$(terraform output -raw acr_name)
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
ACR_USERNAME=$(terraform output -raw acr_admin_username)
ACR_PASSWORD=$(terraform output -raw acr_admin_password)
VM_IP=$(terraform output -raw vm_public_ip)

echo "   ACR:  $ACR_LOGIN_SERVER"
echo "   VM:   $VM_IP"
echo ""

# -----------------------------------------------
# Paso 2: Build y push de imagenes al ACR
# -----------------------------------------------
echo "=== Paso 2/4: Construyendo y subiendo imagenes al ACR ==="

echo "$ACR_PASSWORD" | podman login "$ACR_LOGIN_SERVER" \
  --username "$ACR_USERNAME" \
  --password-stdin

echo "   Construyendo web-podman-nginx..."
podman build -t "$ACR_LOGIN_SERVER/web-podman-nginx:casopractico2" \
  "$IMAGES_DIR/web-podman-nginx/"

echo "   Construyendo web-aks-wordpress..."
podman build -t "$ACR_LOGIN_SERVER/web-aks-wordpress:casopractico2" \
  "$IMAGES_DIR/web-aks-wordpress/"

echo "   Subiendo web-podman-nginx..."
podman push "$ACR_LOGIN_SERVER/web-podman-nginx:casopractico2"

echo "   Subiendo web-aks-wordpress..."
podman push "$ACR_LOGIN_SERVER/web-aks-wordpress:casopractico2"
echo ""

# -----------------------------------------------
# Paso 3: Generar inventario de Ansible
# -----------------------------------------------
echo "=== Paso 3/4: Generando inventario de Ansible ==="

cat > "$ANSIBLE_DIR/hosts" <<HOSTS
# Inventario generado automaticamente por deploy-all.sh
# $(date)

[vm]
$VM_IP ansible_user=azureadmin ansible_ssh_private_key_file=~/.ssh/cp2_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[vm:vars]
acr_login_server=$ACR_LOGIN_SERVER
acr_username=$ACR_USERNAME
acr_password=$ACR_PASSWORD
HOSTS

echo "   Inventario generado en ansible/hosts"
echo ""

# -----------------------------------------------
# Paso 4: Ejecutar Ansible
# -----------------------------------------------
echo "=== Paso 4/4: Configurando VM con Ansible ==="
echo ""

# Esperar a que la VM acepte SSH
echo "   Esperando a que la VM acepte conexiones SSH..."
for i in $(seq 1 30); do
  if ssh -i ~/.ssh/cp2_key -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
     azureadmin@"$VM_IP" "echo ok" >/dev/null 2>&1; then
    echo "   VM lista."
    break
  fi
  echo "   Intento $i/30..."
  sleep 10
done

cd "$ANSIBLE_DIR"
ansible-playbook -i hosts playbook.yml

echo ""
echo "=============================================="
echo " Despliegue completado"
echo "=============================================="
echo ""
echo " Nginx (VM):     https://$VM_IP"
echo " Credenciales:   admin / casopractico2"
echo ""
echo " ACR:            $ACR_LOGIN_SERVER"
echo " SSH:            ssh -i ~/.ssh/cp2_key azureadmin@$VM_IP"
echo "=============================================="
