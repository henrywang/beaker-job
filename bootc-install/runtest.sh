#!/bin/bash
set -exuo pipefail

# Detecting bootc systems
ROOT_FSTYPE=$(findmnt -r -o FSTYPE -n /)

# Deployment successful
if [[ "$ROOT_FSTYPE" == "overlay" ]]; then
    bootc status
    rstrnt-report-result switch PASS 0
    exit 0
else
    dnf install -y podman
    podman run \
        --rm \
        --tls-verify=false \
        --privileged \
        --pid=host \
        -v /:/target \
        -v /dev:/dev \
        -v /var/lib/containers:/var/lib/containers \
        --security-opt label=type:unconfined_t \
        "quay.io/xiaofwan/fedora-bootc-os_replace:beaker" \
        bootc install to-existing-root

    rstrnt-reboot
    exit 0
fi
