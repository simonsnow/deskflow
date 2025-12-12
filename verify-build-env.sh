#!/bin/bash
# Verification script to check macOS build environment
# SPDX-FileCopyrightText: (C) 2025 Deskflow Developers
# SPDX-License-Identifier: MIT
# This script checks if your system is properly configured to build Deskflow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Deskflow Build Environment Check ===${NC}\n"

# Detect architecture
ARCH=$(uname -m)
echo -e "${GREEN}✓ Architecture detected: ${BLUE}$ARCH${NC}"

if [ "$ARCH" = "arm64" ]; then
    echo -e "  Running on Apple Silicon (M1/M2/M3/M4)"
elif [ "$ARCH" = "x86_64" ]; then
    echo -e "  Running on Intel Mac"
else
    echo -e "${RED}✗ Unsupported architecture: $ARCH${NC}"
    exit 1
fi

# Check for Xcode Command Line Tools
echo -e "\n${YELLOW}Checking for Xcode Command Line Tools...${NC}"
if xcode-select -p &> /dev/null; then
    XCODE_PATH=$(xcode-select -p)
    echo -e "${GREEN}✓ Xcode Command Line Tools found: ${BLUE}$XCODE_PATH${NC}"
else
    echo -e "${RED}✗ Xcode Command Line Tools not found${NC}"
    echo -e "  Install with: ${YELLOW}xcode-select --install${NC}"
    exit 1
fi

# Check for Homebrew
echo -e "\n${YELLOW}Checking for Homebrew...${NC}"
if command -v brew &> /dev/null; then
    BREW_PREFIX=$(brew --prefix)
    BREW_VERSION=$(brew --version | head -n1)
    echo -e "${GREEN}✓ Homebrew found: ${BLUE}$BREW_PREFIX${NC}"
    echo -e "  Version: $BREW_VERSION"
    
    # Verify Homebrew is in the expected location
    if [ "$ARCH" = "arm64" ] && [ "$BREW_PREFIX" != "/opt/homebrew" ]; then
        echo -e "${YELLOW}⚠ Warning: Homebrew is at $BREW_PREFIX, expected /opt/homebrew for Apple Silicon${NC}"
    elif [ "$ARCH" = "x86_64" ] && [ "$BREW_PREFIX" != "/usr/local" ]; then
        echo -e "${YELLOW}⚠ Warning: Homebrew is at $BREW_PREFIX, expected /usr/local for Intel${NC}"
    fi
else
    echo -e "${RED}✗ Homebrew not found${NC}"
    echo -e "  Install from: ${BLUE}https://brew.sh${NC}"
    exit 1
fi

# Check for CMake
echo -e "\n${YELLOW}Checking for CMake...${NC}"
if command -v cmake &> /dev/null; then
    CMAKE_VERSION=$(cmake --version | head -n1 | cut -d' ' -f3)
    echo -e "${GREEN}✓ CMake found: ${BLUE}$CMAKE_VERSION${NC}"
    
    # Check version is 3.24 or higher
    CMAKE_MAJOR=$(echo $CMAKE_VERSION | cut -d'.' -f1)
    CMAKE_MINOR=$(echo $CMAKE_VERSION | cut -d'.' -f2)
    if [ "$CMAKE_MAJOR" -lt 3 ] || ([ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -lt 24 ]); then
        echo -e "${YELLOW}⚠ Warning: CMake 3.24+ required, found $CMAKE_VERSION${NC}"
        echo -e "  Update with: ${YELLOW}brew upgrade cmake${NC}"
    fi
else
    echo -e "${RED}✗ CMake not found${NC}"
    echo -e "  Install with: ${YELLOW}brew install cmake${NC}"
    exit 1
fi

# Check for Qt
echo -e "\n${YELLOW}Checking for Qt...${NC}"
if brew list qt &> /dev/null; then
    QT_PREFIX=$(brew --prefix qt)
    QT_VERSION=$(brew list --versions qt | cut -d' ' -f2)
    echo -e "${GREEN}✓ Qt found: ${BLUE}$QT_PREFIX${NC}"
    echo -e "  Version: $QT_VERSION"
    
    # Check for CMake files
    if [ -d "$QT_PREFIX/lib/cmake" ]; then
        echo -e "  ${GREEN}✓ Qt CMake files found${NC}"
    else
        echo -e "  ${YELLOW}⚠ Warning: Qt CMake files not found at expected location${NC}"
    fi
else
    echo -e "${RED}✗ Qt not found${NC}"
    echo -e "  Install with: ${YELLOW}brew install qt${NC}"
    exit 1
fi

# Check for OpenSSL 3
echo -e "\n${YELLOW}Checking for OpenSSL 3...${NC}"
if brew list openssl@3 &> /dev/null; then
    OPENSSL_PREFIX=$(brew --prefix openssl@3)
    OPENSSL_VERSION=$(brew list --versions openssl@3 | cut -d' ' -f2)
    echo -e "${GREEN}✓ OpenSSL 3 found: ${BLUE}$OPENSSL_PREFIX${NC}"
    echo -e "  Version: $OPENSSL_VERSION"
else
    echo -e "${RED}✗ OpenSSL 3 not found${NC}"
    echo -e "  Install with: ${YELLOW}brew install openssl@3${NC}"
    exit 1
fi

# Check macOS SDK
echo -e "\n${YELLOW}Checking for macOS SDK...${NC}"
if SDKROOT=$(xcrun --show-sdk-path 2>/dev/null); then
    SDK_VERSION=$(xcrun --show-sdk-version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓ macOS SDK found: ${BLUE}$SDKROOT${NC}"
    echo -e "  Version: $SDK_VERSION"
else
    echo -e "${RED}✗ macOS SDK not found${NC}"
    echo -e "  Install Xcode Command Line Tools: ${YELLOW}xcode-select --install${NC}"
    exit 1
fi

# Summary
echo -e "\n${GREEN}=== Environment Check Complete ===${NC}"
echo -e "\n${BLUE}Your system is ready to build Deskflow for ${ARCH}!${NC}"
echo -e "\nTo build, run: ${YELLOW}./build-macos.sh${NC}"
echo -e "For debug build: ${YELLOW}./build-macos.sh Debug${NC}"

# Show what will be built
echo -e "\n${BLUE}Build Configuration:${NC}"
echo -e "  Architecture: ${GREEN}$ARCH${NC}"
echo -e "  CMake: ${GREEN}$CMAKE_VERSION${NC}"
echo -e "  Qt: ${GREEN}$QT_VERSION${NC}"
echo -e "  OpenSSL: ${GREEN}$OPENSSL_VERSION${NC}"
echo -e "  SDK: ${GREEN}$SDK_VERSION${NC}"
