variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "sql_admin_username" {
  type    = string
  default = "adminsql"
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "domain" {
  type    = string
  default = "silasmachado.cloud"
}

variable "my_ip" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
  default = {
    Evento   = "CopaAzure2026"
    Etapa    = "Modernizacao"
    Trilha   = "Tickets"
    Ambiente = "16-Avos-Final"
  }
}
