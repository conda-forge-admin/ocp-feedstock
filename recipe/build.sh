#!/bin/sh
set -euo pipefail

# get vtk library for osx-arm64
VTK_DIR=${PREFIX}
if [[ "$OSTYPE" == "darwin"* && $OSX_ARCH == "arm64" ]]; then
    VTK_DIR=/tmp/vtk
    conda list -p ${BUILD_PREFIX} > packages.txt
    cat packages.txt
    VTK_PACKAGE_VERSION=`grep vtk packages.txt | awk -F ' ' '{print $2}'`
    export CONDA_SUBDIR=osx-arm64
		conda create -y -p ${VTK_DIR} --no-deps vtk=${VTK_PACKAGE_VERSION}
		VTK_DIR="${VTK_DIR}/lib/cmake/vtk-${VTK_PACKAGE_VERSION}"
fi

# FindOpenCascade.cmake bundled with OCP references the env var `CONDA_PREFIX`.
# That is the right prefix when manually running CMake inside a conda env, but
# the wrong one when using conda-build. Substitute the right prefix inline.
CONDA_PREFIX="${PREFIX}" cmake ${CMAKE_ARGS} -B build -S "${SRC_DIR}/src" \
	-G Ninja \
	-DVTK_DIR="${VTK_DIR}" \
	-DPython3_FIND_STRATEGY=LOCATION \
	-DPython3_ROOT_DIR=${PREFIX} \
	-DPython3_EXECUTABLE=${PREFIX}/bin/python \
	-DCMAKE_BUILD_TYPE=Release

cmake --build build -j ${CPU_COUNT}
cmake --install build --prefix "${STDLIB_DIR}"
