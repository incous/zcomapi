#!/bin/bash
##################################
# Config
##################################
CONFIGFILE=`dirname $0`/zcomapi.conf
source ${CONFIGFILE} || exit
##################################
func_usage ()
{
  echo '##USAGE##'
  echo "  $0 -r REGION -m MODULE -a ACTION"
  exit 1
}

func_define_url ()
{
  ACCOUNT_URL="https://account.${REGION}.cloud.z.com/v1"
  IMAGE_URL="https://image-service.${REGION}.cloud.z.com"
  NETWORK_URL="https://networking.${REGION}.cloud.z.com/v2.0"
  COMPUTE_URL="https://compute.${REGION}.cloud.z.com/v2"
  VOLUME_URL="https://block-storage.${REGION}.cloud.z.com/v2"
  IDENT_URL="https://identity.${REGION}.cloud.z.com/v2.0"
  DATABASE_URL="https://database-hosting.${REGION}.cloud.z.com/v1"
  DNS_URL="https://dns-service.${REGION}.cloud.z.com/v1"
}

generate_post_data()
{
  cat <<EOF
{
  "auth": {
    "passwordCredentials": {
      "username":"${USERNAME}",
      "password":"${PASSWORD}"
     },
    "tenantId":"${TENANT_ID}"
  }
}
EOF
}

func_account_orders ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${ACCOUNT_URL}/${TENANT_ID}/order-items > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.'
}

func_account_orderinfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${ACCOUNT_URL}/${TENANT_ID}/order-items/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.'
}

func_account_invoices ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${ACCOUNT_URL}/${TENANT_ID}/billing-invoices > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.'
}

func_account_notifications ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${ACCOUNT_URL}/${TENANT_ID}/notifications > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.'
}

func_ident_token()
{
  token=`curl -s -X POST -H "Accept: application/json" -d "$(generate_post_data)" ${IDENT_URL}/tokens | jq ".access.token.id" | tr -d "\""`
  sed -i.bak "s/^TOKEN=.*$/TOKEN=${token}/" ${CONFIGFILE}
}

func_compute_vms ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${COMPUTE_URL}/${TENANT_ID}/servers/detail > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["servers"][] | {name: .metadata.instance_name_tag, uuid: .id, status: .status, host: ."OS-EXT-SRV-ATTR:host", address: [.addresses[][] | select(.version >= 4).addr]}'
}

func_compute_vminfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${COMPUTE_URL}/${TENANT_ID}/servers/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["server"] | {name: .metadata.instance_name_tag, uuid: .id, status: .status, host: ."OS-EXT-SRV-ATTR:host", address: [.addresses[][] | select(.version >= 4).addr], created: .created, updated: .updated, keyname: .keyname, flavor: .flavor.id, image: .image, metadata: .metadata, disks: ."os-extended-volumes:volumes_attached.id", secgroups: [.security_groups[].name]}'
}

func_compute_vmfw ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${COMPUTE_URL}/${TENANT_ID}/servers/${OBJECT}/os-security-groups > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["security_groups"][] | {name: .name, secgroup_id: .id}'
}

func_compute_vncconsole ()
{
  curl -s -X POST -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" -d '{ "os-getVNCConsole": { "type": "novnc" } }' ${COMPUTE_URL}/${TENANT_ID}/servers/${OBJECT}/action > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["console"] | {url: .url}'
}

func_compute_webconsole ()
{
  curl -s -X POST -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" -d '{ "os-getWebConsole": { "type": "serial" } }' ${COMPUTE_URL}/${TENANT_ID}/servers/${OBJECT}/action > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["console"] | {url: .url}'
}

func_compute_plans ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${COMPUTE_URL}/${TENANT_ID}/flavors > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["flavors"][] | {name: .name, id: .id}'
}

func_compute_planinfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${COMPUTE_URL}/${TENANT_ID}/flavors/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["flavor"]'
}

func_compute_images ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${COMPUTE_URL}/${TENANT_ID}/images > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["images"][] | {name: .name, id: .id}'
}

func_compute_imageinfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${COMPUTE_URL}/${TENANT_ID}/images/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["image"] | {name: .name, id: .id, status: .status, progress: .progress, minDisk: .minDisk, minRam: .minRam, created: .created, updated: .updated, metadata: .metadata}'
}

func_compute_keypairs ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${COMPUTE_URL}/${TENANT_ID}/os-keypairs > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["keypairs"][] | {name: .keypair.name}'
}

func_compute_isoimages ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${COMPUTE_URL}/${TENANT_ID}/iso-images > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["iso-images"][]'
}

func_compute_isodl ()
{
  curl -i -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" -d '{ "iso-image": { "url": "'"${OBJECT}"'" } }' ${COMPUTE_URL}/${TENANT_ID}/iso-images > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["request"]'
}

func_compute_isomount ()
{
  curl -i -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" -d '{ "mountImage": "'"${ISOPATH}"'" }' ${COMPUTE_URL}/${TENANT_ID}/servers/${OBJECT}/action > /tmp/output.tmp
  cat /tmp/output.tmp
}

func_compute_isoumount ()
{
  curl -i -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" -d '{ "unmountImage": "" }' ${COMPUTE_URL}/${TENANT_ID}/servers/${OBJECT}/action > /tmp/output.tmp
  cat /tmp/output.tmp
}

func_compute_backups ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${COMPUTE_URL}/${TENANT_ID}/backup > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["backup"][] | {id: .id, type: .backupruns.type, time: .backupruns.created_at}'
}

func_volume_list ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${VOLUME_URL}/${TENANT_ID}/volumes/detail > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["volumes"][] | {name: .name, id: .id, status: .status, size: .size}'
}

func_volume_info ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${VOLUME_URL}/${TENANT_ID}/volumes/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["volume"] | {name: .name, id: .id, status: .status, size: .size, type: .volume_type, boot: .bootable, zone: .availability_zone, encrypt: .encrypted, vmid: .attachments[0].server_id}'
}

func_image_list ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${IMAGE_URL}/v2/images > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["images"][] | select(.owner == "'"${TENANT_ID}"'") | {name: .name, id: .id}'
}

func_image_info ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${IMAGE_URL}/v2/images/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '. | {name: .name, id: .id, container_format: .container_format, disk_format: .disk_format, size: .size, status: .status, created: .created_at, updated: .updated_at}'
}

func_image_quota ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${IMAGE_URL}/v2/quota > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["quota"][]'
}

func_network_list ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/networks > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["networks"][] | select(.tenant_id == "'"${TENANT_ID}"'") | {name: .name, id: .id}'
}

func_network_netinfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/networks/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["network"]'
}

func_network_ports ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/ports > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["ports"][] | select(.tenant_id == "'"${TENANT_ID}"'") | {name: .name, status: .status, id: .id}'
}

func_network_portinfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/ports/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["port"]'
}

func_network_secgroups ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/security-groups > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["security_groups"][] | select(.tenant_id == "'"${TENANT_ID}"'") | {name: .name, id: .id}'
}

func_network_rules ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/security-group-rules > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["security_group_rules"][] | select(.tenant_id == "'"${TENANT_ID}"'" and .security_group_id == "'"${OBJECT}"'")'
}

func_network_subnets ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/subnets > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["subnets"][] | select(.tenant_id == "'"${TENANT_ID}"'") | {name: .name, id: .id}'
}

func_network_subnetinfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/subnets/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["subnet"]'
}

func_network_pools ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/lb/pools > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["pools"][] | select(.tenant_id == "'"${TENANT_ID}"'") | {name: .name, id: .id}'
}

func_network_poolinfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/lb/pools/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["pool"] | {name: .name, description: .description, id: .id, vip_id: .vip_id, protocol: .protocol, lb_method: .lb_method, status: .status, healthcheck: .health_monitors, members: .members}'
}

func_network_vips ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/lb/vips > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["vips"][] | select(.tenant_id == "'"${TENANT_ID}"'") | {name: .name, id: .id, ip: .address, port: .protocol_port}'
}

func_network_vipinfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/lb/vips/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["vip"] | {name: .name, id: .id, port_id: .port_id, pool_id: .pool_id, ip: .address, port: .protocol_port}'
}

func_network_healthchecks ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/lb/health_monitors > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["health_monitors"][] | select(.tenant_id == "'"${TENANT_ID}"'") | {id: .id, type: .type, delay: .delay, timeout: .timeout}'
}

func_network_healthcheckinfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${NETWORK_URL}/lb/health_monitors/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["health_monitor"]'
}

func_database_list ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${DATABASE_URL}/services > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.'
}

func_database_dbs ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${DATABASE_URL}/databases > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.'
}

func_database_dbinfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${DATABASE_URL}/databases/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.'
}

func_database_dbusers ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${DATABASE_URL}/databases/${OBJECT}/grant > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.'
}

func_database_users ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${DATABASE_URL}/users > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.'
}

func_database_userinfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${DATABASE_URL}/users/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.'
}

func_dns_domains ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${DNS_URL}/domains > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["domains"][] | {name: .name, id: .id}'
}

func_dns_dominfo ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${DNS_URL}/domains/${OBJECT} > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.'
}

func_dns_domrecords ()
{
  curl -s -X GET -H "Accept: application/json" -H "X-Auth-Token: ${TOKEN}" ${DNS_URL}/domains/${OBJECT}/records > /tmp/output.tmp
  cat /tmp/output.tmp | jq '.["records"][] | {id: .id, name: .name, type: .type, data: .data}'
}

while getopts r:m:a:o:p: OPT
do
  case $OPT in
    "r" ) REGION="$OPTARG" ;;
    "m" ) MODULE="$OPTARG" ;;
    "a" ) ACTION="$OPTARG" ;;
    "o" ) OBJECT="$OPTARG" ;;
    "p" ) ISOPATH="$OPTARG" ;;
     * ) func_usage ;;
  esac
done

#Check Arguments
if [ -z ${REGION} ] || [ -z ${MODULE} ] || [ -z ${ACTION} ]; then
  func_usage
fi

if [[ ${MODULE} = "account" ]]; then
  ACCOUNT_URL="https://account.${REGION}.cloud.z.com/v1"
  if [[ ${ACTION} = "orders" ]]; then
    func_account_orders;
  elif [[ ${ACTION} = "order" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_account_orderinfo;
    fi
  elif [[ ${ACTION} = "invoices" ]]; then
    func_account_products;
  elif [[ ${ACTION} = "notifications" ]]; then
    func_account_notifications;
  fi
fi

if [[ ${MODULE} = "ident" ]]; then
  IDENT_URL="https://identity.${REGION}.cloud.z.com/v2.0"
  if [[ ${ACTION} = "token" ]]; then
    func_ident_token;
  fi
fi

if [[ ${MODULE} = "compute" ]]; then
  COMPUTE_URL="https://compute.${REGION}.cloud.z.com/v2"
  if [[ ${ACTION} = "vms" ]]; then
    func_compute_vms;
  elif [[ ${ACTION} = "vminfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_compute_vminfo;
    fi
  elif [[ ${ACTION} = "vmfw" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_compute_vmfw;
    fi
  elif [[ ${ACTION} = "vncconsole" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_compute_vncconsole;
    fi
  elif [[ ${ACTION} = "webconsole" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_compute_webconsole;
    fi
  elif [[ ${ACTION} = "plans" ]]; then
    func_compute_plans;
  elif [[ ${ACTION} = "planinfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_compute_planinfo;
    fi
  elif [[ ${ACTION} = "images" ]]; then
    func_compute_images;
  elif [[ ${ACTION} = "imageinfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_compute_imageinfo;
    fi
  elif [[ ${ACTION} = "keypairs" ]]; then
    func_compute_keypairs;
  elif [[ ${ACTION} = "isoimages" ]]; then
    func_compute_isoimages;
  elif [[ ${ACTION} = "isodl" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_compute_isodl;
    fi
  elif [[ ${ACTION} = "isomount" ]]; then
    if [ -z ${OBJECT} ] || [ -z ${ISOPATH} ]; then
      func_usage;
    else
      func_compute_isomount;
    fi
  elif [[ ${ACTION} = "isoumount" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_compute_isoumount;
    fi
  elif [[ ${ACTION} = "backups" ]]; then
    func_compute_backups;
  fi
fi

if [[ ${MODULE} = "volume" ]]; then
  VOLUME_URL="https://block-storage.${REGION}.cloud.z.com/v2"
  if [[ ${ACTION} = "list" ]]; then
    func_volume_list;
  elif [[ ${ACTION} = "info" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_volume_info;
    fi
  fi
fi

if [[ ${MODULE} = "image" ]]; then
  IMAGE_URL="https://image-service.${REGION}.cloud.z.com"
  if [[ ${ACTION} = "list" ]]; then
    func_image_list;
  elif [[ ${ACTION} = "info" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_image_info;
    fi
  elif [[ ${ACTION} = "quota" ]]; then
    func_image_quota;
  fi
fi

if [[ ${MODULE} = "network" ]]; then
  NETWORK_URL="https://networking.${REGION}.cloud.z.com/v2.0"
  if [[ ${ACTION} = "list" ]]; then
    func_network_list;
  elif [[ ${ACTION} = "netinfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_network_netinfo;
    fi
  elif [[ ${ACTION} = "ports" ]]; then
    func_network_ports;
  elif [[ ${ACTION} = "portinfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_network_portinfo;
    fi
  elif [[ ${ACTION} = "secgroups" ]]; then
    func_network_secgroups;
  elif [[ ${ACTION} = "rules" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_network_rules;
    fi
  elif [[ ${ACTION} = "subnets" ]]; then
    func_network_subnets;
  elif [[ ${ACTION} = "subnetinfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_network_subnetinfo;
    fi
  elif [[ ${ACTION} = "pools" ]]; then
    func_network_pools;
  elif [[ ${ACTION} = "poolinfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_network_poolinfo;
    fi
  elif [[ ${ACTION} = "vips" ]]; then
    func_network_vips;
  elif [[ ${ACTION} = "vipinfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_network_vipinfo;
    fi
  elif [[ ${ACTION} = "healthchecks" ]]; then
    func_network_healthchecks;
  elif [[ ${ACTION} = "healthcheckinfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_network_healthcheckinfo;
    fi
  fi
fi

if [[ ${MODULE} = "database" ]]; then
  DATABASE_URL="https://database-hosting.${REGION}.cloud.z.com/v1"
  if [[ ${ACTION} = "list" ]]; then
    func_database_list;
  elif [[ ${ACTION} = "dbs" ]]; then
    func_database_dbs;
  elif [[ ${ACTION} = "dbinfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_database_dbinfo;
    fi
  elif [[ ${ACTION} = "dbusers" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_database_dbusers;
    fi
  elif [[ ${ACTION} = "users" ]]; then
    func_database_users;
  elif [[ ${ACTION} = "userinfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_database_userinfo;
    fi
  fi
fi

if [[ ${MODULE} = "dns" ]]; then
  DNS_URL="https://dns-service.${REGION}.cloud.z.com/v1"
  if [[ ${ACTION} = "domains" ]]; then
    func_dns_domains;
  elif [[ ${ACTION} = "dominfo" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_dns_dominfo;
    fi
  elif [[ ${ACTION} = "domrecords" ]]; then
    if [ -z ${OBJECT} ]; then
      func_usage;
    else
      func_dns_domrecords;
    fi
  elif [[ ${ACTION} = "quota" ]]; then
    func_image_quota;
  fi
fi
