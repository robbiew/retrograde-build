FROM --platform=linux/amd64 ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV GOPATH=/go
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
ENV CC=gcc
ENV CXX=g++

# Install basic build dependencies
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
    gcc \
    g++ \
    libc6-dev \
    libncurses5-dev \
    libncursesw5-dev \
    zlib1g-dev \
    libssl-dev \
    libreadline-dev \
    libsqlite3-dev \
    tk-dev \
    libgdbm-dev \
    libc6-dev \
    libbz2-dev \
    libffi-dev \
    flex \
    bison \
    gawk \
    gettext \
    texinfo \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install dosemu2
RUN add-apt-repository ppa:dosemu2/ppa && \
    apt-get update && \
    apt-get install -y dosemu2 && \
    rm -rf /var/lib/apt/lists/*

# Install Go
RUN apt-get update && \
    apt-get install -y golang && \
    rm -rf /var/lib/apt/lists/*

# Create working directories
RUN mkdir -p /build /output /go

# Set working directory
WORKDIR /build

# Create scripts directory
RUN mkdir -p /scripts

# Clone external binary repositories
RUN git clone https://github.com/pgul/binkd.git /build/binkd && \
    git clone https://github.com/robbiew/stormedit.git /build/stormedit

# Set up static linking flags
ENV LDFLAGS="-static -s"
ENV CFLAGS="-O2 -static"
ENV CXXFLAGS="-O2 -static"

# Create entry point script
RUN echo '#!/bin/bash\n\
echo "=== x86_64 Build Container ==="\n\
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
echo ""\n\
exec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]