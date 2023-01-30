ARG FEDORA_MAJOR_VERSION=37
FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_MAJOR_VERSION}
ARG FEDORA_MAJOR_VERSION
ARG KERNEL_VERSION=6.0.8-xm1.0.fc37.x86_64 

COPY etc /etc

COPY ublue-firstboot /usr/bin

RUN rpm-ostree override remove toolbox firefox firefox-langpacks && \
    rpm-ostree install zsh neofetch distrobox && \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    wget https://copr.fedorainfracloud.org/coprs/rmnscnce/kernel-xanmod/repo/fedora-${FEDORA_MAJOR_VERSION}/rmnscnce-kernel-xanmod-fedora-${FEDORA_MAJOR_VERSION}.repo -O /etc/yum.repos.d/rmnscnce-kernel-xanmod-fedora-${FEDORA_MAJOR_VERSION}.repo && \
    rpm-ostree override remove kernel kernel-modules-extra kernel-core kernel-modules --install kernel-xanmod-edge --install kernel-xanmod-edge-core --install kernel-xanmod-edge-modules && \
    rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm && \
    rpm-ostree override remove mesa-va-drivers --install mesa-va-drivers-freeworld && \
    rpm-ostree install mesa-vdpau-drivers-freeworld && \
    rpm-ostree install libva-intel-driver intel-media-driver && \
    wget https://negativo17.org/repos/fedora-nvidia.repo -O /etc/yum.repos.d/fedora-nvidia.repo && \
    rpm-ostree override remove nvidia-gpu-firmware --install nvidia-driver --install nvidia-driver-cuda --install nvidia-settings && \
    rpm-ostree install latte-dock && \
    rpm-ostree install gnome-software && \
    rm var/log/akmods/akmods.log && \
    /usr/bin/dracut --tmpdir /tmp/ --no-hostonly --kver ${KERNEL_VERSION} --reproducible -v --add ostree -f /tmp/initramfs2.img && \
    mv /tmp/initramfs2.img /lib/modules/${KERNEL_VERSION}/initramfs.img && \
    ostree container commit
