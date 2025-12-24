#!/bin/bash

# ===========================
# Convert .pkg to .iso
# Waits for user to provide the .pkg path
# Shows progress during copying
# ===========================

# Ask the user to drag and drop the .pkg file into Terminal
echo "Drag and drop the .pkg file here and press Enter:"
read -e PKG

# Check if the file exists
if [ ! -f "$PKG" ]; then
    echo "Error: File not found"
    exit 1
fi

# Get the base name of the package without path and extension
BASENAME=$(basename "$PKG" .pkg)

# Create a temporary working directory on the Desktop
WORKDIR="$HOME/Desktop/${BASENAME}_to_iso"
mkdir -p "$WORKDIR"

# Expand the .pkg into the working directory
echo "Expanding $BASENAME.pkg..."
pkgutil --expand "$PKG" "$WORKDIR/expanded_pkg"

# Determine the package size in MB and add extra 1GB buffer
PKG_SIZE_MB=$(du -sm "$PKG" | cut -f1)
DMG_SIZE_MB=$((PKG_SIZE_MB + 1024)) # +1 GB buffer

# Set DMG and ISO paths
DMG="$WORKDIR/pkg_image.dmg"
ISO="$HOME/Desktop/${BASENAME}.iso"

# Create an empty DMG of the calculated size
echo "Creating DMG of size $DMG_SIZE_MB MB..."
hdiutil create -size "${DMG_SIZE_MB}m" -fs HFS+ -volname "PKG_ISO" "$DMG"

# Mount the DMG
echo "Mounting DMG..."
hdiutil attach "$DMG" -mountpoint /Volumes/PKG_ISO

# Copy the expanded pkg contents to DMG with progress
echo "Copying expanded package to DMG..."
rsync -avh --progress "$WORKDIR/expanded_pkg/" /Volumes/PKG_ISO/

# Detach the DMG
echo "Detaching DMG..."
hdiutil detach /Volumes/PKG_ISO

# Convert DMG to ISO
echo "Converting DMG to ISO..."
hdiutil makehybrid -iso -joliet -o "$ISO" "$DMG"

# Done
echo "Done! ISO created on Desktop: $ISO"
