# Hashistack on Scaleway

[Terraform](https://www.terraform.io) module to deploy [Consul](https://www.consul.io), [Nomad](https://www.nomadproject.io), [Vault](https://www.vaultproject.io) onto [Scaleway](https://www.scaleway.com)

## Benefits

- [x] sets up a consul, vault, nomad, docker cluster for you
- [x] configures scaleway and centos firewalls correctly for you
- [ ] configures TLS certificates for you

## Todo

Necessary:

- [x] abstract out from private repo
- [ ] ensure abstraction works

Nice to have:

- [ ] streamline master, origin, slave configuration exchange
- [ ] streamline setting of nomad token
- [ ] streamline variable setting, perhaps use jq with a json file instead

## Preparation

If you are using MacOS, you will need to do the following:

``` bash
brew install coreutils
```

## Configuration

``` hcl
data "scaleway_image" "centos" {
  architecture = "arm64"
  name         = "CentOS 7.3"
}

data "scaleway_bootscript" "centos" {
  architecture = "arm64"
  name_filter  = "mainline 4.14"
}

locals {
  output_path      = "${path.root}/data"
  private_key_path = "${path.root}/.ssh/scaleway"
  region           = "par1"
  image            = "${data.scaleway_image.centos.id}"
  bootscript       = "${data.scaleway_bootscript.centos.id}"
}

provider "scaleway" {
  region = "${local.region}"
}
```

Configure `private_key_path` to be the ssh private key you are using for scaleway

## Usage

``` hcl
# Origin Server
# Creates consul server + vault server
# Initialises consul
# Initialises vault
# Generates nomad vault configuration
# Generates TLS certificates via vault pki
# Restarts nomad and vault with TLS
module "par1_cluster_origin" {
  source = "bevry/hashistack/scaleway"

  providers = {
    scaleway = "scaleway"
  }

  image             = "${local.image}"
  bootscript        = "${local.bootscript}"
  output_path       = "${local.output_path}"
  private_key_path  = "${local.private_key_path}"
  region            = "${local.region}"
  type              = "origin"
  count             = 1
}

# Master Server
# Creates consul server + nomad server
module "par1_cluster_master" {
  source = "bevry/hashistack/scaleway"

  providers = {
    scaleway = "scaleway"
  }

  image            = "${local.image}"
  bootscript       = "${local.bootscript}"
  output_path      = "${local.output_path}"
  private_key_path = "${local.private_key_path}"
  region           = "${local.region}"
  type             = "master"
  count            = 2
  join             = "${module.cluster_origin.private_ip}"
  nomad_token      = "${module.cluster_origin.nomad_token}"
}

# Slave Server
# Creates consul agent + docker + nomad agent
module "par1_cluster_slave" {
  source = "bevry/hashistack/scaleway"

  providers = {
    scaleway = "scaleway"
  }

  image             = "${local.image}"
  bootscript        = "${local.bootscript}"
  output_path       = "${local.output_path}"
  private_key_path  = "${local.private_key_path}"
  region            = "${local.region}"
  type              = "slave"
  count             = 2
  join              = "${module.cluster_origin.private_ip}"
  nomad_token       = "${module.cluster_origin.nomad_token}"
}
```


## Debugging

If you need to debug DNS:

``` bash
sudo yum install -y net-tools # ifconfig
sudo yum install -y bind-utils # dig
dig consul.service.consul
dig @127.0.0.1 -p 8600 consul.service.consul SRV
```

<!-- LICENSE/ -->

## License

Unless stated otherwise all works are:

- Copyright &copy; 2018+ [Benjamin Lupton](https://balupton.com)

and licensed under:

- [MIT License](http://spdx.org/licenses/MIT.html)

<!-- /LICENSE -->
