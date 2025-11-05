# Quick Start Guide

## TL;DR - Build Everything

```bash
cd retrograde-builders
./build.sh
```

This will:
1. Build Docker images for both ARM64 and x86_64
2. Compile all components (Husky, Binkd, Stormedit) for both architectures
3. Output static binaries to `./output/`

## Quick Commands

### Build specific architecture only
```bash
./build.sh arm64        # ARM64 only
./build.sh x86_64       # x86_64 only
```

### Build specific components
```bash
./build.sh --husky      # Husky Project only
./build.sh --binkd      # Binkd only  
./build.sh --stormedit  # Stormedit only
```

### Combine options
```bash
./build.sh --husky arm64    # Husky for ARM64 only
./build.sh --clean --binkd  # Clean output and build Binkd for both archs
```

## Output

After successful build, find your binaries in:
```
output/
├── husky/
│   ├── arm64/hpt, htick, fidoconf
│   └── x86_64/hpt, htick, fidoconf
├── binkd/
│   ├── arm64/binkd
│   └── x86_64/binkd
└── stormedit/
    ├── arm64/stormedit, editorbd.ans
    └── x86_64/stormedit, editorbd.ans
```

## Requirements

- Docker with BuildKit support
- 4GB free space per architecture
- Internet connection

## Help

```bash
./build.sh --help
```

For detailed documentation, see [README.md](README.md).