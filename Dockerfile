FROM debian:bookworm

# Non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    build-essential meson git wget unzip nano fakeroot devscripts ninja-build \
    quilt libexpat1-dev libxml2-dev doxygen graphviz xmlto xsltproc docbook-xsl \
    libcairo2-dev libpango1.0-dev glslang-tools hwdata xwayland libseat-dev \
    libvulkan-dev libxcb-dri3-dev libxcb-ewmh-dev libxcb-present-dev libxcb-res0-dev \
    libmd-dev libbz2-dev liblzma-dev libzstd-dev po4a libncurses-dev scdoc librsvg2-dev \
    libudev-dev libsystemd-dev libdrm-dev

# Download and install Nushell based on the system architecture
RUN ARCH=$(uname -m) && \
    case ${ARCH} in \
    x86_64) NUSHELL_ARCH="x86_64-unknown-linux-gnu" ;; \
    aarch64) NUSHELL_ARCH="aarch64-unknown-linux-gnu" ;; \
    armv7l) NUSHELL_ARCH="armv7-unknown-linux-gnueabihf" ;; \
    *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac && \
    wget https://github.com/nushell/nushell/releases/download/0.96.0/nu-0.96.0-${NUSHELL_ARCH}.tar.gz && \
    tar -xzvf nu-0.96.0-${NUSHELL_ARCH}.tar.gz && \
    mv nu-0.96.0-${NUSHELL_ARCH}/nu /usr/local/bin/ && \
    rm -rf nu-0.96.0-${NUSHELL_ARCH}.tar.gz nu-0.96.0-${NUSHELL_ARCH}

# Set up working directory
WORKDIR /build

# Set up deps directory
RUN mkdir -p deps/wayland deps/wayland-protocols deps/dpkg-dev deps/libliftoff deps/libdisplay-info deps/wlroots deps/labwc

# Copy the compositor directory
COPY compositor /build/compositor

# Logger
RUN echo "Logging the files in the /build directory" && ls -la /build

# Build and install Wayland
RUN echo "Building packages" && \
    cd compositor && \
    nu packages-build.nu



# RUN nu ls -la /build/deps/wayland    

# # Build and install Wayland protocols
# RUN mkdir wayland-protocols && cd wayland-protocols && \
#     dget http://deb.debian.org/debian/pool/main/w/wayland-protocols/wayland-protocols_1.36-1.dsc && \
#     cd wayland-protocols-1.36 && \
#     debuild -us -uc && \
#     cd .. && \
#     mv *.deb /build/deps/wayland-protocols && \
#     dpkg -i /build/deps/wayland-protocols/*.deb

# # Build and install dpkg-dev
# RUN mkdir dpkg-dev && cd dpkg-dev && \
#     dget http://deb.debian.org/debian/pool/main/d/dpkg/dpkg_1.22.7.dsc && \
#     cd dpkg-1.22.7 && \
#     debuild -us -uc && \
#     cd .. && \
#     mv *.deb /build/deps/dpkg-dev && \
#     dpkg -i /build/deps/dpkg-dev/*.deb


# # Build and install libliftoff
# RUN mkdir libliftoff && cd libliftoff && \
#     dget http://deb.debian.org/debian/pool/main/libl/libliftoff/libliftoff_0.4.1-1.dsc && \
#     cd libliftoff-0.4.1 && \
#     debuild -us -uc && \
#     cd .. && \
#     mv *.deb /build/deps/libliftoff && \
#     dpkg -i /build/deps/libliftoff/*.deb


# # Build and install libdisplay-info
# RUN mkdir libdisplay-info && cd libdisplay-info && \
#     dget http://deb.debian.org/debian/pool/main/libd/libdisplay-info/libdisplay-info_0.1.1-2.dsc && \
#     cd libdisplay-info-0.1.1 && \
#     debuild -us -uc && \
#     cd .. && \
#     mv *.deb /build/deps/libdisplay-info && \
#     dpkg -i /build/deps/libdisplay-info/*.deb

# # Build and install wlroots
# RUN apt install -y libcap-dev libegl1-mesa-dev libegl-dev libgbm-dev \
#     libgles2-mesa-dev libinput-dev libx11-xcb-dev libxcb-composite0-dev \
#     libxcb-icccm4-dev libxcb-image0-dev libxcb-render-util0-dev libxcb-xinput-dev libxkbcommon-dev

# RUN mkdir wlroots && cd wlroots && \
#     dget http://deb.debian.org/debian/pool/main/w/wlroots/wlroots_0.17.4-1.dsc && \
#     cd wlroots-0.17.4 && \
#     debuild -us -uc && \
#     cd .. && \
#     mv *.deb /build/deps/wlroots && \
#     dpkg -i /build/deps/wlroots/*.deb  


# # Build labwc
# ENV DEBEMAIL="dhruveshb@mechasystems.com"
# # Build labwc
# RUN mkdir labwc && cd labwc && \
#     wget https://github.com/labwc/labwc/archive/refs/tags/0.7.3.tar.gz -O labwc_0.7.3.orig.tar.gz && \
#     tar xf labwc_0.7.3.orig.tar.gz && \
#     cd labwc-0.7.3 && \
#     mkdir debian && cd .. \
#     dch --create -v 0.7.3-1 --package labwc 

# COPY rules /build/labwc/labwc-0.7.3/debian/rules
# COPY control /build/labwc/labwc-0.7.3/debian/control
# COPY changelog /build/labwc/labwc-0.7.3/debian/changelog
# COPY sources/* /build/labwc/labwc-0.7.3/debian/sources    

# RUN cd labwc/labwc-0.7.3 && \
#     debuild -us -uc && \
#     cd .. && \
#     mv *.deb /build/deps/labwc && \
#     dpkg -i /build/deps/labwc/*.deb

CMD ["/bin/bash"]