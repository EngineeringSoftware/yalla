#!/bin/bash

git clone https://github.com/kokkos/pykokkos-base.git
pushd pykokkos-base
git checkout b8694f5 # This sets the Kokkos version to 3.7.02
conda create -n pyk_cgo --file requirements.txt python=3.11 pybind11 patchelf
source activate pyk_cgo
python setup.py install -- -DENABLE_LAYOUTS=ON -DENABLE_MEMORY_TRAITS=OFF -DENABLE_VIEW_RANKS=3 \
 -DENABLE_CUDA=OFF -DKokkos_ENABLE_CUDA=OFF -DENABLE_THREADS=OFF -DKokkos_ENABLE_THREADS=OFF \
 -DENABLE_SERIAL=ON -DKokkos_ENABLE_SERIAL=ON -DENABLE_OPENMP=OFF -DKokkos_ENABLE_OPENMP=OFF
popd
git clone https://github.com/kokkos/pykokkos.git
pushd pykokkos
git checkout 3d4afd2
pip install --user -e .
popd

anaconda_location=$(dirname $(dirname "$(which conda)"))
kokkos_include_path="${anaconda_location}/envs/pyk_cgo/lib/python3.11/site-packages/pykokkos_base-0.0.7-py3.11-linux-x86_64.egg/include/kokkos"
echo "${kokkos_include_path}"

pushd 02
# TODO: change the hardcoded path to variable
/home/nalawar/projects/yalla/llvm-build/bin/clang-yalla --header_dir "${kokkos_include_path}" kernel.cpp \
 --input_headers functor.hpp --  -isystem "${kokkos_include_path}" -DEXEC_SPACE=Kokkos::Serial -Dpk_exec_space=Kokkos::Serial

sed -i '/#include <Kokkos_Core.hpp>/d' kernel.yalla.cpp
sed -i 's/#include "functor.hpp"/#include "functor.yalla.hpp"/g' kernel.yalla.cpp

COMPILER=g++
CXX_STANDARD=17
EXEC_SPACE=Serial
KOKKOS_INCLUDE_PATH=${kokkos_include_path}
KOKKOS_LIB_PATH="${anaconda_location}/envs/pyk_cgo/lib/python3.11/site-packages/pykokkos_base-0.0.7-py3.11-linux-x86_64.egg/lib"
PK_ARG_MEMSPACE=Kokkos::HostSpace
PK_ARG_LAYOUT=Kokkos::LayoutRight
MODE=yalla
MODULE=kernel.cpython-311-x86_64-linux-gnu.so

mkdir build

    echo "Compiling kernel..."
    # Compile the kernel
    "${COMPILER}" \
    -I. \
    -O3 \
    -march=native -mtune=native \
    -fPIC \
    -std=c++${CXX_STANDARD} \
    -DSPACE="${EXEC_SPACE}" \
    -o build/kernel.yalla.o \
    -c kernel.yalla.cpp \
    -Dpk_exec_space="Kokkos::${EXEC_SPACE}"

    echo "Compiling bindings..."
    # Compile the bindings
    "${COMPILER}" \
    `python3 -m pybind11 --includes` \
    -I. \
    -O3 \
    -march=native -mtune=native \
    -isystem "${KOKKOS_INCLUDE_PATH}" \
    -fPIC \
    -std=c++${CXX_STANDARD} \
    -DSPACE="${EXEC_SPACE}" \
    -o build/bindings.${EXEC_SPACE}.${MODE}.o \
    -c bindings.${EXEC_SPACE}.${MODE}.cpp \
    -Dpk_arg_memspace="${PK_ARG_MEMSPACE}" \
    -Dpk_arg_layout="${PK_ARG_LAYOUT}" \
    -Dpk_exec_space="Kokkos::${EXEC_SPACE}"

    echo "Compiling wrappers..."
    # Compile the wrappers
    "${COMPILER}" \
    -I. \
    -O3 \
    -march=native -mtune=native \
    -isystem "${KOKKOS_INCLUDE_PATH}" \
    -fPIC \
    -std=c++${CXX_STANDARD} \
    -DSPACE="${EXEC_SPACE}" \
    -o build/wrappers.yalla.o \
    -c wrappers.yalla.cpp

    echo "Linking..."
    "${COMPILER}" \
    -shared \
    build/kernel.yalla.o build/wrappers.yalla.o build/bindings.${EXEC_SPACE}.${MODE}.o -o build/${MODULE} \
    "${KOKKOS_LIB_PATH}/libkokkoscontainers.so" \
    "${KOKKOS_LIB_PATH}/libkokkoscore.so"
