ARG FEDORA_MAJOR_VERSION=37

FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_MAJOR_VERSION} AS nvidia_builder
ARG FEDORA_MAJOR_VERSION

# Build Nvidia driver
RUN rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm && \
    rpm-ostree install mock xorg-x11-drv-nvidia{,-cuda} binutils \
                       kernel-devel-$(rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}') && \
    ln -s /usr/bin/ld.bfd /etc/alternatives/ld && ln -s /etc/alternatives/ld /usr/bin/ld && \
    akmods --force --kernels "$(rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"


FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_MAJOR_VERSION}
ARG FEDORA_MAJOR_VERSION

COPY --from=nvidia_builder /var/cache/akmods/nvidia /tmp/nvidia

COPY etc /etc

COPY ublue-firstboot /usr/bin

RUN rpm-ostree override remove toolbox firefox firefox-langpacks && \
    rpm-ostree install zsh neofetch distrobox zenity && \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    rpm-ostree install kernel-devel kernel-devel-matched && \
    rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm && \
    KERNEL_VERSION="$(rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')" && \
    rpm-ostree install xorg-x11-drv-nvidia{,-cuda} kernel-devel-${KERNEL_VERSION} \
                       /tmp/nvidia/kmod-nvidia-${KERNEL_VERSION}-*.rpm && \
    ln -s /usr/bin/ld.bfd /etc/alternatives/ld && ln -s /etc/alternatives/ld /usr/bin/ld && \
    rm -rf /tmp/nvidia /var/* && \
    rpm-ostree override remove mesa-va-drivers && \
    rpm-ostree install libva-intel-driver intel-media-driver && \
    rpm-ostree install latte-dock && \
    rpm-ostree install gnome-software && \
    rm -rf var/log/akmods/akmods.log && \
    ostree container commit
