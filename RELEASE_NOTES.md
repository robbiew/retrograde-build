# External Binary Release Notes

Static external binaries used by [Retrograde BBS](https://github.com/robbiew/retrograde).

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

## Architecture Support

All binaries are provided for:
- **x86_64** (Intel/AMD 64-bit)
- **ARM64** (AArch64)

## Build Information

These binaries are built using Docker containers for consistency and reproducibility. The build process:
- Uses official upstream source repositories
- Applies static linking where possible for maximum compatibility
- Includes comprehensive testing and validation
- Automatically uploads to Retrograde BBS releases

## Usage

These binaries are automatically integrated into Retrograde BBS installations and should be placed in the appropriate `bin/external/` directory structure.

For manual installation or standalone use, ensure the binaries have execute permissions and are accessible in your system PATH.