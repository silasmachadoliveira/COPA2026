variable "create_resource_group" {
  type    = bool
  default = true
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "vnet_address_space" {
  type = string
}

variable "subnets" {
  type        = map(string)
  description = "Map of subnet name => CIDR"
}

variable "nsg_name" {
  type = string
}

variable "nsg_rules" {
  type = map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
