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
    TEMPDIR=$(mktemp -d)
    trap 'rm -rf -- "$TEMPDIR"' EXIT

    CONTAINERFILE=${TEMPDIR}/Containerfile
    TIER1_IMAGE_URL="${TIER1_IMAGE_URL:-quay.io/fedora/fedora-bootc:40}"
    LOCAL_IMAGE_NAME="bootc-image:beaker"

    # Should upgrade kernel in Containerfile
    tee "$CONTAINERFILE" > /dev/null << EOF
FROM "$TIER1_IMAGE_URL"
RUN dnf install -y wget && dnf -y clean all
EOF

    podman build --tls-verify=false --retry=5 --retry-delay=10 -t "$LOCAL_IMAGE_NAME" -f "$CONTAINERFILE" .

    podman run \
        --rm \
        --tls-verify=false \
        --privileged \
        --pid=host \
        -v /:/target \
        -v /dev:/dev \
        -v /var/lib/containers:/var/lib/containers \
        --security-opt label=type:unconfined_t \
        "$LOCAL_IMAGE_NAME" \
        bootc install to-existing-root

    rstrnt-reboot
    exit 0
fi
