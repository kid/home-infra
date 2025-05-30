#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if TALOS_VERSION is set
if [ -z "$TALOS_VERSION" ]; then
  echo "Error: TALOS_VERSION environment variable is not set."
  exit 1
fi

# Check if IMAGE_URL is set
if [ -z "$IMAGE_URL" ]; then
  echo "Error: IMAGE_URL environment variable is not set."
  exit 1
fi

# Use BUILD_DIR from the environment or default to "build"
BUILD_DIR="${BUILD_DIR:-build}"

# Create the build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Define variables
FILENAME="nocloud-amd64.raw.xz"
QCOW2_FILE="rootfs.img"
METADATA_FILE="metadata.yaml"
BUILD_EPOCH="$(date +%s)"
VERSION_NO_PREFIX="${TALOS_VERSION#v}"  # Strip 'v' prefix if it exists
ARCHIVE_NAME="talos-${TALOS_VERSION}.tar.gz"

# Download the Talos image from Talos Factory
if [ -f "$BUILD_DIR/$FILENAME" ]; then
  echo "$FILENAME already exists in $BUILD_DIR. Skipping download."
else
  echo "Downloading Talos image from $IMAGE_URL..."
  curl -L -o "$BUILD_DIR/$FILENAME" "$IMAGE_URL" || { echo "Error: Failed to download $IMAGE_URL"; exit 1; }
  echo "Download complete."
fi

# Decompress the downloaded image
echo "Decompressing $FILENAME..."
unxz -f "$BUILD_DIR/$FILENAME"
RAW_FILE="${FILENAME%.xz}"  # Remove .xz extension
echo "Decompression complete."

# Convert the decompressed file to qcow2 format and name it rootfs.img
if [ -f "$BUILD_DIR/$RAW_FILE" ]; then
  echo "Converting $RAW_FILE to $QCOW2_FILE..."
  qemu-img convert -f raw -O qcow2 "$BUILD_DIR/$RAW_FILE" "$BUILD_DIR/$QCOW2_FILE"
  echo "Conversion to $QCOW2_FILE complete."
else
  echo "Error: Decompressed file $RAW_FILE not found in $BUILD_DIR."
  exit 1
fi

# Create metadata file
echo "Creating $METADATA_FILE..."
tee "$BUILD_DIR/$METADATA_FILE" > /dev/null <<EOF
architecture: x86_64
creation_date: ${BUILD_EPOCH}
properties:
  description: Talos Linux ${VERSION_NO_PREFIX}
  os: Talos Linux
  release: ${VERSION_NO_PREFIX}
EOF
echo "$METADATA_FILE created in $BUILD_DIR."

# Create an archive containing the qcow2 file and metadata.yaml
echo "Creating archive $ARCHIVE_NAME..."
tar -czf "$BUILD_DIR/$ARCHIVE_NAME" -C "$BUILD_DIR" "$QCOW2_FILE" "$METADATA_FILE"
echo "Archive $ARCHIVE_NAME created successfully in $BUILD_DIR."

# Cleanup intermediate files
echo "Cleaning up intermediate files..."
rm -f "$BUILD_DIR/$RAW_FILE" "$BUILD_DIR/$QCOW2_FILE" "$BUILD_DIR/$METADATA_FILE"
echo "Cleanup complete. Final artifact: $BUILD_DIR/$ARCHIVE_NAME"
