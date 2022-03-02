ARG BASE_IMAGE=quay.io/centos/centos:stream8
FROM $BASE_IMAGE AS ironic-builder 
RUN dnf install -y python3 jq OpenIPMI ipmitool
COPY . /bin
