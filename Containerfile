ARG FEDORA_MAJOR_VERSION=37

FROM registry.hub.docker.com/library/fedora:${FEDORA_MAJOR_VERSION} AS rpm_builder

COPY usr/lib/systemd/system/openrgb.service /usr/lib/systemd/system/openrgb.service

RUN yum -y install ruby rpm-build squashfs-tools
RUN gem install fpm
RUN fpm \
    -s dir -t rpm \
    --name openrgb-service \
    --version 1 \
    --architecture all \
    --depends openrgb \
    --depends systemd \
    --description "Adds the required service file to systemd for OpenRGB to run as daemon" \
    /usr/lib/systemd/system/openrgb.service=/usr/lib/systemd/system/openrgb.service

FROM ghcr.io/ublue-os/kinoite-nvidia:latest AS system_image
ARG FEDORA_MAJOR_VERSION

# Copy the built RPM from rpm_builder
COPY --from=rpm_builder /openrgb-service-1-1.noarch.rpm /tmp/openrgb-service/openrgb-service-1-1.noarch.rpm

COPY etc /etc
COPY usr/lib/systemd/system/openrgb.service /usr/lib/systemd/system/openrgb.service

# Copy the first run zenety script
COPY ublue-firstboot /usr/bin

RUN echo "INSTALLING BASE SYSTEM ----------------------------------------------" && \
    rpm-ostree override remove toolbox firefox firefox-langpacks && \
    rpm-ostree install zsh neofetch distrobox zenity && \
    rpm-ostree install kernel-devel kernel-devel-matched && \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    echo "INSTALLING RPM-FUSION REPOS -----------------------------------------" && \
    rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm && \
    echo "INSTALLING CODEC DRIVERS --------------------------------------------" && \
    rpm-ostree override remove libavutil-free libswscale-free libswresample-free libavformat-free libavcodec-free libavfilter-free libpostproc-free \
        --install=ffmpeg-libs --install=ffmpeg --install=libavcodec-freeworld && \
    echo "INSTALLING INTEL MEDIA DRIVERS --------------------------------------" && \
    rpm-ostree install libva-intel-driver intel-media-driver && \
    echo "INSTALLING KDE ADD-ONS ----------------------------------------------" && \
    rpm-ostree install bismuth && \
    echo "INSTALLING OPENRGB --------------------------------------------------" && \
    rpm-ostree install openrgb && \
    rpm-ostree install /tmp/openrgb-service/openrgb-service-1-1.noarch.rpm && \
    rm -rf /tmp/openrgb-service && \
    systemctl enable openrgb && \
    ostree container commit
