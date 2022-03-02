ARG BASE_IMAGE=quay.io/centos/centos:stream8
FROM ${BASE_IMAGE} AS ironic-builder 
RUN dnf install -y \
    OpenIPMI \
    ipmitool \
    jq \
    python3
COPY ipmi_address_bulk.sh ipmi_port_bulk.sh /bin/
