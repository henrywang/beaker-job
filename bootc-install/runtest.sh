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
    # replace with your public key
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtJv3QKdqQ+0+jJND7bXVq9ux87yyi4qyJk7iOsX2VsgAUuYXpBf337p5yNB3N1kjOwGYSDjvDvS7GuhdatuvJI3/xzcyodbwJp32AT76e9uvUQHTBBGmUvBLzw3nk8ZDNp5d4rt2cZvlhv7lzDSt30DF14ivg5Xp/V0tK0BEfFlvYHuHheDeiSOQRQ392J7TefPQOW+JpxANU4Bxc1aHIettaIqQMWm9r4ZELd8M83IYt5Btp1bPsnfYywQMYqNXyDuhwhcsBTR5kVObP0DwxKZbMNPmA2lBvrX2GMIa+qfvKIW87KooaoPLt7CR7/DKfQ1S492L1wIwNUPUBLsQD xiaofwan@dhcp-8-203.nay.redhat.com' > /tmp/id_rsa.pub

    podman run \
        --rm \
        --tls-verify=false \
        --privileged \
        --pid=host \
        -v /:/target \
        -v /dev:/dev \
        -v /var/lib/containers:/var/lib/containers \
        -v /tmp:/output \
        --security-opt label=type:unconfined_t \
        "quay.io/xiaofwan/fedora-bootc-os_replace:beaker" \
        bootc install to-existing-root \
        --root-ssh-authorized-keys /output/id_rsa.pub

    rstrnt-reboot
    exit 0
fi
