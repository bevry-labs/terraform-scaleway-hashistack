# Hashistack on Scaleway

[Terraform](https://www.terraform.io) module to deploy [Consul](https://www.consul.io), [Nomad](https://www.nomadproject.io), [Vault](https://www.vaultproject.io) onto [Scaleway](https://www.scaleway.com)

This module is currently under construction. I would love assistance. [Please reach out.](https://balupton.com/meet)

## Features

- [x] deploys a consul, vault, nomad, docker cluster to scaleway
- [x] configures firewalls correctly
- [x] uses local TLS via `tls_mode=local`
    - [x] uses mutual TLS for consul and vault
    - [ ] uses mutual TLS for nomad
- [ ] uses [Cloudflare's Argo Tunnel](https://www.cloudflare.com/products/argo-tunnel/) via `tls_mode=cloudflared`
- [ ] uses [fabio](https://github.com/fabiolb/fabio) or [traefik](https://github.com/containous/traefik)

## Preparation

If you are using MacOS, you will need to do the following:

``` bash
brew install coreutils
npm i -g json
```

## Servers

Origin Server:

- Creates consul server + vault server
- Initialises consul
- Initialises vault
- Generates nomad vault configuration
- Generates TLS certificates via vault pki
- Restarts consul and vault with TLS

Master Server:

- Creates consul server + nomad server

Slave Server:

- Creates consul agent + docker + nomad agent


## Usage

Refer to [`./example/main.tf`](https://github.com/bevry/terraform-scaleway-hashistack/blob/master/example/main.tf)


## Debugging

If you need to debug DNS:

``` bash
sudo yum install -y net-tools # ifconfig
sudo yum install -y bind-utils # dig
netstat -lnp
netstat -rn
route -n
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
