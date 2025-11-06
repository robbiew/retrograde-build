# Quick Start Guide

## TL;DR - Build Everything

```bash
# From the DockerBuilds repository root
./build.sh --all both
```

This will:
1. Build Docker images for both ARM64 and x86_64
2. Compile all components (Husky, Binkd, Stormedit) for both architectures
3. Output static binaries to `../output/` (repository root)

## Quick Commands

### Build specific architecture only
```bash
# From repository root
./build.sh --all arm64        # ARM64 only
./build.sh --all x86_64       # x86_64 only
```

### Build specific components
```bash
# From repository root
./build.sh --husky both       # Husky Project only
./build.sh --binkd both       # Binkd only  
./build.sh --stormedit both   # Stormedit only
```

### Combine options
```bash
# From repository root
./build.sh --husky arm64      # Husky for ARM64 only
./build.sh --binkd x86_64     # Binkd for x86_64 only
```

## Output

After successful build, find your binaries in the repository root:
```
../output/
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
# From repository root
./build.sh --help
```

For detailed documentation, see [README.md](README.md).