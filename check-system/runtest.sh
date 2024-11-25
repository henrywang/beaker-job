#!/bin/bash
set -e

# Colorful timestamped output.
function greenprint {
  echo -e "\033[1;32m[$(date -Isecond)] ${1}\033[0m"
}

if [[ -d /sys/firmware/efi ]]; then
    greenprint "Boot as UEFI"
else
    greenprint "Boot as BIOS"
fi

greenprint "SELinux status"
getenforce

greenprint "System partition info"
df -Th

greenprint "Partition tabke"
fdisk -l

greenprint "Block device"
lsblk -af

greenprint "Mount table"
findmnt

greenprint "rpm-ostree status"
rpm-ostree status

greenprint "Bootc status"
bootc status

greenprint "Installed packages"
rpm -qa | sort

greenprint "Deploy correct image"
IMAGE_URL=$(bootc status --json | jq -r '.status.booted.image.image.image')
if [[ "$IMAGE_URL" == "$BOOTC_IMAGE_URL" ]]; then
    rstrnt-report-result check-system PASS 0
    exit 0
else
    rstrnt-report-result check-system FAIL 0
    exit 0
fi
