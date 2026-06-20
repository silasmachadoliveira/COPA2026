variable "subscription_id" {
  type = string
}

variable "admin_username" {
  type    = string
  default = "tftecadmin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "sql_admin_username" {
  type    = string
  default = "adminsql"
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "my_ip" {
  type        = string
  description = "Seu IP publico para regra RDP"
}

variable "tags" {
  type = map(string)
  default = {
    Evento = "CopaAzure2026"
    Etapa  = "FaseGrupos"
    Trilha = "Tickets"
  }
}
