#!/bin/bash
set -exuo pipefail

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

bootc switch "localhost/$LOCAL_IMAGE_NAME"

rstrnt-reboot
