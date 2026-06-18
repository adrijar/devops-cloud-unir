# Caso Practico 2 — Automatizacion de despliegues en entornos Cloud

> Asignatura: **DevOps & Cloud** — Master Universitario en DevOps & Cloud
> Universidad Internacional de La Rioja (UNIR)
> Autor: Adrian Simon Rivas

---

## Descripcion

Este caso practico implementa, mediante un enfoque **Infraestructura como
Codigo** y **Gestion de la Configuracion**, el despliegue automatizado de
una arquitectura cloud sobre **Microsoft Azure** que incluye:

1. Un **Azure Container Registry (ACR)** privado para alojar las imagenes
   de contenedores del proyecto.
2. Una **maquina virtual Linux** que ejecuta un servidor web en contenedor
   con **Podman**, con HTTPS y autenticacion basica.
3. Un cluster gestionado **Azure Kubernetes Service (AKS)** con un nodo
   worker y conectividad nativa con el ACR.
4. Una aplicacion con **almacenamiento persistente** desplegada sobre el
   cluster AKS.

La infraestructura se crea con **Terraform** y la configuracion de los
sistemas y el despliegue de las aplicaciones se realiza con **Ansible**.

---

## Estructura del repositorio

cp2/
├── README.md
├── LICENSE
├── .gitignore
├── terraform/
├── ansible/
├── images/
└── docs/

---

## Requisitos previos

- Azure CLI 2.60+
- Terraform 1.9+
- Ansible 2.12+
- Podman 4.0+
- kubectl 1.28+
- git

Antes de ejecutar Terraform es necesario:

1. Autenticarse con Azure: `az login --use-device-code`
2. Exportar el subscription ID: `export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"`
3. Registrar los resource providers (ContainerRegistry, Compute, Network, ContainerService).
4. Generar el par de claves SSH `~/.ssh/cp2_key`.

---

## Licencia

Este proyecto se distribuye bajo licencia **MIT**. El texto legal oficial
se encuentra en el fichero `LICENSE`.

La licencia MIT permite usar, copiar, modificar, integrar, publicar,
distribuir, sublicenciar y vender el software sin restricciones,
manteniendo el aviso de copyright original.

