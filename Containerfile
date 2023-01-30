ARG FEDORA_MAJOR_VERSION=37
FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_MAJOR_VERSION}
ARG FEDORA_MAJOR_VERSION
ARG KERNEL_REPO=https://download.copr.fedorainfracloud.org/results/rmnscnce/kernel-xanmod/fedora-37-x86_64/05033717-kernel-xanmod-edge/
ARG KERNEL_VERSION=6.0.8-xm1.0.fc37.x86_64

COPY etc /etc

COPY ublue-firstboot /usr/bin

RUN rpm-ostree override remove toolbox firefox firefox-langpacks && \
    rpm-ostree install zsh neofetch distrobox zenity && \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    rpm-ostree override remove kernel kernel-core kernel-modules kernel-modules-extra \
    --install ${KERNEL_REPO}/kernel-xanmod-edge-${KERNEL_VERSION}.rpm --install ${KERNEL_REPO}/kernel-xanmod-edge-core-${KERNEL_VERSION}.rpm --install ${KERNEL_REPO}/kernel-xanmod-edge-modules-${KERNEL_VERSION}.rpm && \
    rpm-ostree install ${KERNEL_REPO}/kernel-xanmod-edge-devel-${KERNEL_VERSION}.rpm ${KERNEL_REPO}/kernel-xanmod-edge-devel-matched-${KERNEL_VERSION}.rpm && \
    rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm && \
    rpm-ostree override remove mesa-va-drivers --install mesa-va-drivers-freeworld && \
    rpm-ostree install mesa-vdpau-drivers-freeworld && \
    rpm-ostree install libva-intel-driver intel-media-driver && \
    wget https://negativo17.org/repos/fedora-nvidia.repo -O /etc/yum.repos.d/fedora-nvidia.repo && \
    rpm-ostree override remove nvidia-gpu-firmware --install nvidia-driver --install nvidia-driver-cuda --install nvidia-settings && \
    rpm-ostree install latte-dock && \
    rpm-ostree install gnome-software && \
    /usr/bin/dracut --tmpdir /tmp/ --no-hostonly --kver ${KERNEL_VERSION} --reproducible --add ostree -f /tmp/initramfs2.img && \
    mv /tmp/initramfs2.img /lib/modules/${KERNEL_VERSION}/initramfs.img && \
    rm -rf var/log/akmods && \
    ostree container commit
