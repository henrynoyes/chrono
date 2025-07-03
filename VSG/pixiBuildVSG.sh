#!/bin/bash

# -------------------------------------------------------------------------------------------------------
# Shell script for building VSG based on the last official releases for pixi environment.
# - Requires cmake, wget, and unzip (provided by pixi)
# - Place in your Project Chrono directory with pixi.toml
# - Run within pixi shell environment: pixi shell
# - Specify the locations for the VSG sources OR indicate that these should be downloaded.
# - Specify the install directory (defaults to pixi environment prefix).
# - Decide whether to build shared or static libraries and whether to also build debug libraries.
# - Run the script (sh ./buildVSG_pixi.sh).
# - The install directory will contain (under subdirectories of VSG_INSTALL_DIR/lib/shared) all VSG CMake
#   project configuration scripts required to configure Chrono with the Chrono::VSG module enabled.
#
# Notes:
# - The script accepts 1 optional argument to override the install directory.
# - This script uses the following versions of the various codes from their respective repositories:
#      VulkanSceneGraph (github.com/vsg-dev/VulkanSceneGraph.git): Tag v1.1.4
#      vsgXchange (github.com/vsg-dev/vsgXchange.git):             Tag v1.1.2
#      vsgImGui (github.com/vsg-dev/vsgImGui.git):                 Tag v0.5.0
#      vsgExamples (github.com/vsg-dev/vsgExamples.git):           Tag v1.1.4
#      assimp (github.com/assimp/assimp):                          Tag v5.3.1
# - We suggest using Ninja (ninja-build.org/) and the "Ninja Multi-Config" CMake generator.
#   (otherwise, you will need to explicitly set the CMAKE_BUILD_TYPE variable)
# -------------------------------------------------------------------------------------------------------

# Check if we're in a pixi environment
if [ -z "$PIXI_PROJECT_ROOT" ]; then
    echo "Error: This script must be run within a pixi shell environment."
    echo "Please run: pixi shell"
    echo "Then run this script again."
    exit 1
fi

# Use pixi environment prefix as default install directory
VSG_INSTALL_DIR="$CONDA_PREFIX"

BUILDSHARED=ON
BUILDDEBUG=OFF
BUILDSYSTEM="Ninja Multi-Config"

# ------------------------------------------------------------------------
# Allow overriding installation directory through command line argument


echo "Building VSG in pixi environment"
echo "Pixi project root: $PIXI_PROJECT_ROOT"
echo "Install directory: $VSG_INSTALL_DIR"

# ------------------------------------------------------------------------

echo "Download sources from GitHub"

rm -rf download_vsg
mkdir download_vsg

echo "  ... VulkanSceneGraph"
git clone -c advice.detachedHead=false --depth 1 --branch v1.1.4 "https://github.com/vsg-dev/VulkanSceneGraph" "download_vsg/vsg"
VSG_SOURCE_DIR="download_vsg/vsg"

echo "  ... vsgXchange"    
git clone -c advice.detachedHead=false --depth 1 --branch v1.1.2 "https://github.com/vsg-dev/vsgXchange" "download_vsg/vsgXchange"
VSGXCHANGE_SOURCE_DIR="download_vsg/vsgXchange"

echo "  ... vsgImGui"
git clone -c advice.detachedHead=false --depth 1 --branch v0.5.0 "https://github.com/vsg-dev/vsgImGui" "download_vsg/vsgImGui"
VSGIMGUI_SOURCE_DIR="download_vsg/vsgImGui"

echo "  ... vsgExamples"
git clone -c advice.detachedHead=false --depth 1 --branch v1.1.4 "https://github.com/vsg-dev/vsgExamples" "download_vsg/vsgExamples"
VSGEXAMPLES_SOURCE_DIR="download_vsg/vsgExamples"

echo "  ... assimp"
git clone -c advice.detachedHead=false --depth 1 --branch v5.3.1 "https://github.com/assimp/assimp" "download_vsg/assimp"
ASSIMP_SOURCE_DIR="download_vsg/assimp"


echo -e "\nSources in:"
echo "  "  ${VSG_SOURCE_DIR}
echo "  "  ${VSGXCHANGE_SOURCE_DIR}
echo "  "  ${VSGIMGUI_SOURCE_DIR}
echo "  "  ${VSGEXAMPLES_SOURCE_DIR}
echo "  "  ${ASSIMP_SOURCE_DIR}

# --- assimp -------------------------------------------------------------

echo -e "\n------------------------ Configure assimp\n"
rm -rf build_assimp
cmake -G "${BUILDSYSTEM}" -B build_assimp -S ${ASSIMP_SOURCE_DIR} \
      -DBUILD_SHARED_LIBS:BOOL=OFF \
      -DCMAKE_DEBUG_POSTFIX=_d \
      -DCMAKE_RELWITHDEBINFO_POSTFIX=_rd \
      -DASSIMP_BUILD_TESTS:BOOL=OFF  \
      -DASSIMP_BUILD_ASSIMP_TOOLS:BOOL=OFF \
      -DASSIMP_BUILD_ZLIB:BOOL=ON \
      -DASSIMP_BUILD_DRACO:BOOL=ON \
      -DCMAKE_INSTALL_PREFIX=${VSG_INSTALL_DIR}

echo -e "\n------------------------ Build and install assimp\n"
cmake --build build_assimp --config Release
cmake --install build_assimp --config Release
if [ ${BUILDDEBUG} = ON ]
then
    cmake --build build_assimp --config Debug
    cmake --install build_assimp --config Debug
else
    echo "No Debug build of assimp"
fi

# --- vsg ----------------------------------------------------------------

echo -e "\n------------------------ Configure vsg\n"
rm -rf build_vsg
cmake  -G "${BUILDSYSTEM}" -B build_vsg -S ${VSG_SOURCE_DIR}  \
      -DBUILD_SHARED_LIBS:BOOL=${BUILDSHARED} \
      -DCMAKE_DEBUG_POSTFIX=_d \
      -DCMAKE_RELWITHDEBINFO_POSTFIX=_rd \
      -DCMAKE_INSTALL_PREFIX=${VSG_INSTALL_DIR}

echo -e "\n------------------------ Build and install vsg\n"
cmake --build build_vsg --config Release
cmake --install build_vsg --config Release
if [ ${BUILDDEBUG} = ON ]
then
    cmake --build build_vsg --config Debug
    cmake --install build_vsg --config Debug
else
    echo "No Debug build of vsg"
fi

# --- vsgXchange ---------------------------------------------------------

echo -e "\n------------------------ Configure vsgXchange\n"
rm -rf build_vsgXchange
cmake  -G "${BUILDSYSTEM}" -B build_vsgXchange -S ${VSGXCHANGE_SOURCE_DIR}  \
      -DBUILD_SHARED_LIBS:BOOL=${BUILDSHARED} \
      -DCMAKE_DEBUG_POSTFIX=_d \
      -DCMAKE_RELWITHDEBINFO_POSTFIX=_rd \
      -Dvsg_DIR:PATH=${VSG_INSTALL_DIR}/lib/cmake/vsg \
      -Dassimp_DIR:PATH=${VSG_INSTALL_DIR}/lib/cmake/assimp-5.2 \
      -DCMAKE_INSTALL_PREFIX=${VSG_INSTALL_DIR}

echo -e "\n------------------------ Build and install vsgXchange\n"
cmake --build build_vsgXchange --config Release
cmake --install build_vsgXchange --config Release
if [ ${BUILDDEBUG} = ON ]
then
    cmake --build build_vsgXchange --config Debug
    cmake --install build_vsgXchange --config Debug
else
    echo "No Debug build of vsgXchange"
fi

# --- vsgImGui -----------------------------------------------------------

echo -e "\n------------------------ Configure vsgImGui\n"
rm -rf  build_vsgImGui
cmake -G "${BUILDSYSTEM}" -B build_vsgImGui -S ${VSGIMGUI_SOURCE_DIR} \
      -DBUILD_SHARED_LIBS:BOOL=${BUILDSHARED} \
      -DCMAKE_DEBUG_POSTFIX=_d \
      -DCMAKE_RELWITHDEBINFO_POSTFIX=_rd \
      -Dvsg_DIR:PATH=${VSG_INSTALL_DIR}/lib/cmake/vsg \
      -DCMAKE_INSTALL_PREFIX=${VSG_INSTALL_DIR}

echo -e "\n------------------------ Build and install vsgImGui\n"
cmake --build build_vsgImGui --config Release
cmake --install build_vsgImGui --config Release
if [ ${BUILDDEBUG} = ON ]
then
    cmake --build build_vsgImGui --config Debug
    cmake --install build_vsgImGui --config Debug
else
    echo "No Debug build of vsgImGui"
fi

# --- vsgExamples --------------------------------------------------------

echo -e "\n------------------------ Configure vsgExamples\n"
rm -rf  build_vsgExamples
cmake -G "${BUILDSYSTEM}" -B build_vsgExamples -S ${VSGEXAMPLES_SOURCE_DIR} \
      -Dvsg_DIR:PATH=${VSG_INSTALL_DIR}/lib/cmake/vsg \
      -DvsgXchange_DIR:PATH=${VSG_INSTALL_DIR}/lib/cmake/vsgXchange \
      -DvsgImGui_DIR:PATH=${VSG_INSTALL_DIR}/lib/cmake/vsgImGui \
      -DCMAKE_INSTALL_PREFIX=${VSG_INSTALL_DIR}

echo -e "\n------------------------ Build and install vsgExamples\n"
cmake --build build_vsgExamples --config Release
cmake --install build_vsgExamples --config Release

# --- Cleanup ------------------------------------------------------------

echo -e "\n------------------------ Cleaning up temporary directories\n"
echo "Removing source directories..."
rm -rf download_vsg
echo "Removing build directories..."
rm -rf build_assimp build_vsg build_vsgXchange build_vsgImGui build_vsgExamples
echo "Cleanup complete."

# --- VSG_FILE_PATH ------------------------------------------------------

echo -e "\n------------------------ VSG Installation Complete\n"
echo "VSG libraries installed to: ${VSG_INSTALL_DIR}"
echo "VSG examples data path: ${VSG_INSTALL_DIR}/share/vsgExamples"
echo ""
echo "To use VSG with Project Chrono:"
echo "1. When configuring Chrono with cmake, ensure VSG is found:"
echo "   -Dvsg_DIR:PATH=${VSG_INSTALL_DIR}/lib/cmake/vsg"
echo "   -DvsgXchange_DIR:PATH=${VSG_INSTALL_DIR}/lib/cmake/vsgXchange"
echo "   -DvsgImGui_DIR:PATH=${VSG_INSTALL_DIR}/lib/cmake/vsgImGui"
echo ""
echo "2. The VSG_FILE_PATH environment variable will be automatically set"
echo "   within the pixi environment to: ${VSG_INSTALL_DIR}/share/vsgExamples"
echo ""
echo "3. Build Chrono with the VSG module enabled: -DENABLE_MODULE_VSG=ON"

# Set VSG_FILE_PATH for the current pixi environment
export VSG_FILE_PATH="${VSG_INSTALL_DIR}/share/vsgExamples"
echo "VSG_FILE_PATH set to: $VSG_FILE_PATH"