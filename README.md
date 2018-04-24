# Hashistack on Scaleway

[Terraform](https://www.terraform.io) module to deploy [Consul](https://www.consul.io), [Nomad](https://www.nomadproject.io), [Vault](https://www.vaultproject.io) onto [Scaleway](https://www.scaleway.com)

This module is currently under construction. I would love assistance. [Please reach out.](https://balupton.com/meet)

## Features

- [x] deploys a consul, vault, nomad, docker cluster to scaleway
- [x] configures scaleway and centos firewalls correctly
- [ ] uses TLS for security
- [ ] uses [Cloudflare's Argo Tunnel](https://www.cloudflare.com/products/argo-tunnel/) for security
- [ ] uses [fabio](https://github.com/fabiolb/fabio) or [traefik](https://github.com/containous/traefik) for routing

## Todo

- [ ] TLS encryption
    - Vault
        - https://www.vaultproject.io/api/secret/pki/index.html
            - https://www.vaultproject.io/docs/secrets/pki/index.html
        - https://www.vaultproject.io/api/auth/cert/index.html
            - https://www.vaultproject.io/docs/auth/cert.html
        - https://www.vaultproject.io/docs/configuration/listener/tcp.html
    - Consul
        - https://www.consul.io/docs/agent/encryption.html
    - Nomad
        - https://www.nomadproject.io/docs/agent/encryption.html
            - https://www.nomadproject.io/guides/securing-nomad.html

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
- Restarts nomad and vault with TLS

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
