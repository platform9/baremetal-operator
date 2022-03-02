#!/bin/bash
vbmc_user=$(echo ${USERNAME} | base64)
vbmc_pass=$(echo ${PASSWORD} | base64)
ipmi_addr=${IPMI_ADDRESS:-127.0.0.1}

k8s_bearer_token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl_args=("--cacert" "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt" "-H" "Authorization: Bearer ${k8s_bearer_token}")

# fetch addresses of bare metal hosts already known
IFS=','
ipmi_addresses=$(curl -s GET "${curl_args[@]}" https://kubernetes.default/apis/metal3.io/v1alpha1/baremetalhosts | jq '.items[].spec.bmc.address')

for port in $(seq --separator=, ${VBMC_PORT_START} ${VBMC_PORT_END}); do
    # we wish to ignore ports already known
    # https://stackoverflow.com/a/15394738
    if [[ ! "${ipmi_addresses[*]}:" =~ ":${port}" ]]; then
     echo "No bare metal host present for IPMI port ${port} ..."
     if ipmitool -I lanplus -U ${USERNAME} -P ${PASSWORD} -H ${ipmi_addr} -p ${port} power status; then
	  echo "Creating bmh test-pf9-${port}"
   	  curl -X POST -H "Content-Type: application/json" "${curl_args[@]}" https://kubernetes.default/api/v1/namespaces/baremetal-operator-system/secrets/ -d '{"apiVersion":"v1","kind":"Secret","metadata":{"name":"test-pf9-'${port}'-bmc-secret"},"type":"Opaque","data":{"username":"'${vbmc_user}'","password":"'${vbmc_pass}'"}}' 
	  curl -X POST -H "Content-Type: application/json" "${curl_args[@]}" https://kubernetes.default/apis/metal3.io/v1alpha1/namespaces/baremetal-operator-system/baremetalhosts -d '{"apiVersion":"metal3.io/v1alpha1","kind":"BareMetalHost","metadata":{"name":"test-pf9-'${port}'","namespace":"baremetal-operator-system"},"spec":{"bmc":{"address":"ipmi://'${ipmi_addr}':'${port}'","credentialsName":"test-pf9-'${port}'-bmc-secret"},"bootMode":"legacy","online":true}}'
     fi
    fi
done
