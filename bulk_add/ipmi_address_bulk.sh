#!/bin/bash
bmc_user=$(echo ${USERNAME} | base64)
bmc_pass=$(echo ${PASSWORD} | base64)
port=${BMC_PORT:-6230}

k8s_bearer_token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl_args=("--cacert" "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt" "-H" "Authorization: Bearer ${k8s_bearer_token}")

# fetch addresses of bare metal hosts already known
ipmi_addresses=$(curl -s GET "${curl_args[@]}" https://kubernetes.default/apis/metal3.io/v1alpha1/baremetalhosts | jq '.items[].spec.bmc.address')

# generate a new list of ip addresses in the range provided
for addr in $(python3 -c "from ipaddress import IPv4Address as ip; print('\n'.join(str(ip(n)) for n in range(int(ip('${IPMI_RANGE_START}')), int(ip('${IPMI_RANGE_END}')) + 1)))"); do
    # we wish to ignore addresses already known
    # https://stackoverflow.com/a/15394738
    if [[ ! "${ipmi_addresses[*]}:" =~ "${addr}:" ]]; then
     echo "No bare metal host present for IPMI address ${addr} ..."
     if ipmitool -I lanplus -U ${USERNAME} -P ${PASSWORD} -H ${addr} -p ${port} power status; then
	  echo "Creating bmh ${PREFIX}-${addr}"
   	  curl -X POST -H "Content-Type: application/json" "${curl_args[@]}" https://kubernetes.default/api/v1/namespaces/baremetal-operator-system/secrets/ -d '{"apiVersion":"v1","kind":"Secret","metadata":{"name":"'${PREFIX}'-'${addr}'-bmc-secret"},"type":"Opaque","data":{"username":"'${bmc_user}'","password":"'${bmc_pass}'"}}' 
	  curl -X POST -H "Content-Type: application/json" "${curl_args[@]}" https://kubernetes.default/apis/metal3.io/v1alpha1/namespaces/baremetal-operator-system/baremetalhosts -d '{"apiVersion":"metal3.io/v1alpha1","kind":"BareMetalHost","metadata":{"name":"'${PREFIX}'-'${addr}'","namespace":"baremetal-operator-system"},"spec":{"bmc":{"address":"ipmi://'${addr}':'${port}'","credentialsName":"'${PREFIX}'-'${addr}'-bmc-secret"},"bootMode":"legacy","online":true}}'
     fi
    fi
done
