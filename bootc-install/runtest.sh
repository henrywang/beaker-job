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

    tee "${TEMPDIR}/beaker-harness.repo" > /dev/null << EOF
[beaker-harness]
name=beaker-harness
baseurl=http://beaker.engineering.redhat.com/harness/Fedora40/
enabled=1
gpgcheck=0
EOF

    # Should upgrade kernel in Containerfile
    tee "$CONTAINERFILE" > /dev/null << EOF
FROM "$TIER1_IMAGE_URL"
ADD http://lab-02.rhts.eng.rdu.redhat.com/beaker/anamon3 /usr/local/sbin/anamon
COPY beaker-harness.repo /etc/yum.repos.d/
RUN chmod 755 /usr/local/sbin/anamon && \
    dnf install -y restraint && \
    dnf -y clean all
EOF

    podman build --tls-verify=false --retry=5 --retry-delay=10 -t "$LOCAL_IMAGE_NAME" -f "$CONTAINERFILE" "$TEMPDIR"

    podman run \
        --rm \
        --tls-verify=false \
        --privileged \
        --pid=host \
        -v /:/target \
        -v /dev:/dev \
        -v /var/lib/containers:/var/lib/containers \
        --security-opt label=type:unconfined_t \
        "localhost/${LOCAL_IMAGE_NAME}" \
        bootc install to-existing-root --target-transport=containers-storage

    rstrnt-reboot
    exit 0
fi
