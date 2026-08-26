#!/usr/bin/env bash
# ==============================================================================
# Script: build_flatpak.sh
# Description: Generates Flatpak Python dependencies and builds the Flatpak bundle.
#
# DEPENDENCIES REQUIREMENT:
# Before running this script locally, ensure you have flatpak, flatpak-builder,
# and python3-pip installed.
#
# Ubuntu / Debian / Pop!_OS / Mint:
#   sudo apt update
#   sudo apt install -y flatpak flatpak-builder python3-pip python3-venv pipx
#
# Arch Linux / Manjaro / EndeavourOS:
#   sudo pacman -Syu --needed flatpak flatpak-builder python-pip python-pipx
#
# Fedora:
#   sudo dnf install -y flatpak flatpak-builder python3-pip python3-pipx
#
# Setup Flathub repository (if not already added):
#   flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
# ==============================================================================

set -euo pipefail

# Configurations
MANIFEST="${MANIFEST:-com.github.Ubaida_M_Yusuf.Makimus_AI.yaml}"
APP_ID="${APP_ID:-com.github.Ubaida_M_Yusuf.Makimus_AI}"
BUILD_DIR="${BUILD_DIR:-build-dir}"
REPO_DIR="${REPO_DIR:-repo}"
BRANCH="${BRANCH:-main}"
REQUIREMENTS_FILE="${REQUIREMENTS_FILE:-requirements-flatpak.txt}"

# Read version (fallback to version.txt or default 1.0.0)
if [ -f "version.txt" ]; then
    VERSION=$(tr -d '\r\n ' < version.txt)
else
    VERSION="${VERSION:-1.0.0}"
fi

OUTPUT_BUNDLE="Makimus_AI-v${VERSION}.flatpak"

echo "=========================================="
echo " Building Flatpak Bundle for $APP_ID"
echo " Version: $VERSION"
echo " Output:  $OUTPUT_BUNDLE"
echo "=========================================="

# ------------------------------------------------------------------------------
# Steg 0: Generer Python-avhengigheter hvis requirements-filen finnes
# ------------------------------------------------------------------------------
if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "--> [0/4] Generating Python dependencies manifest..."

    # Sjekk om flatpak-pip-generator er installert
    if ! command -v flatpak-pip-generator &> /dev/null; then
        echo "    'flatpak-pip-generator' ble ikke funnet. Installerer via pip/pipx..."
        pip install --user flatpak-pip-generator 2>/dev/null || pipx install flatpak-pip-generator || sudo pip3 install flatpak-pip-generator
    fi

    flatpak-pip-generator \
        --requirements-file="$REQUIREMENTS_FILE" \
        --output=python-dependencies \
        --runtime=org.freedesktop.Sdk//24.08 \
        --prefer-wheels=torch,torchvision,triton,cuda-bindings,Pillow,pybind11,opencv-python,numpy,rawpy,safetensors,regex,hf-xet,PyYAML,nvidia-cublas,nvidia-cuda-cupti,nvidia-cuda-nvrtc,nvidia-cuda-runtime,nvidia-cudnn-cu13,nvidia-cufft,nvidia-cufile,nvidia-curand,nvidia-cusolver,nvidia-cusparse,nvidia-cusparselt-cu13,nvidia-nccl-cu13,nvidia-nvjitlink,nvidia-nvshmem-cu13,nvidia-nvtx
else
    echo "--> [0/4] Ingen '$REQUIREMENTS_FILE' funnet, hopper over generering av python-dependencies."
fi

# ------------------------------------------------------------------------------
# Steg 1-3: Bygg Flatpak
# ------------------------------------------------------------------------------
echo "--> [1/4] Ensuring Flathub remote is available..."
flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo

echo "--> [2/4] Building and installing dependencies from Flathub..."
flatpak-builder --user --install-deps-from=flathub --force-clean "$BUILD_DIR" "$MANIFEST"

echo "--> [3/4] Exporting build to local repository..."
rm -rf "$REPO_DIR"
flatpak-builder --user --repo="$REPO_DIR" --force-clean "$BUILD_DIR" "$MANIFEST"

echo "--> [4/4] Creating standalone bundle file ($OUTPUT_BUNDLE)..."
flatpak build-bundle "$REPO_DIR" "$OUTPUT_BUNDLE" "$APP_ID" master

echo "=========================================="
echo " SUCCESS! Bundle created: $OUTPUT_BUNDLE"
echo "=========================================="