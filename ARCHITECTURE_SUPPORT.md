# macOS Architecture Support

## Overview

Deskflow supports both Intel (x86_64) and Apple Silicon (arm64) architectures on macOS. The build system automatically detects your Mac's architecture and builds the appropriate binary.

## Automatic Architecture Detection

The `build-macos.sh` script automatically:

1. Detects your Mac's architecture using `uname -m`
2. Sets the appropriate CMake architecture flag
3. Uses the correct Homebrew paths for dependencies
4. Builds a native binary for your system

## Supported Architectures

- **Apple Silicon (arm64)**: M1, M2, M3, M4 Macs
- **Intel (x86_64)**: Intel-based Macs

## Building for Your Architecture

Simply run the build script - it will automatically detect and build for your architecture:

```bash
./build-macos.sh
```

Or for a Debug build:

```bash
./build-macos.sh Debug
```

## What the Script Does

1. **Detects Architecture**: Uses `uname -m` to determine if you're on arm64 or x86_64
2. **Checks Dependencies**: Verifies cmake, Homebrew, Qt, and OpenSSL are installed
3. **Configures Build**: Sets `CMAKE_OSX_ARCHITECTURES` to match your system
4. **Builds Project**: Compiles using all available CPU cores
5. **Signs Application**: Ad-hoc signs the app bundle for local development

## Homebrew Path Handling

The script correctly handles different Homebrew installation paths:

- **Apple Silicon**: `/opt/homebrew`
- **Intel**: `/usr/local`

This is done using `brew --prefix` which automatically returns the correct path for your system.

## Cross-Compilation Notes

**Important**: This script builds native binaries only. It does NOT create universal (fat) binaries that work on both architectures.

If you need to:

- Build on Apple Silicon for Intel: You cannot do this with this script
- Build on Intel for Apple Silicon: You cannot do this with this script
- Create universal binaries: This is not currently supported by the build script

Each architecture must be built on its respective hardware.

## Verification

After building, you can verify the architecture of your binary:

```bash
# Check the architecture of the main executable
file build/bin/Deskflow.app/Contents/MacOS/deskflow-core

# Expected output on Apple Silicon:
# Mach-O 64-bit executable arm64

# Expected output on Intel:
# Mach-O 64-bit executable x86_64
```

Or use `lipo`:

```bash
lipo -info build/bin/Deskflow.app/Contents/MacOS/deskflow-core
```

## CI/CD Support

The project's CI/CD pipeline builds for both architectures:

- **macos-arm64**: Builds on macos-15 runners
- **macos-x64**: Builds on macos-15-intel runners

See `.github/workflows/continuous-integration.yml` for configuration details.

## Deployment Targets

- **Apple Silicon**: macOS 14.0+ (Sonoma and later)
- **Intel**: macOS 12.0+ (Monterey and later)

These are set in the CI configuration and can be adjusted if needed.

## Troubleshooting

### Wrong Architecture Binary

If you accidentally installed a binary for the wrong architecture, you'll see errors when trying to run the app. To fix:

1. Remove the old app: `rm -rf /Applications/Deskflow.app`
2. Rebuild for your architecture: `./build-macos.sh`
3. Copy the new binary: `cp -R build/bin/Deskflow.app /Applications/`

### Dependencies Not Found

If Qt or OpenSSL aren't found, the script will attempt to install them via Homebrew. Make sure Homebrew is installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Build Fails on Intel Mac

If you're on an Intel Mac and the build fails, ensure you have:

1. Xcode Command Line Tools: `xcode-select --install`
2. Homebrew installed in `/usr/local`
3. Qt and OpenSSL installed: `brew install qt openssl@3`

## Summary

✅ **Current Status**: Fully supports both architectures
✅ **Automatic Detection**: Script detects and builds for your architecture
✅ **Tested in CI**: Both architectures are built and tested automatically
✅ **Ready to Use**: Just run `./build-macos.sh` on any Mac
