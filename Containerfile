ARG FEDORA_MAJOR_VERSION=37
FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_MAJOR_VERSION}
ARG FEDORA_MAJOR_VERSION

COPY etc /etc

COPY ublue-firstboot /usr/bin

RUN rpm-ostree override remove toolbox firefox firefox-langpacks && \
    rpm-ostree install zsh neofetch distrobox zenity && \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    rpm-ostree install kernel-devel kernel-devel-matched && \
    rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm && \
    rpm-ostree override remove mesa-va-drivers && \
    rpm-ostree install libva-intel-driver intel-media-driver && \
    rpm-ostree install latte-dock && \
    rpm-ostree install gnome-software && \
    wget https://negativo17.org/repos/fedora-nvidia.repo -O /etc/yum.repos.d/fedora-nvidia.repo && \
    ostree container commit
