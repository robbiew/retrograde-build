FROM ubuntu:24.04

# Set environment variables for cross-compilation
ENV DEBIAN_FRONTEND=noninteractive
ENV GOPATH=/go
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Cross-compilation environment for ARM64
ENV CC=aarch64-linux-gnu-gcc
ENV CXX=aarch64-linux-gnu-g++
ENV AR=aarch64-linux-gnu-ar
ENV STRIP=aarch64-linux-gnu-strip
ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV GOOS=linux
ENV GOARCH=arm64
ENV CGO_ENABLED=1

# Install cross-compilation toolchain and dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    wget \
    curl \
    git \
    build-essential \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    make \
    flex \
    bison \
    gawk \
    gettext \
    texinfo \
    sudo \
    unzip \
    crossbuild-essential-arm64 \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    && rm -rf /var/lib/apt/lists/*

# Install Go with ARM64 support
RUN wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz && \
    rm go1.21.5.linux-amd64.tar.gz

# Create working directories
RUN mkdir -p /build /output /go

# Set working directory
WORKDIR /build

# Create scripts directory
RUN mkdir -p /scripts

# Clone external binary repositories
RUN git clone https://github.com/pgul/binkd.git /build/binkd && \
    git clone https://github.com/robbiew/stormedit.git /build/stormedit && \
    git clone https://gitlab.synchro.net/main/sbbs.git /build/sbbs

# Set up cross-compilation flags for static ARM64 builds
ENV LDFLAGS="-static -s"
ENV CFLAGS="-O2 -static"
ENV CXXFLAGS="-O2 -static"

# Create entry point script
RUN echo '#!/bin/bash\n\
echo "=== ARM64 Cross-Compilation Build Container ==="\n\
echo "Cross-compilation toolchain: $(aarch64-linux-gnu-gcc --version | head -1)"\n\
echo "Target architecture: $(aarch64-linux-gnu-gcc -dumpmachine)"\n\
echo "Available build scripts:"\n\
echo "  /scripts/build-husky.sh - Build Husky Project binaries"\n\
echo "  /scripts/build-binkd.sh - Build Binkd"\n\
echo "  /scripts/build-stormedit.sh - Build Stormedit"\n\
echo "  /scripts/build-all.sh - Build everything"\n\
echo ""\n\
echo "Output directory: /output"\n\
echo "Source directories:"\n\
echo "  /build/husky - Husky Project (created by build script)"\n\
echo "  /build/binkd - Binkd"\n\
echo "  /build/stormedit - Stormedit"\n\
echo "  /build/sbbs - Synchronet BBS (SEXYZ)"\n\
echo ""\n\
exec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]