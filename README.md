# External Binary Builder for Retrograde BBS

This repository builds static external binaries used by [Retrograde BBS](https://github.com/robbiew/retrograde).

## What This Does

Builds static binaries for Fidonet utilities:
- **HPT** - Husky message processor
- **Binkd** - Fidonet mailer daemon  
- **StormEdit** - BBS message editor

These binaries are built using Docker containers for consistency and automatically uploaded to Retrograde BBS releases.

## Quick Start

```bash
# Build all binaries for both architectures
./build.sh --all both

# Build specific component for specific architecture  
./build.sh --husky x86_64
./build.sh --binkd arm64
./build.sh --stormedit both

# Create release archives
./scripts/create-release-archives.sh

# Upload to retrograde releases (requires GitHub token)
./scripts/upload-to-retrograde-release.sh v1.0.1
```

## Architecture Support

- **x86_64** (Intel/AMD 64-bit)
- **ARM64** (Apple Silicon, ARM64 servers)

## Automated Builds

GitHub Actions automatically:
- Builds binaries weekly (Mondays 2 AM UTC)
- Uploads to Retrograde BBS releases
- Supports manual triggers

## For Retrograde Users

You don't need this repository. Retrograde's `install.sh` automatically downloads the pre-built binaries.

## For Developers

This separation allows:
- Consistent static builds across platforms
- Independent updates of external dependencies
- Automated cross-platform binary generation
- Simplified Retrograde BBS codebase

Built binaries are distributed via [Retrograde BBS releases](https://github.com/robbiew/retrograde/releases), not stored in git.
