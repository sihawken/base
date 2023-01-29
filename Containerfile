ARG FEDORA_MAJOR_VERSION=37

FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_MAJOR_VERSION}

COPY etc /etc

COPY ublue-firstboot /usr/bin

RUN rpm-ostree override remove firefox firefox-langpacks && \
    rpm-ostree install distrobox gnome-tweaks just && \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    systemctl enable flatpak-automatic.timer && \
    ostree container commit
