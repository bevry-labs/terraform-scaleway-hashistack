output "private_ip" {
  value = "${scaleway_server.server.0.private_ip}"
}

output "public_ip" {
  value = "${scaleway_server.server.0.public_ip}"
}

data "local_file" "nomad_token" {
  filename = "${var.output_path}/nomad_token"
}

output "nomad_token" {
  value     = "${data.local_file.nomad_token.content}"
  sensitive = true
}
