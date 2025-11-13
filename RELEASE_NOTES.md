# External Binary Release Notes

Static external binaries built for [Retrograde BBS](https://github.com/robbiew/retrograde).

This repository provides pre-compiled, static-linked binaries for external programs used by Retrograde BBS, including FidoNet mail processing, file transfer protocols, and BBS utilities.

## Included Components

### **Husky Project** - FidoNet mail system toolkit

Complete suite of FidoNet mail processing utilities:

**Core Mail Processing:**

- **hpt** - Main HPT mail tosser and scanner
- **htick** - File processing and hatching utility
- **hptlink** - Link maintenance and statistics
- **hpttree** - Area tree display utility

**Packet and Message Utilities:**

- **pktinfo** - Packet information display
- **txt2pkt** - Text to packet converter
- **tpkt** - Packet testing and validation
- **gnmsgid** - Message ID generator

**Configuration Tools:**

- **tparser** - Configuration parser and validator
- **linked** - Link information utility

### **Binkd** - FidoNet mailer daemon

High-performance FidoNet-compatible mailer for reliable message and file transfers over TCP/IP connections.

### **StormEdit** - BBS external message editor  

Full-screen ANSI message editor designed for BBS environments, providing enhanced editing capabilities for bulletin board users.

### **SEXYZ** - X/Y/Z-modem file transfer protocols

X/Y/Z-modem file transfer protocol implementation based on Synchronet BBS SEXYZ:

**Protocol Support:**

- **X-modem** - Single file transfers with checksum verification
- **Y-modem** - Batch file transfers with CRC error checking  
- **Z-modem** - Advanced batch transfers with crash recovery
- **Unified interface** - Compatible with Synchronet SEXYZ command format

**Features:**

- Static binaries for maximum compatibility
- Cross-platform support (x86_64 and ARM64)
- Standalone implementation optimized for BBS environments
- Command-line interface compatible with existing SEXYZ usage

## Architecture Support

All binaries are provided for:

- **x86_64** (Intel/AMD 64-bit)
- **ARM64** (AArch64)

## Build Information

These binaries are built using Docker containers for consistency and reproducibility across platforms.

**Build Features:**

- Uses official upstream source repositories
- Static linking for maximum compatibility and portability
- Cross-compilation support for multiple architectures
- Automated testing and validation
- GitHub Actions CI/CD pipeline
- Automatic release packaging and distribution

**Supported Architectures:**

- **x86_64** - Intel/AMD 64-bit systems
- **ARM64** - AArch64 systems (Apple Silicon, ARM servers)

## Installation & Usage

### **Automatic Installation**

These binaries are automatically downloaded and installed by the [Retrograde BBS install script](https://github.com/robbiew/retrograde). No manual intervention required.

### **Manual Installation**

For standalone use or manual installation:

1. Download the appropriate archive for your architecture from the [releases page](https://github.com/robbiew/retrograde/releases)
2. Extract to your desired location (typically `bin/external/`)
3. Ensure binaries have execute permissions: `chmod +x *`
4. Add to your system PATH if needed

### **Integration**

Binaries are designed to integrate seamlessly with Retrograde BBS configuration and can be used by other compatible BBS software.

## Release Frequency

- **Weekly automated builds** every Monday at 2 AM UTC
- **Manual builds** can be triggered for urgent updates
- **Version tracking** follows upstream project releases
- **Archive retention** available for previous builds
