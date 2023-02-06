#!/bin/bash

IMG_NAME="Kinoite for the MSI Stealth 15M"
IMG=ostree-unverified-registry:ghcr.io/sihawken/kinoite-msi-stealth-15m:latest

if [[ $(id -u) == 0 ]]; then
    echo "Do not run this script using sudo. Please run as a normal user."
    exit 99
fi

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VAR=$VARIANT
fi

# Only run if on Kinoite or Silverblue
if [ "${OS}" = "Fedora Linux" ] && [ "${VAR}" = "Kinoite" ]; then
    echo "System is running Fedora Kinoite. Ready to rebase to: ${IMG_NAME}."
elif [ "${OS}" = "Fedora Linux" ] && [ "${VAR}" = "Silverblue" ]; then
    echo "System is running Fedora Silverblue. Ready to rebase to: ${IMG_NAME}."
else 
    echo "Host system is neither Fedora Siverblue or Fedora Kinoite. This script only supports migrating from these two systems. Please install Fedora Silverblue or Fedora Kinoite and run the script again."
    exit 1
fi

read -r -p "WARNING: Rebasing to ${IMG_NAME} will delete all preinstalled flatpaks. This script is meant to only be used on a new Kinoite or Silverblue install. Do you wish to continue? [y/N]" response
if [[ ! $response =~ ^[Yy]$ ]]
then
    echo "Confirmation not recieved. System will not be migrated."
    exit 1
fi

echo "Migrating to ${IMG_NAME}. Running rpm-ostree rebase && setting the kernel arguments."

pkexec sh -c 'rpm-ostree rebase --experimental $IMG && \
    rpm-ostree kargs \
    --append=rd.driver.blacklist=nouveau \
    --append=modprobe.blacklist=nouveau \
    --append=nvidia-drm.modeset=1 \
    --append=nvidia.NVreg_DynamicPowerManagement=0x02 \
    --append=nvidia.NVreg_PreserveVideoMemoryAllocations=0 \
    --append=nvidia.NVreg_DynamicPowerManagementVideoMemoryThreshold=200 && \
    systemctl reboot'