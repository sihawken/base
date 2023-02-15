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

FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_MAJOR_VERSION} AS nvidia_builder
ARG FEDORA_MAJOR_VERSION

# Build Nvidia driver kernel module
RUN wget https://negativo17.org/repos/fedora-nvidia.repo -O /etc/yum.repos.d/fedora-nvidia.repo && \
    rpm-ostree install mock nvidia-driver nvidia-driver-cuda binutils \
                       kernel-devel-$(rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}') && \
    ln -s /usr/bin/ld.bfd /etc/alternatives/ld && ln -s /etc/alternatives/ld /usr/bin/ld && \
    akmods --force --kernels "$(rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"

FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_MAJOR_VERSION} AS system_image
ARG FEDORA_MAJOR_VERSION
 
# Copy the Nvidia driver kernel module from nvidia_builder
COPY --from=nvidia_builder /var/cache/akmods/nvidia /tmp/nvidia

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
    echo "INSTALL NEGATIVO17 NVIDIA FEDORA REPO & DRIVERS ---------------------" && \
    wget https://negativo17.org/repos/fedora-nvidia.repo -O /etc/yum.repos.d/fedora-nvidia.repo && \
    KERNEL_VERSION="$(rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')" && \
    rpm-ostree install nvidia-driver nvidia-driver-cuda nvenc nvidia-driver-NvFBCOpenGL \
        /tmp/nvidia/kmod-nvidia-${KERNEL_VERSION}-*.rpm && \
    ln -s /usr/bin/ld.bfd /etc/alternatives/ld && ln -s /etc/alternatives/ld /usr/bin/ld && \
    rm -rf /tmp/nvidia /var/* && \
    echo "INSTALLING NVIDIA-XRUN ----------------------------------------------" && \
    wget https://copr.fedorainfracloud.org/coprs/ekultails/nvidia-xrun/repo/fedora-37/ekultails-nvidia-xrun-fedora-37.repo -O /etc/yum.repos.d/ekultails-nvidia-xrun-fedora-37.repo && \
    rpm-ostree install nvidia-xrun && \
    systemctl enable nvidia-xrun-pm && \
    echo "INSTALL CODEC DRIVERS -----------------------------------------------" && \
    rpm-ostree override remove libavutil-free libswscale-free libswresample-free libavformat-free libavcodec-free libavfilter-free libpostproc-free \
        --install=ffmpeg-libs --install=ffmpeg --install=libavcodec-freeworld && \
    echo "INSTALL INTEL MEDIA DRIVERS -----------------------------------------" && \
    rpm-ostree install libva-intel-driver intel-media-driver && \
    echo "INSTALLING OPENRGB --------------------------------------------------" && \
    rpm-ostree install openrgb && \
    rpm-ostree install /tmp/openrgb-service/openrgb-service-1-1.noarch.rpm && \
    rm -rf /tmp/openrgb-service && \
    systemctl enable openrgb && \
    ostree container commit
