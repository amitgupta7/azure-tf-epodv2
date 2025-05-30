#!/usr/bin/env bash
while getopts k:s:t:o:n: flag
do
    case "${flag}" in
        n) pod_name=${OPTARG};;
        o) pod_owner=${OPTARG};;
        k) xkey=${OPTARG};;
        s) xsecret=${OPTARG};;
        t) xtenant=${OPTARG};;
    esac
done

mkdir -p localfiles
cd localfiles

  curl -s -X 'GET' \
  'https://app.securiti.ai/core/v1/admin/appliance/chart_download_url' \
  -H 'accept: application/json' \
  -H 'X-API-Secret:  '${xsecret} \
  -H 'X-API-Key:  '${xkey} \
  -H 'X-TIDENT:  '${xtenant} \
  | jq -r '.download_url' | xargs -n 1 curl -O 

  appliance_name="${pod_name}-$(echo $(date +%s) %1000+1|bc)"
  curl -s -X 'POST' \
  'https://app.securiti.ai/core/v1/admin/appliance' \
  -H 'accept: application/json' \
  -H 'X-API-Secret:  '${xsecret} \
  -H 'X-API-Key:  '${xkey} \
  -H 'X-TIDENT:  '${xtenant} \
  -H 'Content-Type: application/json' \
  -d '{
        "owner": "'${pod_owner}'",
        "co_owners": [],
        "name": "'${appliance_name}'",
        "desc": "",
        "install_mode":"byok",
        "notify_owners":false,
        "custom_registry":false,
        "namespace":"default",
        "install_monitoring":true,
        "install_metrics":true,
        "max_memory":64000,
        "location": {
            "city":"",
            "state":"Alabama",
            "country":"United States of America"
        }
    }' > appliance.json

  appliance_id=$(cat appliance.json | jq -r '.data.id')

  curl -s -X POST https://app.securiti.ai/core/v1/admin/appliance/${appliance_id}/custom_values \
  -H 'accept: application/json, text/plain, */*' \
  -H 'X-API-Secret:  '${xsecret} \
  -H 'X-API-Key:  '${xkey} \
  -H 'X-TIDENT:  '${xtenant} \
  -H 'Content-Type: application/json' \
  -d '{"custom_registry":false,"registry_host":"","namespace":"default","install_monitoring":true,"prometheus_url":"","install_metrics":false,"max_memory":64000,"custom_annotations":"","custom_labels":"","node_selector":""}'

  curl -s -X GET https://app.securiti.ai/core/v1/admin/appliance/${appliance_id}/overrides \
  -H 'accept: application/json' \
  -H 'X-API-Secret:  '${xsecret} \
  -H 'X-API-Key:  '${xkey} \
  -H 'X-TIDENT:  '${xtenant} \
  | jq -r '.data' | base64 --decode > values.yaml

    curl -s -X GET https://app.securiti.ai/core/v1/admin/appliance/${appliance_id}/install_command \
  -H 'accept: application/json' \
  -H 'X-API-Secret:  '${xsecret} \
  -H 'X-API-Key:  '${xkey} \
  -H 'X-TIDENT:  '${xtenant} \
  | jq -r '.data' > install.sh

  curl -s -X GET https://app.securiti.ai/core/v1/admin/appliance/${appliance_id}/appliance_auth \
  -H 'accept: application/json' \
  -H 'X-API-Secret:  '${xsecret} \
  -H 'X-API-Key:  '${xkey} \
  -H 'X-TIDENT:  '${xtenant} \
 | jq -r '.data' | base64 --decode > secret.json
 
  echo "appliance created with id: ${appliance_id}"
