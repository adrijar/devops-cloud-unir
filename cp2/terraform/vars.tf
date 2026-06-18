# vars.tf
# Declaracion de variables de entrada para Terraform.
# Caso Practico 2 - DevOps & Cloud - UNIR

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID. Se inyecta via la variable de entorno ARM_SUBSCRIPTION_ID."
}

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