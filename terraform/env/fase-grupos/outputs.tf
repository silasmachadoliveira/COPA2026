output "vm_frontend_public_ip" {
  value = module.vm_frontend.public_ip
}

output "vm_backend_public_ip" {
  value = module.vm_backend.public_ip
}

output "vm_data_public_ip" {
  value = module.vm_data.public_ip
}
