#!/bin/bash
# Build script for Deskflow on macOS
# SPDX-FileCopyrightText: (C) 2025 Deskflow Developers
# SPDX-License-Identifier: MIT
# This script automatically detects your Mac architecture (Intel x86_64 or Apple Silicon arm64)
# and builds the project with proper paths for Homebrew dependencies

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Deskflow Build Script for macOS ===${NC}"

# Detect architecture
ARCH=$(uname -m)
echo -e "${GREEN}Detected architecture: $ARCH${NC}"

if [ "$ARCH" = "arm64" ]; then
    CMAKE_ARCH="arm64"
    echo -e "${GREEN}Building for Apple Silicon (arm64)${NC}"
elif [ "$ARCH" = "x86_64" ]; then
    CMAKE_ARCH="x86_64"
    echo -e "${GREEN}Building for Intel (x86_64)${NC}"
else
    echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
    exit 1
fi

# Check for required tools
echo -e "\n${GREEN}Checking dependencies...${NC}"

if ! command -v cmake &> /dev/null; then
    echo -e "${RED}Error: cmake not found. Install with: brew install cmake${NC}"
    exit 1
fi

if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error: Homebrew not found. Install from https://brew.sh${NC}"
    exit 1
fi

# Check for Qt and OpenSSL
if ! brew list qt &> /dev/null; then
    echo -e "${YELLOW}Qt not found. Installing...${NC}"
    brew install qt
fi

if ! brew list openssl@3 &> /dev/null; then
    echo -e "${YELLOW}OpenSSL 3 not found. Installing...${NC}"
    brew install openssl@3
fi

# Get paths
QT_PATH=$(brew --prefix qt)
OPENSSL_PATH=$(brew --prefix openssl@3)
SDKROOT=$(xcrun --show-sdk-path)

echo -e "${GREEN}Using Qt from: $QT_PATH${NC}"
echo -e "${GREEN}Using OpenSSL from: $OPENSSL_PATH${NC}"
echo -e "${GREEN}Using SDK: $SDKROOT${NC}"

# Build type (default to Release)
BUILD_TYPE="${1:-Release}"
BUILD_DIR="build"

echo -e "\n${GREEN}Configuring project (Build Type: $BUILD_TYPE)...${NC}"

# Configure
cmake -S. -B"$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_PREFIX_PATH="$QT_PATH;$OPENSSL_PATH" \
    -DCMAKE_OSX_ARCHITECTURES="$CMAKE_ARCH" \
    -DCMAKE_OSX_SYSROOT="$SDKROOT"

if [ $? -ne 0 ]; then
    echo -e "${RED}Configuration failed!${NC}"
    exit 1
fi

echo -e "\n${GREEN}Building project...${NC}"

# Build using all available cores
NCORES=$(sysctl -n hw.ncpu)
cmake --build "$BUILD_DIR" -j"$NCORES"

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo -e "\n${GREEN}Signing application...${NC}"
codesign --force --deep --sign - "$BUILD_DIR/bin/Deskflow.app"

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Warning: Code signing failed. The app may not work with Accessibility permissions.${NC}"
else
    echo -e "${GREEN}Application signed successfully.${NC}"
fi

echo -e "\n${GREEN}=== Build Successful! ===${NC}"
echo -e "Application bundle: ${GREEN}$BUILD_DIR/bin/Deskflow.app${NC}"
echo -e "Core executable: ${GREEN}$BUILD_DIR/bin/Deskflow.app/Contents/MacOS/deskflow-core${NC}"
echo -e "\nTo run the app: ${YELLOW}open $BUILD_DIR/bin/Deskflow.app${NC}"
echo -e "To run tests: ${YELLOW}$BUILD_DIR/bin/legacytests${NC}"
echo -e "\n${YELLOW}=== Installation Instructions ===${NC}"
echo -e "To install to /Applications:"
echo -e "  1. Remove any existing version: ${YELLOW}rm -rf /Applications/Deskflow.app${NC}"
echo -e "  2. Copy the new version: ${YELLOW}cp -R $BUILD_DIR/bin/Deskflow.app /Applications/${NC}"
echo -e "\n${RED}Important:${NC} Always remove the old app before copying the new one to avoid"
echo -e "architecture mismatches or stale library references."
echo -e "This build is for ${GREEN}$ARCH${NC} architecture."
echo -e "\n${YELLOW}Note:${NC} After installation, you may need to:"
echo -e "  1. Go to System Settings → Privacy & Security → Accessibility"
echo -e "  2. Remove old Deskflow entries and re-add the new app"
echo -e "  3. This is required because the app signature changed"
