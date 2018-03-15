# zcomapi
command for zcomapi

- ident
  - token
- compute
  - vms
  - vminfo
  - vncconsole
  - webconsole
  - plans
  - images
  - imageinfo
  - keypairs
  - isoimages
  - isodl
  - isomount
  - isoumount
  - backups
- volume
  - list
  - info
- database
  - list
- account
  - list
- image
  - list
  - info
  - quota
- network
  - list
  - ports
  - firewall
  - rules
  - subnets
  - pools
  - poolinfo
  - vips
  - vipinfo

**Request new token update to config**

zcomapi -r han1 -m ident -a token

**List all VMs**

zcomapi -r han1 -m compute -a list
