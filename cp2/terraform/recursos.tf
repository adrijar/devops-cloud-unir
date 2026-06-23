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
# - admin_enabled = true: usaremos las credenciales generadas por Azure
resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}acr${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
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


# ============================================================
# CAPA 2: Maquina Virtual Linux con Podman
# ============================================================

# Red virtual principal del proyecto
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.prefix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Subred para la VM
resource "azurerm_subnet" "subnet_vm" {
  name                 = "subnet-vm-${var.prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# IP publica estatica para la VM
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "pip-vm-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Security Group: reglas de trafico para la VM
resource "azurerm_network_security_group" "nsg_vm" {
  name                = "nsg-vm-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  # SSH: acceso para Ansible
  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTPS: acceso al servidor web Nginx
  security_rule {
    name                       = "allow-https"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTP: para la redireccion HTTP->HTTPS
  security_rule {
    name                       = "allow-http"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Interfaz de red de la VM
resource "azurerm_network_interface" "nic_vm" {
  name                = "nic-vm-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig-vm"
    subnet_id                     = azurerm_subnet.subnet_vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

# Asociacion del NSG a la interfaz de red
resource "azurerm_network_interface_security_group_association" "nic_nsg_vm" {
  network_interface_id      = azurerm_network_interface.nic_vm.id
  network_security_group_id = azurerm_network_security_group.nsg_vm.id
}

# Maquina Virtual Linux (Ubuntu 22.04 LTS)
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${var.prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2as_v2"
  admin_username      = var.vm_admin_username
  tags                = var.tags

  # Clave SSH para acceso (no contrasenas)
  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.ssh_public_key
  }

  # Interfaz de red creada anteriormente
  network_interface_ids = [azurerm_network_interface.nic_vm.id]

  # Disco del sistema operativo
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Imagen: Ubuntu 22.04 LTS del Marketplace de Azure
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
# ============================================================
# Outputs Capa 2
# ============================================================
output "vm_public_ip" {
  value       = azurerm_public_ip.vm_public_ip.ip_address
  description = "IP publica de la VM para acceso SSH y web."
}

output "vm_admin_username" {
  value       = var.vm_admin_username
  description = "Usuario administrador de la VM."
}

output "ssh_command" {
  value       = "ssh -i ~/.ssh/cp2_key ${var.vm_admin_username}@${azurerm_public_ip.vm_public_ip.ip_address}"
  description = "Comando SSH para conectarse a la VM."
}

# ============================================================
# Outputs adicionales para Ansible
# ============================================================
output "acr_admin_username" {
  value       = azurerm_container_registry.acr.admin_username
  description = "Usuario admin del ACR para login desde la VM."
  sensitive   = true
}

output "acr_admin_password" {
  value       = azurerm_container_registry.acr.admin_password
  description = "Contraseña admin del ACR para login desde la VM."
  sensitive   = true
}
