#!/bin/bash

# Exit on error
set -e

# Print commands before executing
set -x

# Check for required tools
command -v brew >/dev/null 2>&1 || {
    echo "Homebrew is required but not installed. Please install it first."
    echo "Visit https://brew.sh for installation instructions."
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
Brewfile="$SCRIPT_DIR/Brewfile"

# Install packages using Brewfile if present (preferred), otherwise fall back to brew install list
if [ -f "$Brewfile" ]; then
    echo "Using Brewfile: $Brewfile"
    # Ensure brew/bundle is tapped
    brew tap Homebrew/bundle >/dev/null 2>&1 || true
    brew bundle --file="$Brewfile" --no-upgrade
else
    echo "Brewfile not found; installing common packages via brew install"
    brew install pkg-config pkgconf autoconf automake libtool gettext cmake glib cairo pango atk gdk-pixbuf libepoxy gobject-introspection harfbuzz freetype fontconfig libpng
fi

# Create build directory
BUILD_DIR="$(pwd)/build"
mkdir -p "$BUILD_DIR"

# No Conan usage: dependencies come from Homebrew; pkg-config should find them.

# Run from project root when configuring/building

# Run autogen if needed
if [ ! -f "configure" ]; then
    NOCONFIGURE=1 ./autogen.sh
fi

# Ensure pkg-config looks into Homebrew prefix
export PKG_CONFIG_PATH="$(brew --prefix)/lib/pkgconfig:$(brew --prefix)/share/pkgconfig:$PKG_CONFIG_PATH"

# Configure with macOS specific options
./configure \
    --prefix="$BUILD_DIR" \
    --enable-debug=yes \
    --enable-quartz-backend \
    --enable-x11-backend=no \
    --enable-broadway-backend=yes \
    --with-included-immodules=yes \
    --disable-dependency-tracking \
    PKG_CONFIG_PATH="$BUILD_DIR/lib/pkgconfig"

# Build GTK+
make -j"$(sysctl -n hw.ncpu)"

# Install to build directory
make install

echo "Build completed successfully!"
echo "Build artifacts are in: $BUILD_DIR"
