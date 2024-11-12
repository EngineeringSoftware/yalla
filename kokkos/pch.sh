#!/bin/bash

CONDA_PATH=$(dirname $(dirname "$(which conda)"))
KOKKOS_INCLUDE_PATH="${CONDA_PATH}/envs/pyk_cgo/lib/python3.11/site-packages/pykokkos_base-0.0.7-py3.11-linux-x86_64.egg/include/kokkos"
PCH_PATH="${KOKKOS_INCLUDE_PATH}/Kokkos_Core.hpp.gch"

COMPILER=g++
CXX_STANDARD=17
EXEC_SPACE=Serial
flags="-O3 -Wall -Wextra -march=native -mtune=native -g -O3 -fPIC -DSPACE=${EXEC_SPACE} -std=c++${CXX_STANDARD}"

COMPILE_COMMAND="${COMPILER} -I. ${flags} -isystem ${KOKKOS_INCLUDE_PATH} -o build/kernel.normal.o -c kernel.cpp -Dpk_exec_space=Kokkos::${EXEC_SPACE}"
PCH_COMMAND="${COMPILER} -x c++-header Kokkos_Core.hpp -I. ${flags}"

if [ -f "${PCH_PATH}" ]; then
    rm "${PCH_PATH}"
fi

pushd 02
echo "Compiling kernel without PCH..."
time ${COMPILE_COMMAND}
popd

pushd "${KOKKOS_INCLUDE_PATH}"
echo "Compiling PCH header..."
${PCH_COMMAND}
popd

pushd 02
echo "Compiling kernel without PCH..."
time ${COMPILE_COMMAND}
popd
