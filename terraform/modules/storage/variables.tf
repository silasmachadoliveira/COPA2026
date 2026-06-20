variable "storage_account_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "account_tier" {
  type    = string
  default = "Standard"
}

variable "replication_type" {
  type    = string
  default = "LRS"
}

variable "allow_blob_public_access" {
  type    = bool
  default = false
}

variable "containers" {
  type        = map(string)
  description = "Map of container name => access_type (private, blob, container)"
  default     = {}
}

variable "file_shares" {
  type        = map(number)
  description = "Map of share name => quota in GB"
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
