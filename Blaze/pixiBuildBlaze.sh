#!/bin/bash
# -------------------------------------------------------------------------------------------------------
# Shell script for building and installing Blaze within a pixi environment.
# - Requires git, cmake, and ninja (available through pixi).
# - Place in an arbitrary temporary directory.
# - Run within your pixi environment (pixi shell).
# - Installs Blaze directly into the pixi environment prefix for seamless integration.
#
# Notes:
# - The script accepts 1 optional argument to override the install directory.
# - If ninja is not available, set BUILD_SYSTEM="Unix Makefiles" or some other generator
# - This script is designed to work within a pixi environment
# -------------------------------------------------------------------------------------------------------

# Check if we're in a pixi environment
if [ -z "$CONDA_PREFIX" ]; then
    echo "Error: CONDA_PREFIX not set. Make sure you're running this within a pixi environment."
    echo "Run 'pixi shell' first to activate your environment."
    exit 1
fi

# Set default installation directory to pixi environment prefix
BLAZE_INSTALL_DIR="${CONDA_PREFIX}"
BUILD_SYSTEM="Ninja"

echo "======================================================================"
echo "Building Blaze for pixi environment"
echo "======================================================================"
echo "Pixi environment: ${CONDA_PREFIX}"
echo "Installation directory: ${BLAZE_INSTALL_DIR}"
echo "Build system: ${BUILD_SYSTEM}"
echo "======================================================================"

echo "----------------------------- Download sources from Bitbucket"
rm -rf download_blaze
mkdir download_blaze
git clone -c advice.detachedHead=false --depth 1 --branch v3.8.2 "https://bitbucket.org/blaze-lib/blaze.git" "download_blaze"

echo -e "\n------------------------ Configure Blaze\n"
rm -rf build_blaze
cmake -G "${BUILD_SYSTEM}" -B build_blaze -S download_blaze \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${BLAZE_INSTALL_DIR}" \
    -DCMAKE_PREFIX_PATH="${CONDA_PREFIX}" \
    # -DCMAKE_C_COMPILER="${CONDA_PREFIX}/bin/gcc" \
    # -DCMAKE_CXX_COMPILER="${CONDA_PREFIX}/bin/g++"

echo -e "\n------------------------ Build and install Blaze\n"
# Note: Blaze is header-only, but we still run build in case of any configuration targets
cmake --build build_blaze --config Release
cmake --install build_blaze --config Release --prefix "${BLAZE_INSTALL_DIR}"

echo -e "\n------------------------ Cleanup\n"
rm -rf download_blaze
rm -rf build_blaze

echo "======================================================================"
echo "Blaze installation completed successfully!"
echo "======================================================================"
echo "Blaze headers installed in: ${BLAZE_INSTALL_DIR}/include"
echo ""
echo "To use Blaze in your Chrono build, the headers should now be"
echo "automatically found since they're in your pixi environment prefix."
echo ""
echo "If you need to explicitly set the path, use:"
echo "  -Dblaze_INCLUDE_DIR=${BLAZE_INSTALL_DIR}/include"
echo "======================================================================"