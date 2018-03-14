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

## Configuration

``` hcl
locals {
  var_dir_path = "${path.root}/private/var"
  ssh_key_path = "${path.root}/private/ssh/scaleway"
  region       = "par1"
  image        = "${data.scaleway_image.centos.id}"
  bootscript   = "${data.scaleway_bootscript.centos.id}"
}

provider "scaleway" {
  region = "${local.region}"
}
```

Configure `ssh_key_path` to the ssh private key you are using for scaleway

Configure `var_dir_path` to where you want to store configuration data

If using the default configuration above, consider `${path.root}/private` to be sensitive information, just like your `tfstate` files.

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
  source = "github.com/bevry/hashistack-scaleway"

  providers = {
    scaleway = "scaleway"
  }

  image         = "${local.image}"
  bootscript    = "${local.bootscript}"
  ssh_key_path  = "${local.ssh_key_path}"
  var_dir_path  = "${local.var_dir_path}"

  region        = "${local.region}"
  type          = "origin"
  count         = 1
}

# Master Server
# Creates consul server + nomad server
module "par1_cluster_master" {
  source = "github.com/bevry/hashistack-scaleway"

  providers = {
    scaleway = "scaleway"
  }

  image         = "${local.image}"
  bootscript    = "${local.bootscript}"
  ssh_key_path  = "${local.ssh_key_path}"
  var_dir_path  = "${local.var_dir_path}"

  region        = "${local.region}"
  type          = "master"
  count         = 2
  join          = "${local.origin}"
}

# Slave Server
# Creates consul agent + docker + nomad agent
module "par1_cluster_slave" {
  source = "github.com/bevry/hashistack-scaleway"

  providers = {
    scaleway = "scaleway"
  }

  image         = "${local.image}"
  bootscript    = "${local.bootscript}"
  ssh_key_path  = "${local.ssh_key_path}"
  var_dir_path  = "${local.var_dir_path}"

  region        = "${local.region}"
  type          = "slave"
  count         = 2
  join          = "${local.origin}"
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
