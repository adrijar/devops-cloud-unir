#!/bin/bash
# deploy-all.sh
# Caso Practico 2 - DevOps & Cloud - UNIR
#
# Despliegue completo one-click:
#   1. Terraform apply
#   2. Build y push de imagenes al ACR
#   3. Configura VM con Ansible (Nginx en Podman)
#   4. Despliega WordPress en AKS con Ansible
#
# Requisitos:
#   - az login realizado
#   - ARM_SUBSCRIPTION_ID exportado
#   - terraform, podman, ansible, kubectl instalados
#   - Clave SSH en terraform/terraform.tfvars

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"
ANSIBLE_DIR="$SCRIPT_DIR/ansible"
IMAGES_DIR="$SCRIPT_DIR/images"
K8S_DIR="$SCRIPT_DIR/kubernetes"

echo "=============================================="
echo " Caso Practico 2 - Despliegue completo"
echo " DevOps & Cloud - UNIR"
echo "=============================================="
echo ""

# -----------------------------------------------
# Paso 1: Terraform apply
# -----------------------------------------------
echo "=== Paso 1/5: Creando infraestructura con Terraform ==="
cd "$TERRAFORM_DIR"
terraform init -input=false
terraform apply -auto-approve

ACR_NAME=$(terraform output -raw acr_name)
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
ACR_USERNAME=$(terraform output -raw acr_admin_username)
ACR_PASSWORD=$(terraform output -raw acr_admin_password)
VM_IP=$(terraform output -raw vm_public_ip)
AKS_NAME=$(terraform output -raw aks_name)
echo ""

# -----------------------------------------------
# Paso 2: Build y push de imagenes al ACR
# -----------------------------------------------
echo "=== Paso 2/5: Construyendo y subiendo imagenes al ACR ==="

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
# Paso 3: Configurar VM con Ansible (Nginx)
# -----------------------------------------------
echo "=== Paso 3/5: Configurando VM con Ansible ==="

cat > "$ANSIBLE_DIR/hosts" <<HOSTS
[vm]
$VM_IP ansible_user=azureadmin ansible_ssh_private_key_file=~/.ssh/cp2_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[vm:vars]
acr_login_server=$ACR_LOGIN_SERVER
acr_username=$ACR_USERNAME
acr_password=$ACR_PASSWORD
HOSTS

echo "   Esperando a que la VM acepte SSH..."
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

# -----------------------------------------------
# Paso 4: Configurar kubectl para AKS
# -----------------------------------------------
echo "=== Paso 4/5: Configurando kubectl para AKS ==="
az aks get-credentials \
  --resource-group rg-cp2unir \
  --name "$AKS_NAME" \
  --overwrite-existing

kubectl get nodes
echo ""

# -----------------------------------------------
# Paso 5: Desplegar WordPress en AKS
# -----------------------------------------------
echo "=== Paso 5/5: Desplegando WordPress en AKS ==="

# Sustituir el placeholder ACR_LOGIN_SERVER en el manifiesto de WordPress
sed -i "s|ACR_LOGIN_SERVER|$ACR_LOGIN_SERVER|g" "$K8S_DIR/wordpress-deployment.yml"

cd "$ANSIBLE_DIR"
ansible-playbook aks-wordpress.yml

# Restaurar el placeholder para que el repo quede limpio
sed -i "s|$ACR_LOGIN_SERVER|ACR_LOGIN_SERVER|g" "$K8S_DIR/wordpress-deployment.yml"

echo ""
echo "=============================================="
echo " Despliegue completado"
echo "=============================================="
echo ""
echo " Nginx (VM):     https://$VM_IP"
echo " Credenciales:   admin / casopractico2"
echo ""
echo " WordPress (AKS): ejecutar 'kubectl get svc -n wordpress'"
echo "                   para obtener la IP del LoadBalancer"
echo ""
echo " ACR:            $ACR_LOGIN_SERVER"
echo " SSH:            ssh -i ~/.ssh/cp2_key azureadmin@$VM_IP"
echo "=============================================="
