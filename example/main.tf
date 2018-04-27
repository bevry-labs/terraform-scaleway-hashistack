# =====================================
# Variables

variable "hostname" {
  type    = "string"
  default = "bevry.me"
}

variable "region" {
  type    = "string"
  default = "par1"
}

variable "image" {
  type    = "string"
  default = ""
}

variable "bootscript" {
  type    = "string"
  default = ""
}

variable "base_server_status" {
  type    = "string"
  default = "stopped"
}

# =====================================
# Locals

provider "scaleway" {
  region = "${var.region}"
}

data "scaleway_bootscript" "centos" {
  architecture = "arm64"
  name_filter  = "mainline 4.14"
}

data "scaleway_image" "centos" {
  architecture = "arm64"
  name         = "CentOS 7.3"
}

locals {
  image            = "${var.image != "" ? "${var.image}" : "${data.scaleway_image.centos.id}"}"
  bootscript       = "${var.bootscript != "" ? "${var.bootscript}" : "${data.scaleway_bootscript.centos.id}"}"
  data_path        = "${path.root}/data"
  private_key_path = "${path.root}/.ssh/scaleway"
}

# =====================================
# Server: Origin

module "cluster_origin" {
  source = "bevry/hashistack/scaleway"

  providers = {
    scaleway = "scaleway"
  }

  image            = "${local.image}"
  bootscript       = "${local.bootscript}"
  data_path        = "${local.data_path}"
  private_key_path = "${local.private_key_path}"
  region           = "${var.region}"
  hostname         = "${var.hostname}"
  type             = "origin"
  count            = 1
  consul_expect    = 1
}

# =====================================
# Server: Agents

module "par1_cluster_master" {
  source = "bevry/hashistack/scaleway"

  providers = {
    scaleway = "scaleway"
  }

  image            = "${local.image}"
  bootscript       = "${local.bootscript}"
  data_path        = "${local.data_path}"
  private_key_path = "${local.private_key_path}"
  region           = "${var.region}"
  hostname         = "${var.hostname}"
  type             = "master"
  count            = 2
  join             = "${module.cluster_origin.private_ip}"
  consul_expect    = 3
  nomad_expect     = 2
}

module "par1_cluster_slave" {
  source = "bevry/hashistack/scaleway"

  providers = {
    scaleway = "scaleway"
  }

  image            = "${local.image}"
  bootscript       = "${local.bootscript}"
  data_path        = "${local.data_path}"
  private_key_path = "${local.private_key_path}"
  region           = "${var.region}"
  hostname         = "${var.hostname}"
  type             = "slave"
  count            = 2
  join             = "${module.cluster_origin.private_ip}"
}
