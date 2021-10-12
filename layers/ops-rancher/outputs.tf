output "access-key" {
  value     = module.rancher-bootstrap.access-key
  sensitive = true
}

output "secret-key" {
  value     = module.rancher-bootstrap.secret-key
  sensitive = true
}