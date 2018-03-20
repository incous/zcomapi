# zcomapi
command for zcomapi

- account
  - orders
  - orderinfo -o ORDERID
  - invoices
  - notifications
- ident
  - token
- compute
  - vms
  - vminfo -o VMID
  - vmfw -o VMID
  - vncconsole -o VMID
  - webconsole -o VMID
  - plans
  - planinfo -o PLANID
  - images
  - imageinfo -o IMAGEID
  - keypairs
  - isoimages
  - isodl -o URL
  - isomount -o VMID -p ISOPATH
  - isoumount -o VMID
  - backups
- volume
  - list
  - info -o VOLUMEID
- image
  - list
  - info -o IMAGEID
  - quota
- network
  - list
  - netinfo -o NETID
  - ports
  - portinfo -o PORTID
  - secgroups
  - rules -o SECGROUPID
  - subnets
  - subnetinfo -o SUBNETID
  - pools
  - poolinfo -o POOLID
  - vips
  - vipinfo -o VIPID
  - healthchecks
  - healthcheckinfo -o HEALTHCHECKID
- database
  - list
  - dbs
  - dbinfo -o DBID
  - dbusers -o DBID
  - users
  - userinfo -o USERID
- dns
  - domains
  - dominfo -o DOMAINID
  - domrecords -o DOMAINID

**Request new token update to config**

zcomapi -r han1 -m ident -a token

**List all VMs**

zcomapi -r han1 -m compute -a vms
