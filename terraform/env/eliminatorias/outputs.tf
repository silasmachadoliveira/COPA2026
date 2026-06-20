output "vm_windows_public_ip" {
  value = module.vm_windows.public_ip
}

output "vm_linux_public_ip" {
  value = module.vm_linux.public_ip
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "storage_account_key" {
  value     = module.storage.primary_access_key
  sensitive = true
}
