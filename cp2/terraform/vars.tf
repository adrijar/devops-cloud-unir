# vars.tf
# Declaracion de variables de entrada para Terraform.
# Caso Practico 2 - DevOps & Cloud - UNIR



variable "location" {
  type        = string
  default     = "swedencentral"
  description = "Region de Azure donde se desplegaran los recursos. swedencentral es compatible con cuenta Azure for Students."
}

variable "prefix" {
  type        = string
  default     = "cp2unir"
  description = "Prefijo usado para nombrar todos los recursos del caso practico."
}

variable "tags" {
  type = map(string)
  default = {
    project     = "casopractico2"
    course      = "devops-cloud-unir"
    environment = "academic"
    managed_by  = "terraform"
  }
  description = "Etiquetas que se aplicaran a todos los recursos creados en Azure."
}

# Clave SSH publica que se inyectara en la VM Linux.
# El evaluador debe sobreescribir este valor con su propia clave publica
# creando un fichero terraform.tfvars con:
#   ssh_public_key = "ssh-ed25519 AAAA... su-clave"
variable "ssh_public_key" {
  type        = string
  description = "Clave SSH publica para acceder a la VM Linux."
}

# Nombre de usuario administrador de la VM Linux.
variable "vm_admin_username" {
  type        = string
  description = "Usuario administrador de la VM Linux."
  default     = "azureadmin"
}


