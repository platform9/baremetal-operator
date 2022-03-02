#!/bin/bash
IFS=','
vbmc_user=`echo $USERNAME | base64`
vbmc_pass=`echo $PASSWORD | base64`
port=`if [[ -z "${VBMC_PORT}" ]]; then echo "6230"
else echo "$VBMC_PORT"
fi`
for addr in $(python3 -c "from ipaddress import IPv4Address as ip; print('\n'.join(str(ip(n)) for n in range(int(ip('$IPMI_RANGE_START')), int(ip('$IPMI_RANGE_END')) + 1)))");
do
cat <<EOF >/bin/ip.txt
`echo $addr`
EOF
done
ipmi_addresses=`curl -s GET --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer \`cat /var/run/secrets/kubernetes.io/serviceaccount/token\`" https://kubernetes.default/apis/metal3.io/v1alpha1/baremetalhosts | jq '.items[].spec.bmc.address'`
while IFS="" read -r ip || [ -n "$ip" ]
do
  	for i in "${ipmi_addresses[@]}";
        do
                if [[ ! "$i" == *"$ip"* ]]; then
		  echo "No bmh present for $ip IPMI address....."
		  if [[ `ipmitool -I lanplus -U $USERNAME -P $PASSWORD -H $ip -p $port power status` ]]; then
			echo "Creating bmh $PREFIX-$ip"
   		  	curl -X POST -H "Content-Type: application/json" --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer `cat /var/run/secrets/kubernetes.io/serviceaccount/token`" https://kubernetes.default/api/v1/namespaces/baremetal-operator-system/secrets/   -d '{"apiVersion":"v1","kind":"Secret","metadata":{"name":"'$PREFIX'-'$ip'-bmc-secret"},"type":"Opaque","data":{"username":"'$vbmc_user'","password":"'$vbmc_pass'"}}' 
		  	curl -X POST -H "Content-Type: application/json" --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer `cat /var/run/secrets/kubernetes.io/serviceaccount/token`" https://kubernetes.default/apis/metal3.io/v1alpha1/namespaces/baremetal-operator-system/baremetalhosts -d '{"apiVersion":"metal3.io/v1alpha1","kind":"BareMetalHost","metadata":{"name":"'$PREFIX'-'$ip'","namespace":"baremetal-operator-system"},"spec":{"bmc":{"address":"ipmi://'$ip':'$port'","credentialsName":"'$PREFIX'-'$ip'-bmc-secret"},"bootMode":"legacy","online":true}}'
		  fi
	  	fi
        done
done < /bin/ip.txt
