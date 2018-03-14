# https://github.com/nicolai86/scaleway-terraform-demo/blob/master/main.tf
# https://github.com/nicolai86/scaleway-terraform-demo/blob/master/modules/consul/main.tf
# https://github.com/nicolai86/scaleway-terraform-demo/blob/master/modules/nomad/main.tf
# https://github.com/hashicorp/terraform-aws-consul/blob/master/modules/install-consul/install-consul
# https://www.consul.io/docs/agent/options.html?#ports-used
# https://www.consul.io/docs/agent/options.html#scaleway

# Variables
variable "ssh_private_key" {
  type = "string"
}

variable "type" {
  type = "string" # origin, master, slave
}

variable "count" {
  type    = "string"
  default = 1
}

variable "join" {
  type    = "string"
  default = ""
}

variable "region" {
  type = "string"
}

variable "image" {
  type = "string"
}

variable "bootscript" {
  type    = "string"
  default = ""
}

variable "consul_expect" {
  type    = "string"
  default = 0
}

variable "nomad_expect" {
  type    = "string"
  default = 0
}

variable "nomad_token" {
  type    = "string"
  default = ""
}

# Config
# https://www.consul.io/docs/agent/options.html#ports-used
# https://stackoverflow.com/a/43404044/130638
# https://forums.docker.com/t/docker-ports-in-aws-ec2/15799
# web_ports = [443]
locals {
  loopback_ip            = "127.0.0.1"
  docker_type            = "${var.type == "slave" ? "present" : ""}"
  consul_version         = "1.0.3"
  consul_url             = "https://releases.hashicorp.com/consul/1.0.3/consul_1.0.3_linux_arm64.zip"
  consul_type            = "${var.type}"
  consul_ports_local     = [8301, 8302, 8600]
  consul_ports_local_tcp = [8300, 8500]
  consul_ports_local_udp = []
  nomad_version          = "0.7.1"
  nomad_url              = "https://releases.hashicorp.com/nomad/0.7.1/nomad_0.7.1_linux_arm64.zip"
  nomad_type             = "${var.type == "origin" ? "" : var.type}"
  nomad_ports_local      = []
  nomad_ports_local_tcp  = "${compact(split(" ", local.nomad_type == "" ? "" : "4646 4647 4648"))}"
  nomad_ports_local_udp  = []
  vault_version          = "0.9.3"
  vault_url              = "https://releases.hashicorp.com/vault/0.9.3/vault_0.9.3_linux_arm64.zip"
  vault_type             = "${var.type == "slave" ? "" : var.type}"
  vault_ports_local      = []
  vault_ports_local_tcp  = "${compact(split(" ", local.vault_type == "" ? "" : "8200"))}"
  vault_ports_local_udp  = []
  ports_local            = "${concat(local.consul_ports_local, local.nomad_ports_local, local.vault_ports_local)}"
  ports_local_tcp        = "${distinct(concat(local.ports_local, local.consul_ports_local_tcp, local.nomad_ports_local_tcp, local.vault_ports_local_tcp))}"
  ports_local_udp        = "${distinct(concat(local.ports_local, local.consul_ports_local_udp, local.nomad_ports_local_udp, local.vault_ports_local_udp))}"

  tags_ = [
    "cluster",
    "cluster-${var.type}",
    "${local.vault_type != "" ? "vault-${local.vault_type}" : ""}",
    "${local.consul_type != "" ? "consul-${local.consul_type}" : ""}",
    "${local.nomad_type != "" ? "nomad-${local.nomad_type}" : ""}",
    "${local.docker_type != "" ? "docker-${local.docker_type}" : ""}",
  ]

  tags = "${compact(local.tags_)}"
}

# security group
resource "scaleway_security_group" "cluster" {
  name        = "${var.region}_${var.type}"
  description = "terraform created security group"
}

resource "scaleway_security_group_rule" "accept-local-inbound-tcp" {
  security_group = "${scaleway_security_group.cluster.id}"

  action    = "accept"
  direction = "inbound"

  ip_range = "10.0.0.0/8"
  protocol = "TCP"
  port     = "${element(local.ports_local_tcp, count.index)}"
  count    = "${length(local.ports_local_tcp)}"
}

resource "scaleway_security_group_rule" "accept-local-inbound-udp" {
  security_group = "${scaleway_security_group.cluster.id}"

  action    = "accept"
  direction = "inbound"

  ip_range = "10.0.0.0/8"
  protocol = "UDP"
  port     = "${element(local.ports_local_udp, count.index)}"
  count    = "${length(local.ports_local_udp)}"
}

resource "scaleway_security_group_rule" "accept-local-outbound-tcp" {
  security_group = "${scaleway_security_group.cluster.id}"

  action    = "accept"
  direction = "outbound"

  ip_range = "10.0.0.0/8"
  protocol = "TCP"
  port     = "${element(local.ports_local_tcp, count.index)}"
  count    = "${length(local.ports_local_tcp)}"
}

resource "scaleway_security_group_rule" "accept-local-outbound-udp" {
  security_group = "${scaleway_security_group.cluster.id}"

  action    = "accept"
  direction = "outbound"

  ip_range = "10.0.0.0/8"
  protocol = "UDP"
  port     = "${element(local.ports_local_udp, count.index)}"
  count    = "${length(local.ports_local_udp)}"
}

# Provision IP
# resource "scaleway_ip" "public_ip" {
#   count = "${var.count}"
# }

# Provision Server
# public_ip           = "${element(scaleway_ip.public_ip.*.ip, count.index)}"
resource "scaleway_server" "server" {
  count               = "${var.count}"
  name                = "${var.region}_${var.type}_${count.index}"
  image               = "${var.image}"
  bootscript          = "${var.bootscript}"
  security_group      = "${scaleway_security_group.cluster.id}"
  type                = "ARM64-2GB"
  state               = "running"
  enable_ipv6         = false
  dynamic_ip_required = true
  tags                = "${local.tags}"

  provisioner "local-exec" {
    command = "${path.module}/helpers/scripts/local-begin ${var.ssh_key_path} ${var.var_dir_path} ${self.public_ip} ${self.private_ip}"
  }

  # https://www.terraform.io/docs/provisioners/connection.html
  connection {
    type        = "ssh"
    user        = "root"
    timeout     = "180s"
    private_key = "${var.ssh_private_key}"
    agent       = false
  }

  # https://www.consul.io/docs/agent/options.html#scaleway
  # https://github.com/hashicorp/nomad/tree/master/terraform
  # https://github.com/hashicorp/consul/blob/master/terraform/digitalocean/consul.tf
  # https://github.com/hashicorp/consul/blob/master/terraform/shared/scripts/install.sh
  # https://github.com/hashicorp/consul/blob/master/terraform/shared/scripts/rhel_consul.service
  provisioner "remote-exec" {
    inline = [
      "sysctl kernel.hostname=${var.region}_${var.type}_${count.index}",
      "rm -Rf /root/cluster",
      "mkdir -p /root/cluster/tmp",
      "mkdir -p /root/cluster/var",
      "echo -n '${join("\n", local.ports_local_tcp)}' > /root/cluster/var/ports_local_tcp",
      "echo -n '${join("\n", local.ports_local_udp)}' > /root/cluster/var/ports_local_udp",
      "echo -n '${local.consul_version}' > /root/cluster/var/consul_version",
      "echo -n '${local.consul_url}' > /root/cluster/var/consul_url",
      "echo -n '${local.consul_type}' > /root/cluster/var/consul_type",
      "echo -n '${var.consul_expect}' > /root/cluster/var/consul_expect",
      "echo -n '${local.nomad_version}' > /root/cluster/var/nomad_version",
      "echo -n '${local.nomad_url}' > /root/cluster/var/nomad_url",
      "echo -n '${local.nomad_type}' > /root/cluster/var/nomad_type",
      "echo -n '${var.nomad_expect}' > /root/cluster/var/nomad_expect",
      "echo -n '${var.nomad_token}' > /root/cluster/var/nomad_token",
      "echo -n '${local.vault_version}' > /root/cluster/var/vault_version",
      "echo -n '${local.vault_url}' > /root/cluster/var/vault_url",
      "echo -n '${local.vault_type}' > /root/cluster/var/vault_type",
      "echo -n '${local.docker_type}' > /root/cluster/var/docker_type",
      "echo -n '${var.region}_${var.type}_${count.index}' > /root/cluster/var/name",
      "echo -n '${var.join}' > /root/cluster/var/join",
      "echo -n '${self.private_ip}' > /root/cluster/var/private_ip",
      "echo -n '${self.public_ip}' > /root/cluster/var/public_ip",
      "echo -n '${local.loopback_ip}' > /root/cluster/var/loopback_ip",
      "echo -n '${var.type}' > /root/cluster/var/type",
      "echo -n '${var.region}' > /root/cluster/var/region",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/helpers/"
    destination = "/root/cluster"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/cluster/scripts/*",
      "/root/cluster/scripts/setup",
    ]
  }

  provisioner "local-exec" {
    command = "${path.module}/helpers/scripts/local-end ${var.ssh_key_path} ${var.var_dir_path}  ${self.public_ip} ${self.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "/root/cluster/scripts/cleanup",
    ]
  }
}

# Outputs
output "private_ip" {
  value = "${scaleway_server.server.0.private_ip}"
}

output "public_ip" {
  value = "${scaleway_server.server.0.public_ip}"
}
