# recursos.tf
# Definicion de los recursos de Azure: Resource Group y ACR.
# Caso Practico 2 - DevOps & Cloud - UNIR

# ============================================================
# Resource Group: contenedor logico de todos los recursos
# ============================================================
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.prefix}"
  location = var.location
  tags     = var.tags
}

# ============================================================
# Sufijo aleatorio: garantiza unicidad global del nombre del ACR
# ============================================================
resource "random_string" "acr_suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# ============================================================
# Azure Container Registry: registry privado de imagenes
# ============================================================
# 
# - admin_enabled = false: no usaremos credenciales admin.
#   La autenticacion se hara mediante Managed Identity (VM y AKS).
resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}acr${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

# ============================================================
# Outputs: valores expuestos al usuario tras `terraform apply`
# ============================================================
output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Nombre del resource group creado."
}

output "acr_name" {
  value       = azurerm_container_registry.acr.name
  description = "Nombre del Azure Container Registry."
}

output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "Servidor de login del ACR (URL para podman/docker login)."
}
