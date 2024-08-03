#!/bin/bash
set -exuo pipefail

BOOT_COUNTS=$(journalctl --list-boots -q | wc -l)

if [[ "$BOOT_COUNTS" == "1" ]]; then

    TEMPDIR=$(mktemp -d)
    trap 'rm -rf -- "$TEMPDIR"' EXIT

    CONTAINERFILE=${TEMPDIR}/Containerfile
    TIER1_IMAGE_URL="quay.io/xiaofwan/fedora-bootc-os_replace:beaker"
    LOCAL_IMAGE_NAME="bootc-image:beaker"

    tee "$CONTAINERFILE" > /dev/null << EOF
FROM "$TIER1_IMAGE_URL"
RUN dnf install -y wget && dnf -y clean all
EOF

    podman build --tls-verify=false --retry=5 --retry-delay=10 -t "$LOCAL_IMAGE_NAME" -f "$CONTAINERFILE" .
    podman push --tls-verify=false --quiet "localhost/$LOCAL_IMAGE_NAME" dir:/mnt

    bootc switch --quiet --transport dir /mnt

    rstrnt-reboot
    exit 0
else
    rstrnt-report-result switch PASS 0
    exit 0
fi
