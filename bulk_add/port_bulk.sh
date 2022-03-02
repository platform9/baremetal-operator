#!/bin/bash
vbmc_user=`echo $USERNAME | base64`
vbmc_pass=`echo $PASSWORD | base64`
ipmi_addr=`if [[ -z "${IPMI_ADDRESS}" ]]; then echo "127.0.0.1"
else echo "$IPMI_ADDRESS"
fi`
ipmi_addresses=`curl -s GET --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer \`cat /var/run/secrets/kubernetes.io/serviceaccount/token\`" https://kubernetes.default/apis/metal3.io/v1alpha1/namespaces/default/baremetalhosts | jq '.items[].spec.bmc.address'`
for port in $(seq $VBMC_PORT_START $VBMC_PORT_END);
do
	for i in "${ipmi_addresses[@]}";
	do 
		if [[ ! "$i" == *"$port"* ]]; then	
			echo "No bmh present for vbmc $port ....."
		  	if [[ `ipmitool -I lanplus -U $USERNAME -P $PASSWORD -H $ipmi_addr -p $port power status` ]]; then
				echo "Creating bmh test-pf9-$port"
				curl -X POST -H "Content-Type: application/json" --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer `cat /var/run/secrets/kubernetes.io/serviceaccount/token`" https://kubernetes.default/api/v1/namespaces/baremetal-operator-system/secrets/   -d '{"apiVersion":"v1","kind":"Secret","metadata":{"name":"test-pf9-'$port'-bmc-secret"},"type":"Opaque","data":{"username":"'$vbmc_user'","password":"'$vbmc_pass'"}}'
				curl -X POST -H "Content-Type: application/json" --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer `cat /var/run/secrets/kubernetes.io/serviceaccount/token`" https://kubernetes.default/apis/metal3.io/v1alpha1/namespaces/baremetal-operator-system/baremetalhosts -d '{"apiVersion":"metal3.io/v1alpha1","kind":"BareMetalHost","metadata":{"name":"test-pf9-'$port'","namespace":"baremetal-operator-system"},"spec":{"bmc":{"address":"ipmi://'$ipmi_addr':'$port'","credentialsName":"test-pf9-'$port'-bmc-secret"},"bootMode":"legacy","online":true}}'
			fi
		fi
	done
done
