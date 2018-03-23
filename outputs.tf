output "private_ip" {
  value = "${scaleway_server.server.0.private_ip}"
}

output "public_ip" {
  value = "${scaleway_server.server.0.public_ip}"
}

# data "local_file" "unseal_key_01" {
#   filename = "${path.module}/helpers/outputs/unseal_key_01"
# }

# data "local_file" "unseal_key_02" {
#   filename = "${path.module}/helpers/outputs/unseal_key_02"
# }

# data "local_file" "unseal_key_03" {
#   filename = "${path.module}/helpers/outputs/unseal_key_03"
# }

# data "local_file" "unseal_key_04" {
#   filename = "${path.module}/helpers/outputs/unseal_key_04"
# }

# data "local_file" "unseal_key_05" {
#   filename = "${path.module}/helpers/outputs/unseal_key_05"
# }

# data "local_file" "root_token" {
#   filename = "${path.module}/helpers/outputs/root_token"
# }

# output "unseal_key_01" {
#   value     = "${data.local_file.unseal_key_01.content}"
#   sensitive = true
# }

# output "unseal_key_02" {
#   value     = "${data.local_file.unseal_key_02.content}"
#   sensitive = true
# }

# output "unseal_key_03" {
#   value     = "${data.local_file.unseal_key_03.content}"
#   sensitive = true
# }

# output "unseal_key_04" {
#   value     = "${data.local_file.unseal_key_04.content}"
#   sensitive = true
# }

# output "unseal_key_05" {
#   value     = "${data.local_file.unseal_key_05.content}"
#   sensitive = true
# }

# output "root_token" {
#   value     = "${data.local_file.root_token.content}"
#   sensitive = true
# }

data "local_file" "cluster_token" {
  filename = "${var.output_path}/cluster_token"
}

output "cluster_token" {
  value = "${data.local_file.cluster_token.content}"
}

data "local_file" "nomad_token" {
  filename = "${var.output_path}/nomad_token"
}

output "nomad_token" {
  value     = "${data.local_file.nomad_token.content}"
  sensitive = true
}
