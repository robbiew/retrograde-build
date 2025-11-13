#!/bin/bash

# Build SEXYZ (X/Y/Z-modem File Transfer Protocol)
# Simplified standalone version for Retrograde BBS Docker builds

set -e

BUILD_DIR="/build"
ARCH_NAME=""

cd "$BUILD_DIR"

echo "Building SEXYZ - X/Y/Z-modem File Transfer Protocol"

# Detect architecture and set cross-compilation environment
if [ -n "$FORCE_ARCH" ]; then
    ARCH_NAME="$FORCE_ARCH"
    echo "Using forced architecture: $ARCH_NAME"
    elif [ "$ARCH" = "arm64" ]; then
    ARCH_NAME="arm64"
    elif [ "$(uname -m)" = "aarch64" ]; then
    ARCH_NAME="arm64"
else
    ARCH_NAME="x86_64"
fi

echo "Building for $ARCH_NAME"

# Set cross-compilation environment for ARM64
if [ "$ARCH_NAME" = "arm64" ]; then
    export CC="aarch64-linux-gnu-gcc"
    export CXX="aarch64-linux-gnu-g++"
    export AR="aarch64-linux-gnu-ar"
    export STRIP="aarch64-linux-gnu-strip"
    COMPILER="$CC"
else
    COMPILER="gcc"
fi

# Create SEXYZ source directory
mkdir -p sexyz
cd sexyz

# Create minimal SEXYZ implementation
cat > sexyz.c << 'SEXYZ_SOURCE_END'
/*
 * SEXYZ - X/Y/Z-modem File Transfer Protocol
 * Minimal standalone implementation for Retrograde BBS
 * Based on Synchronet BBS SEXYZ
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <signal.h>

#define VERSION "1.0.0"
#define FALSE 0
#define TRUE 1

static void show_usage(const char* progname) {
    printf("SEXYZ v%s - X/Y/Z-modem File Transfer Protocol\n", VERSION);
    printf("Usage: %s [options] <command> [files...]\n\n", progname);

    printf("Commands:\n");
    printf("  send <file>...     Send file(s) using Z-modem\n");
    printf("  receive [dir]      Receive files using Z-modem\n");
    printf("  xsend <file>       Send file using X-modem\n");
    printf("  xreceive <file>    Receive file using X-modem\n");
    printf("  ysend <file>       Send file using Y-modem\n");
    printf("  yreceive           Receive files using Y-modem\n");
    printf("  help               Show this help\n");

    printf("\nOptions:\n");
    printf("  -h, --help         Show this help\n");
    printf("  -v, --version      Show version information\n");
    printf("  -q, --quiet        Quiet operation\n");
    printf("  -d, --debug        Debug mode\n");
}

static void show_version(void) {
    printf("SEXYZ v%s - X/Y/Z-modem File Transfer Protocol\n", VERSION);
    printf("Standalone build for Retrograde BBS\n");
    printf("Based on Synchronet BBS SEXYZ by Rob Swindell\n");
}

int main(int argc, char *argv[]) {
    int quiet = 0;
    int debug = 0;
    int i;

    // Parse options
    for (i = 1; i < argc && argv[i][0] == '-'; i++) {
        if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            show_usage(argv[0]);
            return 0;
        } else if (strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "--version") == 0) {
            show_version();
            return 0;
        } else if (strcmp(argv[i], "-q") == 0 || strcmp(argv[i], "--quiet") == 0) {
            quiet = 1;
        } else if (strcmp(argv[i], "-d") == 0 || strcmp(argv[i], "--debug") == 0) {
            debug = 1;
        } else {
            fprintf(stderr, "Unknown option: %s\n", argv[i]);
            show_usage(argv[0]);
            return 1;
        }
    }

    if (i >= argc) {
        show_usage(argv[0]);
        return 1;
    }

    const char* command = argv[i];

    if (!quiet) {
        printf("SEXYZ v%s - %s mode\n", VERSION, command);
    }

    if (strcmp(command, "help") == 0) {
        show_usage(argv[0]);
        return 0;
    } else if (strcmp(command, "send") == 0) {
        if (i + 1 >= argc) {
            fprintf(stderr, "Error: No files specified for send\n");
            return 1;
        }
        printf("Z-modem send mode\n");
        for (int j = i + 1; j < argc; j++) {
            printf("Preparing to send: %s\n", argv[j]);
            // TODO: Implement Z-modem send
        }
        printf("Note: Full Z-modem implementation pending\n");
    } else if (strcmp(command, "receive") == 0) {
        printf("Z-modem receive mode\n");
        if (i + 1 < argc) {
            printf("Receive directory: %s\n", argv[i + 1]);
        }
        // TODO: Implement Z-modem receive
        printf("Note: Full Z-modem implementation pending\n");
    } else if (strcmp(command, "xsend") == 0) {
        if (i + 1 >= argc) {
            fprintf(stderr, "Error: No file specified for X-modem send\n");
            return 1;
        }
        printf("X-modem send mode\n");
        printf("File to send: %s\n", argv[i + 1]);
        // TODO: Implement X-modem send
        printf("Note: Full X-modem implementation pending\n");
    } else if (strcmp(command, "xreceive") == 0) {
        if (i + 1 >= argc) {
            fprintf(stderr, "Error: No filename specified for X-modem receive\n");
            return 1;
        }
        printf("X-modem receive mode\n");
        printf("File to receive: %s\n", argv[i + 1]);
        // TODO: Implement X-modem receive
        printf("Note: Full X-modem implementation pending\n");
    } else if (strcmp(command, "ysend") == 0) {
        if (i + 1 >= argc) {
            fprintf(stderr, "Error: No file specified for Y-modem send\n");
            return 1;
        }
        printf("Y-modem send mode\n");
        printf("File to send: %s\n", argv[i + 1]);
        // TODO: Implement Y-modem send
        printf("Note: Full Y-modem implementation pending\n");
    } else if (strcmp(command, "yreceive") == 0) {
        printf("Y-modem receive mode\n");
        // TODO: Implement Y-modem receive
        printf("Note: Full Y-modem implementation pending\n");
    } else {
        fprintf(stderr, "Unknown command: %s\n", command);
        fprintf(stderr, "Use '%s help' for available commands\n", argv[0]);
        return 1;
    }

    return 0;
}
SEXYZ_SOURCE_END

# Build SEXYZ
echo "Compiling SEXYZ..."
if [ -n "$CC" ]; then
    echo "Using cross-compiler: $CC"
else
    echo "Using system compiler: gcc"
fi

$COMPILER -static -O2 -Wall -o sexyz sexyz.c -lm

if [ $? -eq 0 ]; then
    echo "SEXYZ build completed successfully!"
    ls -la sexyz
    file sexyz
    
    # Test the binary
    echo "Testing SEXYZ binary:"
    ./sexyz --version
    
    # Copy to output directory
    mkdir -p "/output/sexyz/$ARCH_NAME"
    cp sexyz "/output/sexyz/$ARCH_NAME/"
    echo "SEXYZ binary copied to /output/sexyz/$ARCH_NAME/"
    
    echo "SEXYZ build for $ARCH_NAME completed successfully!"
else
    echo "SEXYZ build failed!"
    exit 1
fi