variable "vm_name" {
  type = string
}

variable "computer_name" {
  type    = string
  default = ""
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_B2als_v2"
}

variable "os_type" {
  type        = string
  description = "windows or linux"
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "public_ip_name" {
  type = string
}

variable "disk_type" {
  type    = string
  default = "StandardSSD_LRS"
}

variable "disk_size_gb" {
  type    = number
  default = 50
}

variable "hotpatch_enabled" {
  type    = bool
  default = false
}

variable "sql_enabled" {
  type    = bool
  default = false
}

variable "sql_disk_size_gb" {
  type    = number
  default = 8
}

variable "image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}
