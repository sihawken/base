ARG FEDORA_MAJOR_VERSION=37

FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_MAJOR_VERSION}

COPY etc /etc

COPY ublue-firstboot /usr/bin

RUN rpm-ostree override remove toolbox firefox firefox-langpacks && \
    rpm-ostree install zsh neofetch distrobox && \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer

# Update to the xanmod kernel
RUN wget https://copr.fedorainfracloud.org/coprs/rmnscnce/kernel-xanmod/repo/fedora-${FEDORA_MAJOR_VERSION}/rmnscnce-kernel-xanmod-fedora-${FEDORA_MAJOR_VERSION}.repo -O /etc/yum.repos.d/rmnscnce-kernel-xanmod-fedora-${FEDORA_MAJOR_VERSION}.repo && \
    rpm-ostree override remove kernel kernel-modules-extra kernel-core kernel-modules --install kernel-xanmod-edge --install kernel-xanmod-edge-core --install kernel-xanmod-edge-modules

# Install the rpmfusion repositories
RUN rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm \
https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm

# Replace media drivers
RUN rpm-ostree override remove mesa-va-drivers --install mesa-va-drivers-freeworld && \
rpm-ostree install mesa-vdpau-drivers-freeworld && \
rpm-ostree install libva-intel-driver intel-media-driver

# Add nvidia drivers
RUN wget https://negativo17.org/repos/fedora-nvidia.repo -O /etc/yum.repos.d/fedora-nvidia.repo && \
rpm-ostree override remove nvidia-gpu-firmware --install nvidia-driver --install nvidia-driver-cuda --install nvidia-settings

RUN ostree container commit
