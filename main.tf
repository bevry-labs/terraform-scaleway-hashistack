# Web Ports:
#   [80, 443]
# Consul Ports:
#   https://www.consul.io/docs/agent/options.html#ports-used
# Docker Ports:
#   https://stackoverflow.com/a/43404044/130638
#   => [2375, 2376, 2377, 5000, 4789, 7946]
#   https://forums.docker.com/t/docker-ports-in-aws-ec2/15799
#   => however, they should not be opened as they are a security risk
locals {
  loopback_ip            = "127.0.0.1"
  docker_types           = "${map("slave", "present")}"
  docker_type            = "${lookup(local.docker_types, var.type, "")}"
  consul_user            = "root"
  consul_group           = "root"
  consul_version         = "1.0.7"
  consul_types           = "${map("origin", "origin", "master", "master", "slave", "slave")}"
  consul_type            = "${lookup(local.consul_types, var.type, "")}"
  consul_ports_local     = [8301, 8302, 8600]
  consul_ports_local_tcp = [8300, 8500]
  consul_ports_local_udp = []
  nomad_user             = "nomad_user"
  nomad_group            = "nomad_user"
  nomad_version          = "0.8.1"
  nomad_types            = "${map("master", "master", "slave", "slave")}"
  nomad_type             = "${lookup(local.nomad_types, var.type, "")}"
  nomad_ports_local      = []
  nomad_ports_local_tcp  = "${compact(split(" ", local.nomad_type == "" ? "" : "4646 4647 4648"))}"
  nomad_ports_local_udp  = []
  vault_user             = "vault_user"
  vault_group            = "vault_user"
  vault_version          = "0.10.1"
  vault_types            = "${map("origin", "origin")}"
  vault_type             = "${lookup(local.vault_types, var.type, "")}"
  vault_ports_local      = []
  vault_ports_local_tcp  = "${compact(split(" ", local.vault_type == "" ? "" : "8200 8201"))}"
  vault_ports_local_udp  = []
  ports_local            = "${concat(local.consul_ports_local, local.nomad_ports_local, local.vault_ports_local)}"
  ports_local_tcp        = "${distinct(concat(local.ports_local, local.consul_ports_local_tcp, local.nomad_ports_local_tcp, local.vault_ports_local_tcp))}"
  ports_local_udp        = "${distinct(concat(local.ports_local, local.consul_ports_local_udp, local.nomad_ports_local_udp, local.vault_ports_local_udp))}"

  tags_string = "cluster cluster_${var.type} ${local.vault_type != "" ? "vault vault_${local.vault_type}" : ""} ${local.consul_type != "" ? "consul consul_${local.consul_type}" : ""} ${local.nomad_type != "" ? "nomad nomad_${local.nomad_type}" : ""} ${local.docker_type != "" ? "docker docker_${local.docker_type}" : ""}"
  tags_array  = "${split(" ", local.tags_string)}"
  tags        = "${compact(local.tags_array)}"
}

# =====================================
# Security Groups

resource "scaleway_security_group" "cluster" {
  name                    = "${var.region}_${var.type}"
  description             = "${var.type} cluster security group"
  enable_default_security = false
}

# Provision Server
# public_ip           = "${element(scaleway_ip.public_ip.*.ip, count.index)}"
resource "scaleway_server" "server" {
  count               = "${var.count}"
  name                = "${var.region}_${var.type}_${count.index}"
  image               = "${var.image}"
  bootscript          = "${var.bootscript}"
  security_group      = "${scaleway_security_group.cluster.id}"
  type                = "ARM64-2GB"
  state               = "${var.state}"
  enable_ipv6         = false
  dynamic_ip_required = true
  tags                = "${local.tags}"

  provisioner "local-exec" {
    command = "chmod +x ${path.module}/helpers/scripts/*"
  }

  provisioner "local-exec" {
    command = "${path.module}/helpers/scripts/local_prepare ${var.data_path} ${var.region}_${var.type}_${count.index} ${var.type}"
  }

  provisioner "local-exec" {
    command = "${path.module}/helpers/scripts/config_write ${var.data_path}/${var.region}_${var.type}_${count.index}/input tls_mode=${var.tls_mode} consul_user=${local.consul_user} consul_group=${local.consul_group} vault_user=${local.vault_user} vault_group=${local.vault_group} nomad_user=${local.nomad_user} nomad_group=${local.nomad_group} hostname=${var.hostname} private_key_path=${var.private_key_path} ports_local_tcp=${join(",", local.ports_local_tcp)} ports_local_udp=${join(",", local.ports_local_udp)} consul_version=${local.consul_version} consul_type=${local.consul_type} nomad_version=${local.nomad_version} nomad_type=${local.nomad_type} vault_version=${local.vault_version} vault_type=${local.vault_type} docker_type=${local.docker_type} name=${var.region}_${var.type}_${count.index} count=${var.count} join=${var.join} loopback_ip=${local.loopback_ip} type=${var.type} region=${var.region} private_ip=${self.private_ip} public_ip=${self.public_ip} "
  }

  provisioner "local-exec" {
    command = "${path.module}/helpers/scripts/local_begin ${var.data_path}/${var.region}_${var.type}_${count.index}"
  }

  connection {
    type        = "ssh"
    user        = "root"
    timeout     = "180s"
    private_key = "${file("${var.private_key_path}")}"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sysctl kernel.hostname=${var.region}_${var.type}_${count.index}",
      "rm -Rf /root/cluster",
      "mkdir -p /root/cluster /root/cluster/scripts /root/cluster/data",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/helpers/scripts/"
    destination = "/root/cluster/scripts"
  }

  provisioner "file" {
    source      = "${var.data_path}/${var.region}_${var.type}_${count.index}/"
    destination = "/root/cluster/data"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/cluster/scripts/*",
      "/root/cluster/scripts/remote_begin",
    ]
  }

  provisioner "local-exec" {
    command = "${path.module}/helpers/scripts/local_end ${var.data_path}/${var.region}_${var.type}_${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "/root/cluster/scripts/remote_end",
    ]
  }
}
