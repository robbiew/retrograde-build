# Retrograde BBS Static Binary Builders

This Docker build system creates static binaries for the Retrograde BBS project on both ARM64 and x86_64 architectures. The binaries are designed to be bundled with GitHub releases and run on various Linux distributions without dependency issues.

## Overview

This build system creates Docker containers for cross-platform compilation of:

1. **Husky Project** (`hpt`, `htick`, and related utilities)
2. **Binkd** (Binkley-style FidoNet mailer)
3. **Stormedit** (BBS message editor)

## Project Structure

```
retrograde-builders/
├── arm64/                  # ARM64 Docker build
│   └── Dockerfile
├── x86_64/                 # x86_64 Docker build
│   └── Dockerfile
├── scripts/                # Build scripts
│   ├── build-husky.sh     # Husky Project build script
│   ├── build-binkd.sh     # Binkd build script
│   ├── build-stormedit.sh # Stormedit build script
│   └── build-all.sh       # Master build script
└── README.md              # This file

# Output is generated in the main output/ directory at repository root
```

## Prerequisites

- Docker with BuildKit support
- Docker Buildx for multi-platform builds (if building on different architecture)
- At least 4GB free disk space per architecture
- Internet connection for downloading dependencies

## Building Docker Images

### Build ARM64 Image

```bash
cd retrograde-builders/arm64
docker build --platform linux/arm64 -t retrograde-builder:arm64 .
```

### Build x86_64 Image

```bash
cd retrograde-builders/x86_64
docker build --platform linux/amd64 -t retrograde-builder:x86_64 .
```

### Build Both Architectures (Multi-platform)

```bash
# Create a buildx builder that supports multiple platforms
docker buildx create --name multi-arch-builder --use

# Build ARM64
docker buildx build --platform linux/arm64 -t retrograde-builder:arm64 --load arm64/

# Build x86_64
docker buildx build --platform linux/amd64 -t retrograde-builder:x86_64 --load x86_64/
```

## Running Builds

Use the main build script from the repository root:

```bash
# From DockerBuilds repository root
./build.sh --all both         # Build all components for both architectures
./build.sh --husky x86_64     # Build only Husky for x86_64
./build.sh --binkd arm64      # Build only Binkd for ARM64
```

### Alternative: Direct Container Usage

For advanced users or debugging, you can run containers directly:

```bash
# Build only Husky Project (using repository root script)
./build.sh --husky arm64

# Or run container directly (from retrograde-builders directory)
docker run --rm -v $(pwd)/../output:/output retrograde-builder:arm64 /scripts/build-all.sh --husky
```

### Interactive Container

```bash
# Start interactive container (from retrograde-builders directory)
docker run --rm -it -v $(pwd)/../output:/output retrograde-builder:arm64 /bin/bash

# Inside the container, run individual build scripts
/scripts/build-husky.sh
/scripts/build-binkd.sh
/scripts/build-stormedit.sh
```

## Output Structure

After successful builds, binaries will be available in:

```
output/
├── husky/
│   ├── arm64/
│   │   ├── hpt
│   │   ├── htick
│   │   └── fidoconf
│   └── x86_64/
│       ├── hpt
│       ├── htick
│       └── fidoconf
├── binkd/
│   ├── arm64/
│   │   └── binkd
│   └── x86_64/
│       └── binkd
├── stormedit/
│   ├── arm64/
│   │   ├── stormedit
│   │   └── editorbd.ans
│   └── x86_64/
│       ├── stormedit
│       └── editorbd.ans
├── build-summary-arm64.txt
└── build-summary-x86_64.txt
```

## Build Scripts Details

### build-husky.sh

- Uses the official Husky Project installation script from `huskyproject/huskybse`
- Downloads and runs `init_build` script
- Configures `huskymak.cfg` for static linking (`DYNLIBS=0`)
- Builds `hpt`, `htick`, and related utilities
- Outputs verified static binaries

### build-binkd.sh

- Clones the Binkd repository
- Attempts autotools configuration if available
- Falls back to existing Makefiles
- Applies static linking flags
- Builds the `binkd` binary

### build-stormedit.sh

- Clones the Stormedit repository
- Initializes git submodules (for MagiDoor dependency)
- Uses CMake build system with static linking flags
- Builds `stormedit` binary and copies required assets
- Includes the `editorbd.ans` backdrop file

### build-all.sh

- Orchestrates all individual build scripts
- Provides command-line options for selective building
- Generates build summaries
- Handles errors gracefully and continues with other builds

## Static Linking Strategy

All binaries are compiled with static linking to ensure maximum portability:

- `LDFLAGS="-static -s"` - Static linking and strip symbols
- `CFLAGS="-O2 -static"` - Optimization and static compilation
- `DYNLIBS=0` - Husky-specific static library configuration
- `CGO_ENABLED=0` - Go static compilation (if applicable)

## Troubleshooting

### Build Failures

1. **Insufficient Memory**: Ensure Docker has at least 2GB RAM allocated
2. **Network Issues**: Check internet connectivity for downloading dependencies
3. **Architecture Mismatch**: Ensure you're building for the correct target platform

### Binary Verification

Each build script verifies static linking using:
```bash
file binary_name          # Shows binary type and architecture
ldd binary_name           # Shows dynamic dependencies (should show "statically linked")
```

### Common Issues

1. **Husky Build Fails**: 
   - Check that the official installation script is accessible
   - Verify all required build dependencies are installed in the container

2. **Binkd Build Fails**:
   - May need manual Makefile selection for specific platforms
   - Check for autotools availability

3. **Stormedit Build Fails**:
   - Ensure git submodules are properly initialized
   - Verify CMake and C++11 compiler availability

## Container Environment

Each container includes:

- Ubuntu 24.04 LTS base
- dosemu2 (for DOS compatibility testing)
- Go compiler
- Complete build toolchain (gcc, g++, make, cmake, autotools)
- Development libraries (ncurses, zlib, openssl, etc.)
- Git for source code management

## Integration with CI/CD

This build system is designed to integrate with GitHub Actions for automated binary building:

```yaml
# Example GitHub Actions workflow snippet
- name: Build ARM64 Binaries
  run: |
    docker build --platform linux/arm64 -t retrograde-builder:arm64 arm64/
    docker run --rm -v $(pwd)/output:/output retrograde-builder:arm64 /scripts/build-all.sh

- name: Build x86_64 Binaries  
  run: |
    docker build --platform linux/amd64 -t retrograde-builder:x86_64 x86_64/
    docker run --rm -v $(pwd)/output:/output retrograde-builder:x86_64 /scripts/build-all.sh
```

## Contributing

When modifying build scripts:

1. Test on both architectures
2. Verify static linking with `ldd` command
3. Update documentation if changing build process
4. Ensure error handling is robust

## License

This build system is provided as-is for the Retrograde BBS project. Individual components (Husky, Binkd, Stormedit) retain their respective licenses.

## Support

For issues specific to this build system, open an issue in the Retrograde BBS repository. For issues with individual components, refer to their respective project repositories:

- [Husky Project](https://github.com/huskyproject)
- [Binkd](https://github.com/pgul/binkd)
- [Stormedit](https://github.com/robbiew/stormedit)
- [Retrograde BBS](https://github.com/robbiew/retrograde)