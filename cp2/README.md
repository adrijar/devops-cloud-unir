# Caso Practico 2 — Automatizacion de despliegues en entornos Cloud

> Asignatura: **DevOps & Cloud** — Master Universitario en DevOps & Cloud
> Universidad Internacional de La Rioja (UNIR)
> Autor: Adrian Simon Rivas

---

## Descripcion

Despliegue automatizado de una arquitectura cloud sobre **Microsoft Azure**:

1. **Azure Container Registry (ACR)** privado con dos imagenes de contenedor.
2. **Maquina virtual Linux** con servidor web Nginx en Podman (HTTPS + auth basica).
3. **Azure Kubernetes Service (AKS)** con un nodo worker.
4. **WordPress con MySQL** y almacenamiento persistente sobre AKS.

Herramientas: **Terraform** (infraestructura) y **Ansible** (configuracion y despliegue).

---

## Estructura del repositorio

    cp2/
    ├── deploy-all.sh              # Script de despliegue one-click
    ├── README.md
    ├── LICENSE                     # Licencia MIT
    ├── .gitignore
    │
    ├── terraform/                  # Infraestructura como Codigo
    │   ├── main.tf                # Provider azurerm
    │   ├── vars.tf                # Variables de entrada
    │   └── recursos.tf            # Todos los recursos de Azure
    │
    ├── ansible/                   # Configuracion y despliegue
    │   ├── playbook.yml           # Configura VM con Podman + Nginx
    │   ├── aks-wordpress.yml      # Despliega WordPress en AKS
    │   └── deploy.sh             # Ejecucion individual del playbook VM
    │
    ├── kubernetes/                # Manifiestos de Kubernetes
    │   ├── namespace.yml
    │   ├── mysql-secret.yml
    │   ├── mysql-pvc.yml
    │   ├── mysql-deployment.yml
    │   ├── wordpress-pvc.yml
    │   └── wordpress-deployment.yml
    │
    └── images/                    # Definiciones de imagenes de contenedor
        ├── web-podman-nginx/      # Nginx con HTTPS y auth basica
        │   ├── Dockerfile
        │   ├── nginx.conf
        │   ├── index.html
        │   └── README.md
        └── web-aks-wordpress/     # WordPress para AKS
            ├── Dockerfile
            └── README.md

---

## Requisitos previos

- Azure CLI 2.60+
- Terraform 1.9+
- Ansible 2.12+ (con colecciones: containers.podman, community.general, kubernetes.core)
- Podman 4.0+
- kubectl 1.28+
- Python 3 con pip
- Par de claves SSH (por defecto ~/.ssh/cp2_key)

---

## Despliegue

### 1. Clonar el repositorio

    git clone https://github.com/adrijar/devops-cloud-unir.git
    cd devops-cloud-unir/cp2

### 2. Autenticarse en Azure

    az login --use-device-code
    export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

### 3. Configurar la clave SSH

Crear el fichero `terraform/terraform.tfvars` con la clave publica SSH:

    cat > terraform/terraform.tfvars << 'TFVARS'
    ssh_public_key = "ssh-ed25519 AAAA... tu-clave-publica"
    TFVARS

### 4. Ejecutar el despliegue completo

    ./deploy-all.sh

El script ejecuta automaticamente:

1. `terraform apply` — crea ACR, VM, red, AKS.
2. `podman build + push` — construye y sube las dos imagenes al ACR.
3. `ansible-playbook playbook.yml` — configura la VM con Podman y Nginx.
4. `az aks get-credentials` — configura kubectl.
5. `ansible-playbook aks-wordpress.yml` — despliega WordPress en AKS.

Tiempo estimado: 15-20 minutos.

### 5. Verificar

Al finalizar, el script muestra las URLs de acceso:

- **Nginx (VM)**: https://<IP_VM> (usuario: admin, contrasena: casopractico2)
- **WordPress (AKS)**: http://<IP_LOADBALANCER>

---

## Destruir la infraestructura

    cd terraform
    terraform destroy -auto-approve

---

## Aplicaciones desplegadas

### Nginx (VM con Podman)

Servidor web Nginx 1.27 sobre Alpine Linux, ejecutado como contenedor
Podman gestionado por systemd. Incluye certificado x.509 autofirmado
y autenticacion basica (htpasswd con bcrypt).

### WordPress (AKS)

WordPress 6.4 con PHP 8.2 sobre Apache, conectado a MySQL 8.0.
Ambos con almacenamiento persistente mediante PersistentVolumeClaims
con la StorageClass `managed-csi` de AKS.

---

## Licencia

Licencia **MIT**. Ver fichero `LICENSE`.
