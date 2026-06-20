variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "tags" {
  type = map(string)
  default = {
    Etapa = "Eliminatorias"
  }
}

variable "admin_username" {
  type    = string
  default = "admincopauser"
}

variable "admin_password" {
  type      = string
  sensitive = true
}
