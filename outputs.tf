output "private_ip" {
  value = "${scaleway_server.server.0.private_ip}"
}

output "public_ip" {
  value = "${scaleway_server.server.0.public_ip}"
}
