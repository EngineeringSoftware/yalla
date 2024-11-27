#!/bin/bash

readonly _DIR="$( cd -P "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" && pwd )"
readonly PROJECTS_DIR="${_DIR}/oss"
CLANG_BIN_PATH=${_DIR}/clang+llvm-15.0.6-x86_64-linux-gnu-ubuntu-18.04/bin
COMPILER=${CLANG_BIN_PATH}/clang++
C_COMPILER=${CLANG_BIN_PATH}/clang
YALLA_PATH=${_DIR}/yalla-install/bin/clang-yalla

source activate pyk_cgo
# kokkos related
KOKKOS_PATH=`python -c "import importlib; print(importlib.import_module('kokkos').__file__)"`
KOKKOS_PATH="${KOKKOS_PATH/"/kokkos/__init__.py"/}" # remove "/kokkos/__init__.py" from the end of the string

KOKKOS_LIB_PATH="${KOKKOS_PATH}/lib"
if [ ! -d "${KOKKOS_LIB_PATH}" ]; then
    KOKKOS_LIB_PATH="${KOKKOS_PATH}/lib64"
fi

KOKKOS_INCLUDE_PATH="${KOKKOS_PATH}/include/kokkos"
OMP_FLAG="-fopenmp"

PK_ARG_MEMSPACE=Kokkos::HostSpace
PK_ARG_LAYOUT=Kokkos::LayoutRight
MODULE=kernel.cpython-311-x86_64-linux-gnu.so
CXX_STANDARD="17"
EXEC_SPACE="OpenMP"

readonly flags="-Wall -Wextra -march=native -mtune=native -g -O3"
KERNELS=("02_yAx" "binning_kksort_BinningKKSort" "force_lj_neigh_fullneigh_reduce" "integrator_nve_initial_integrate" "property_temperature_compute_workunit" "input_init_system" "nstream_nstream" "team_policy_yAx" "force_lj_neigh_fullneigh_for" "integrator_nve_final_integrate" "property_kine_work")

declare -g -A pch_times

normal_comp_time_02=0
yalla_tool_time_02=0
yalla_comp_time_02=0
yalla_wrapper_time_02=0

# compilation command
YALLA_COMMAND="${COMPILER} \
    -I. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    -fPIC \
    -std=c++${CXX_STANDARD} \
    -DSPACE=${EXEC_SPACE} \
    -o kernel.yalla.o \
    -c kernel.yalla.cpp \
    -Dpk_exec_space=Kokkos::${EXEC_SPACE}"

YALLA_BINDINGS_COMMAND="${COMPILER} \
    `python3 -m pybind11 --includes` \
    -I. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    -isystem ${KOKKOS_INCLUDE_PATH} \
    -fPIC \
    ${OMP_FLAG} -std=c++${CXX_STANDARD} \
    -DSPACE="${EXEC_SPACE}" \
    -o bindings.yalla.o \
    -c OpenMP/bindings.yalla.cpp \
    -Dpk_arg_memspace=${PK_ARG_MEMSPACE} \
    -Dpk_arg_layout=${PK_ARG_LAYOUT} \
    -Dpk_exec_space=Kokkos::${EXEC_SPACE}"

YALLA_WRAPPERS_COMMAND="${COMPILER} \
    -I. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    -isystem ${KOKKOS_INCLUDE_PATH} \
    -fPIC \
    ${OMP_FLAG} -std=c++${CXX_STANDARD} \
    -DSPACE=${EXEC_SPACE} \
    -o wrappers.yalla.o \
    -c wrappers.yalla.cpp"

YALLA_LINK_COMMAND="${COMPILER} \
    -I.. \
    -shared \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    ${OMP_FLAG} \
    kernel.yalla.o \
    wrappers.yalla.o \
    bindings.yalla.o \
    -o ${MODULE}.yalla \
    ${KOKKOS_LIB_PATH}/libkokkoscontainers.so \
    ${KOKKOS_LIB_PATH}/libkokkoscore.so"

# compilation command
YALLA_LTO_COMMAND="${COMPILER} \
    -I. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    -fPIC \
    -flto \
    -std=c++${CXX_STANDARD} \
    -DSPACE=${EXEC_SPACE} \
    -o build/${COMPILER}/kernel.lto.o \
    -c kernel.yalla.cpp \
    -Dpk_exec_space=Kokkos::${EXEC_SPACE}"

YALLA_LTO_BINDINGS_COMMAND="${COMPILER} \
    `python3 -m pybind11 --includes` \
    -I. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    -isystem ${KOKKOS_INCLUDE_PATH} \
    -fPIC \
    -flto \
    ${OMP_FLAG} -std=c++${CXX_STANDARD} \
    -DSPACE="${EXEC_SPACE}" \
    -o build/${COMPILER}/bindings.lto.o \
    -c bindings.yalla.cpp \
    -Dpk_arg_memspace=${PK_ARG_MEMSPACE} \
    -Dpk_arg_layout=${PK_ARG_LAYOUT} \
    -Dpk_exec_space=Kokkos::${EXEC_SPACE}"

YALLA_LTO_WRAPPERS_COMMAND="${COMPILER} \
    -I. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    -isystem ${KOKKOS_INCLUDE_PATH} \
    -fPIC \
    -flto \
    ${OMP_FLAG} -std=c++${CXX_STANDARD} \
    -DSPACE=${EXEC_SPACE} \
    -o build/${COMPILER}/wrappers.lto.o \
    -c wrappers.yalla.cpp"

YALLA_LTO_LINK_COMMAND="${COMPILER} \
    -I.. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    -shared \
    ${OMP_FLAG} \
    -flto \
    build/${COMPILER}/kernel.lto.o \
    build/${COMPILER}/wrappers.lto.o \
    build/${COMPILER}/bindings.lto.o \
    -o build/${COMPILER}/${MODULE}.lto \
    ${KOKKOS_LIB_PATH}/libkokkoscontainers.so \
    ${KOKKOS_LIB_PATH}/libkokkoscore.so"

PCH_COMMAND="${COMPILER} \
    -x c++-header ${KOKKOS_INCLUDE_PATH}/Kokkos_Core.hpp \
    -I${KOKKOS_INCLUDE_PATH} \
    -Wall -Wextra \
    -O3 \
    -march=native -mtune=native \
    -g \
    ${OMP_FLAG} \
    -isystem ${KOKKOS_INCLUDE_PATH} \
    -fPIC \
    -std=c++${CXX_STANDARD} \
    -DSPACE=${EXEC_SPACE}"

NORMAL_COMMAND="${COMPILER} \
    -I. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    ${OMP_FLAG} \
    -isystem ${KOKKOS_INCLUDE_PATH} \
    -fPIC \
    -std=c++${CXX_STANDARD} \
    -DSPACE=${EXEC_SPACE} \
    -o kernel.normal.o \
    -c kernel.cpp \
    -Dpk_exec_space=Kokkos::${EXEC_SPACE}"

CLANG_PCH_COMMAND="${COMPILER} \
    -include-pch ${KOKKOS_INCLUDE_PATH}/Kokkos_Core.hpp.gch \
    -I. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    ${OMP_FLAG} \
    -isystem ${KOKKOS_INCLUDE_PATH} \
    -fPIC \
    -std=c++${CXX_STANDARD} \
    -DSPACE=${EXEC_SPACE} \
    -o kernel.normal.o \
    -c kernel.cpp \
    -Dpk_exec_space=Kokkos::${EXEC_SPACE}"

NORMAL_BINDINGS_COMMAND="${COMPILER} \
    `python3 -m pybind11 --includes` \
    -I. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    -isystem ${KOKKOS_INCLUDE_PATH} \
    -fPIC \
    ${OMP_FLAG} -std=c++${CXX_STANDARD} \
    -DSPACE="${EXEC_SPACE}" \
    -o bindings.normal.o \
    -c OpenMP/bindings.normal.cpp \
    -Dpk_arg_memspace=${PK_ARG_MEMSPACE} \
    -Dpk_arg_layout=${PK_ARG_LAYOUT} \
    -Dpk_exec_space=Kokkos::${EXEC_SPACE}"

PCH_BINDINGS_COMMAND="${COMPILER} \
    -include-pch ${KOKKOS_INCLUDE_PATH}/Kokkos_Core.hpp.gch \
    `python3 -m pybind11 --includes` \
    -I. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    -isystem ${KOKKOS_INCLUDE_PATH} \
    -fPIC \
    ${OMP_FLAG} -std=c++${CXX_STANDARD} \
    -DSPACE="${EXEC_SPACE}" \
    -o bindings.normal.o \
    -c OpenMP/bindings.normal.cpp \
    -Dpk_arg_memspace=${PK_ARG_MEMSPACE} \
    -Dpk_arg_layout=${PK_ARG_LAYOUT} \
    -Dpk_exec_space=Kokkos::${EXEC_SPACE}"

NORMAL_LINK_COMMAND="${COMPILER} \
    -I.. \
    -Wall -Wextra \
    -march=native -mtune=native \
    -g \
    -O3 \
    -shared \
    ${OMP_FLAG} \
    kernel.normal.o \
    bindings.normal.o \
    -o ${MODULE}.normal \
    ${KOKKOS_LIB_PATH}/libkokkoscontainers.so \
    ${KOKKOS_LIB_PATH}/libkokkoscore.so"

GCC_PCH_COMMAND="${COMPILER} \
    -I${KOKKOS_INCLUDE_PATH}/ \
    -I. \
    -O3 \
    -march=native -mtune=native \
    -g \
    ${OMP_FLAG} \
    -isystem ${KOKKOS_INCLUDE_PATH} \
    -fPIC \
    -std=c++${CXX_STANDARD} \
    -DSPACE=${EXEC_SPACE} \
    -o build/${COMPILER}/kernel.o \
    -c kernel.cpp \
    -Dpk_exec_space=Kokkos::${EXEC_SPACE}"

declare -A REPOS=(
    ["rapidjson"]="https://github.com/Tencent/rapidjson ab1842a2dae061284c0a62dca1cc6d5e7e37e346"
    ["opencv"]="https://github.com/opencv/opencv.git 0b39a51be8777de8e9a7c47d58d8cc596afa4f9b"
    ["boost"]="https://boostorg.jfrog.io/artifactory/main/release/1.85.0/source/boost_1_85_0.tar.gz 1.85.0"
)

function check_deps() {
    ! hash "git" && \
        { echo "missing git"; return 1; }
    ! hash "cmake" && \
        { echo "missing cmake"; return 1; }
    ! hash "ninja" && \
        { echo "missing ninja"; return 1; }
    return 0
}

# measure the average time of running a command $RUNS times
function measure_time() {
    local COMMAND=$1
    local RUNS=3
    local TOTAL_TIME=0

    for ((i = 1; i <= RUNS; i++)); do
        local OUTPUT=$({ time $COMMAND; } 2>&1)
        # echo "$OUTPUT"
        local TIME=$(echo "$OUTPUT" | grep real | awk '{print $2}' | sed 's/[^0-9.]*//g')
        # echo "Run $i: $TIME seconds"
        TOTAL_TIME=$(echo $TOTAL_TIME + $TIME | bc)
    done

    local AVERAGE_TIME=$(echo "scale=3; $TOTAL_TIME / $RUNS" | bc)
    # echo $AVERAGE_TIME
    printf "%.3f" $AVERAGE_TIME
}

function build_opencv() {
    local OPENCV_DIR="$PROJECTS_DIR/opencv"
    local BUILD_DIR="$OPENCV_DIR/build"
    local INSTALL_DIR="$OPENCV_DIR/install"

    if [ ! -d "$OPENCV_DIR" ]; then
        echo "OpenCV repository not found. Please get the repository first."
        return 1
    fi

    echo "Building OpenCV..."

    mkdir -p "$BUILD_DIR"
    mkdir -p "$INSTALL_DIR"

    (
        cd "$BUILD_DIR"
        cmake -G Ninja .. -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" || \
            { echo "Failed to configure OpenCV build."; return 1; }
        
        ninja || \
            { echo "Failed to build OpenCV."; return 1; }
        
        ninja install || \
            { echo "Failed to install OpenCV."; return 1; }
    )

    echo "OpenCV built and installed successfully."
}

function setup_compiler() {
    echo "Downloading Clang 15.0.6..."
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/clang+llvm-15.0.6-x86_64-linux-gnu-ubuntu-18.04.tar.xz
    echo "Extracting..."
    tar -xf clang+llvm-15.0.6-x86_64-linux-gnu-ubuntu-18.04.tar.xz
    echo "Done"
    rm clang+llvm-15.0.6-x86_64-linux-gnu-ubuntu-18.04.tar.xz
    # COMPILER=clang+llvm-15.0.6-x86_64-linux-gnu-ubuntu-18.04/bin/clang++
    # C_COMPILER=clang+llvm-15.0.6-x86_64-linux-gnu-ubuntu-18.04/bin/clang
}

function setup_yalla() {
    echo "Cloning Yalla..."
    git clone --depth 1 https://github.com/EngineeringSoftware/llvm-project-yalla.git -b yalla
    mkdir yalla-build
    mkdir yalla-install

    echo "Building Yalla..."
    pushd yalla-build
    cmake -G Ninja ../llvm-project-yalla/llvm -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" -DLLVM_ENABLE_RUNTIMES="openmp" \
     -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF -DLLVM_TARGETS_TO_BUILD=X86 \
     -DCMAKE_INSTALL_PREFIX=../yalla-install -DLIBOMP_USE_QUAD_PRECISION=FALSE -DCMAKE_C_COMPILER=$C_COMPILER -DCMAKE_CXX_COMPILER=$COMPILER
    ninja
    ninja install
    popd

    YALLA_PATH="yalla-install/bin/clang-yalla"
}

function setup_pykokkos() {
    git clone https://github.com/kokkos/pykokkos-base.git
    pushd pykokkos-base
    git checkout b8694f5 # This sets the Kokkos version to 3.7.02
    conda create -n pyk_cgo -y --file requirements.txt python=3.11 pybind11 patchelf
    conda activate pyk_cgo
    python setup.py install -- -DENABLE_LAYOUTS=ON -DENABLE_MEMORY_TRAITS=OFF -DENABLE_VIEW_RANKS=3 \
    -DENABLE_CUDA=OFF -DKokkos_ENABLE_CUDA=OFF -DENABLE_CUDA=OFF -DENABLE_THREADS=OFF -DKokkos_ENABLE_THREADS=OFF \
    -DENABLE_SERIAL=ON -DKokkos_ENABLE_SERIAL=ON -DENABLE_OPENMP=ON -DKokkos_ENABLE_OPENMP=ON \
    -DCMAKE_C_COMPILER=$C_COMPILER -DCMAKE_CXX_COMPILER=$COMPILER
    popd

    git clone https://github.com/kokkos/pykokkos.git
    pushd pykokkos
    git checkout 3d4afd2 # Commit from the paper
    pip install --user -e .
    sed -i 's,g++ \\,'"$COMPILER"' \\,g' pykokkos/core/compile.sh
    popd

    git clone https://github.com/kokkos/kokkos-tools.git
    pushd kokkos-tools
    git checkout c3e85a6e4d164951ab79b798c600fd931445e989
    pushd profiling/simple-kernel-timer
    make
    popd
    popd

    # Run initially to generate pk_cpp/
    conda activate pyk_cgo

    pushd kokkos/python_versions/02
    rm -r pk_cpp
    python 02.py
    popd

    pushd kokkos/python_versions/ExaMiniMD
    rm -r pk_cpp
    export PK_EXA_SPACE=OpenMP
    python src/main.py -il input/in.lj --fill
    popd

    pushd kokkos/python_versions/nstream
    rm -r pk_cpp
    python nstream.py 100 13
    popd

    pushd kokkos/python_versions/team_policy
    rm -r pk_cpp
    python team_policy.py --fill -S 25
    popd
}

# clone and checkout out a specific commit of a repository
function setup_repository() {
    local DIR=$1
    local REPO_URL=$2
    local COMMIT_HASH=$3

    if [ ! -d "$DIR" ]; then
        if [[ $DIR == "boost" ]]; then
            wget $REPO_URL || \
                { echo "Failed to download boost."; return 1; }
            tar -xzf boost_1_85_0.tar.gz || \
                { echo "Failed to extract boost."; return 1; }
            mv boost_1_85_0 boost
            rm boost_1_85_0.tar.gz
        else
            git clone $REPO_URL $DIR || \
                { echo "Failed to clone the repository."; return 1; }
            (
            cd $DIR
            git checkout $COMMIT_HASH || \
                { echo "Failed to checkout commit $COMMIT_HASH."; return 1; }
            )
        fi
        echo "Set up $DIR successfully."
    else
        echo "$DIR already exists."
    fi
}

# get all the open source projects used in the evaluation
function get_repos() {
    if [ ! -d "$PROJECTS_DIR" ]; then
        mkdir $PROJECTS_DIR
    fi
    (
    cd $PROJECTS_DIR
    for REPO in "${!REPOS[@]}"; do
        REPO_INFO=(${REPOS[$REPO]})
        REPO_URL=${REPO_INFO[0]}
        COMMIT_HASH=${REPO_INFO[1]}

        setup_repository $REPO $REPO_URL $COMMIT_HASH || \
            { echo "Failed to set up $REPO repository."; return 1; }
    done
    )
    build_opencv
}

# create and precompile a header file with specified headers to include
function precompile_header() {
    local HEADER_NAME=$1
    local INC_PATH=$2
    shift 2
    local FILES=("$@")

    # create the header file
    # echo "Creating file $HEADER_NAME with specified content."
    >$HEADER_NAME
    for FILE in "${FILES[@]}"; do
        echo "#include \"$FILE\"" >>$HEADER_NAME
    done

    # echo "File $HEADER_NAME created successfully."

    # precompile the header
    pch_times[${HEADER_NAME}]=$(measure_time "${COMPILER} ${flags} -x c++-header ${HEADER_NAME} -I ${INC_PATH}")
    # ${COMPILER} ${flags} -x c++-header $HEADER_NAME -I "$INC_PATH"|| \
    #     { echo "Failed to precompile: $HEADER_NAME."; return 1; }
    echo "File $HEADER_NAME precompiled successfully."
}

function process_project() {
    local PROJECT_NAME=$1
    local INC_PATH=$2
    local PCH_PATH=$3
    shift 3
    local FILES=("$@")

    pushd ${PCH_PATH}
    for FILE in "${FILES[@]}"; do
        local HEADER_PREFIX=$(echo "$FILE" | awk -F '|' '{print $1}')
        local HEADER_INC_PATH=$(echo "$FILE" | awk -F '|' '{print $4}')
        local HEADER_FILES=($(echo "$FILE" | awk -F '|' '{for (i=5; i<=NF; i++) print $i}'))
        precompile_header "$HEADER_PREFIX-all.h" "$HEADER_INC_PATH" "${HEADER_FILES[@]}"
    done
    popd
    
    # for FILE in "${FILES[@]}"; do
    #     local SOURCE_FILE=$(echo "$FILE" | awk -F '|' '{print $3}')
    #     local SOURCE_PATH=$(echo "$FILE" | awk -F '|' '{print $2}')
    #     local SUBJECT_NAME=$(echo "$FILE" | awk -F '|' '{print $1}')

    #     # base="${SOURCE_FILE%.cpp}"
    #     # yalla_file="$base.yalla.cpp"

    #     cd "$SOURCE_PATH"
    #     echo "Measuring: $PROJECT_NAME::$SUBJECT_NAME"
    #     # clang++ --version
    #     echo "Compiling without PCH..."
    #     time ${COMPILER} ${flags}  -c -I $INC_PATH $SOURCE_FILE
    #     echo "Compiling with PCH..."
    #     time clang++ ${flags}  -c -I $INC_PATH -include-pch $PCH_PATH/$SUBJECT_NAME-all.h.gch $SOURCE_FILE
    # done
    # )
}

function preprocess_all() {
    echo "preprocessing all PHC headers.."

    # rapidjson
    process_project "rapidjson" "$PROJECTS_DIR/rapidjson/include" "$PROJECTS_DIR/rapidjson/include/rapidjson" \
        "condense|$PROJECTS_DIR/rapidjson/example/condense|condense.cpp|..|error/en.h|filereadstream.h|filewritestream.h|reader.h|writer.h" \
        "archiver|$PROJECTS_DIR/rapidjson/example/archiver|archiver.cpp|..|rapidjson/document.h|rapidjson/prettywriter.h|rapidjson/stringbuffer.h" \
        "capitalize|$PROJECTS_DIR/rapidjson/example/capitalize|capitalize.cpp|..|rapidjson/reader.h|rapidjson/writer.h|rapidjson/filereadstream.h|rapidjson/filewritestream.h|rapidjson/error/en.h"
    
    # opencv
    process_project "opencv" "$PROJECTS_DIR/opencv/install/include/opencv4" "$PROJECTS_DIR/opencv/install/include/opencv4" \
        "3calibration|$PROJECTS_DIR/opencv/samples/cpp|3calibration.cpp|.|opencv2/calib3d.hpp|opencv2/imgproc.hpp|opencv2/imgcodecs.hpp|opencv2/highgui.hpp|opencv2/core/utility.hpp" \
        "drawing|$PROJECTS_DIR/opencv/samples/cpp|drawing.cpp|.|opencv2/core.hpp|opencv2/imgproc.hpp|opencv2/highgui.hpp" \
        "laplace|$PROJECTS_DIR/opencv/samples/cpp|laplace.cpp|.|opencv2/videoio.hpp|opencv2/imgproc.hpp|opencv2/highgui.hpp"
    
    # boost
    process_project "boost" "$PROJECTS_DIR/boost" "$PROJECTS_DIR/boost/boost" \
        "asio|$PROJECTS_DIR/boost/libs/asio/example/cpp11/chat|chat_server.cpp|..|boost/asio.hpp"
}

function run_yalla() {
    mkdir results

    pushd rapidjson/condense
    $YALLA_PATH --header_dir $PROJECTS_DIR/rapidjson/include/rapidjson condense.cpp -- -I$PROJECTS_DIR/rapidjson/include
    sed -i '/#include "rapidjson\/reader\.h"/d' condense.yalla.cpp
    sed -i '/#include "rapidjson\/writer\.h"/d' condense.yalla.cpp
    sed -i '/#include "rapidjson\/filereadstream\.h"/d' condense.yalla.cpp
    sed -i '/#include "rapidjson\/filewritestream\.h"/d' condense.yalla.cpp
    sed -i '/#include "rapidjson\/error\/en\.h"/d' condense.yalla.cpp

    sed -i '1s/^/#include <cstdio>\n/' condense.yalla.cpp
    popd

    pushd rapidjson/capitalize
    $YALLA_PATH --header_dir $PROJECTS_DIR/rapidjson/include/rapidjson --input_headers capitalize.h capitalize.cpp -- -I$PROJECTS_DIR/rapidjson/include
    sed -i '/#include "rapidjson\/reader\.h"/d' capitalize.yalla.cpp
    sed -i '/#include "rapidjson\/writer\.h"/d' capitalize.yalla.cpp
    sed -i '/#include "rapidjson\/filereadstream\.h"/d' capitalize.yalla.cpp
    sed -i '/#include "rapidjson\/filewritestream\.h"/d' capitalize.yalla.cpp
    sed -i '/#include "rapidjson\/error\/en\.h"/d' capitalize.yalla.cpp
    sed -i 's/return Wrapper_String_10(this,/return String(/g' capitalize.yalla.h

    sed -i 's/#include "capitalize.h"/#include "capitalize.yalla.h"/g' capitalize.yalla.cpp
    sed -i 's/#include "capitalize.h"/#include "capitalize.yalla.h"/g' wrappers.yalla.cpp

    sed -i '1s/^/template<typename OutputHandler>\nstruct CapitalizeFilter;\n/' wrappers.yalla.h
    popd

    pushd rapidjson/archiver
    $YALLA_PATH --header_dir $PROJECTS_DIR/rapidjson/include/rapidjson --input_headers archiver.h archiver.cpp -- -I$PROJECTS_DIR/rapidjson/include
    sed -i '/#include "rapidjson\/document\.h"/d' archiver.yalla.cpp
    sed -i '/#include "rapidjson\/prettywriter\.h"/d' archiver.yalla.cpp
    sed -i '/#include "rapidjson\/stringbuffer\.h"/d' archiver.yalla.cpp

    sed -i '1s/^/#include <cstring>\n/' archiver.yalla.cpp

    sed -i '/using namespace rapidjson;/a typedef GenericDocument<UTF8<>> Document;' archiver.yalla.cpp
    sed -i '/using namespace rapidjson;/a typedef GenericValue<UTF8<>> Value;' archiver.yalla.cpp
    sed -i '/using namespace rapidjson;/a typedef GenericStringBuffer<UTF8<>> StringBuffer;' archiver.yalla.cpp
    popd

    pushd opencv/3calibration
    $YALLA_PATH --header_dir $PROJECTS_DIR/opencv/install/include/opencv4/opencv2/ 3calibration.cpp -- -I$PROJECTS_DIR/opencv/install/include/opencv4/
    sed -i '23s/^/namespace cv { \
            typedef Point_<int> Point2i; \
            typedef Point_<float> Point2f; \
            typedef Point_<double> Point2d; \
            typedef Point3_<int> Point3i; \
            typedef Point3_<float> Point3f; \
            typedef Point3_<double> Point3d; \
            } \
            typedef std::string String;\n/' wrappers.yalla.h
    sed -i 's/&imageSize/imageSize/g' 3calibration.yalla.cpp
    sed -i 's/&cameraMatrix/cameraMatrix/g' 3calibration.yalla.cpp
    sed -i 's/&distCoeffs/distCoeffs/g' 3calibration.yalla.cpp
    sed -i 's/&R/R/g' 3calibration.yalla.cpp
    sed -i 's/&T/T/g' 3calibration.yalla.cpp
    sed -i 's/&E/E/g' 3calibration.yalla.cpp
    sed -i 's/&F/F/g' 3calibration.yalla.cpp
    sed -i 's/&temp_criteria/temp_criteria/g' 3calibration.yalla.cpp
    sed -i 's/&view/view/g' 3calibration.yalla.cpp
    sed -i 's/&boardSize/boardSize/g' 3calibration.yalla.cpp
    sed -i 's/&P_/P_/g' 3calibration.yalla.cpp
    sed -i 's/&Q/Q/g' 3calibration.yalla.cpp

    sed -i '/#include "opencv2\/calib3d.hpp"/d' 3calibration.yalla.cpp
    sed -i '/#include "opencv2\/imgproc.hpp"/d' 3calibration.yalla.cpp
    sed -i '/#include "opencv2\/imgcodecs.hpp"/d' 3calibration.yalla.cpp
    sed -i '/#include "opencv2\/highgui.hpp"/d' 3calibration.yalla.cpp
    sed -i '/#include "opencv2\/core\/utility.hpp"/d' 3calibration.yalla.cpp

    sed -i 's/return new cv::FileStorage(cv::operator<<<class cv::Mat>(*fs, *value));/return new cv::FileStorage(*fs << *value);/g' wrappers.yalla.cpp
    sed -i 's/return new std::basic_string<char, std::char_traits<char>, std::allocator<char>(yalla_object->operator basic_string());/return static_cast<std::basic_string<char, std::char_traits<char>, std::allocator<char>>>(*yalla_object);/g' wrappers.yalla.cpp

    perl -0777 -i -pe 's/bool Wrapper_yalla_findChessboardCorners_184\(cv::Mat \* image__0, cv::Size_<int> \* pattern_size_1, std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>& corners__2, int flags_3\){\nreturn yalla_findChessboardCorners\(image__0, pattern_size_1, corners__2, flags_3\);\n}\n//g' wrappers.yalla.cpp
    sed -i 's/cv::operator<<<class cv::Mat>(\*fs_0, \*value_1)/*fs_0 << *value_1/g' wrappers.yalla.cpp
    perl -0777 -i -pe 's/bool Wrapper_run3Calibration_185\(std::vector<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>, std::allocator<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>>> imagePoints1_0, std::vector<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>, std::allocator<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>>> imagePoints2_1, std::vector<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>, std::allocator<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>>> imagePoints3_2, cv::Size_<int>\* imageSize_3, cv::Size_<int>\* boardSize_4, float squareSize_5, float aspectRatio_6, int flags_7, cv::Mat\* cameraMatrix1_8, cv::Mat\* distCoeffs1_9, cv::Mat\* cameraMatrix2_10, cv::Mat\* distCoeffs2_11, cv::Mat\* cameraMatrix3_12, cv::Mat\* distCoeffs3_13, cv::Mat\* R12_14, cv::Mat\* T12_15, cv::Mat\* R13_16, cv::Mat\* T13_17\){\nreturn run3Calibration\(imagePoints1_0, imagePoints2_1, imagePoints3_2, \*imageSize_3, \*boardSize_4, squareSize_5, aspectRatio_6, flags_7, \*cameraMatrix1_8, \*distCoeffs1_9, \*cameraMatrix2_10, \*distCoeffs2_11, \*cameraMatrix3_12, \*distCoeffs3_13, \*R12_14, \*T12_15, \*R13_16, \*T13_17\);\n}//g' wrappers.yalla.cpp
    perl -0777 -i -pe 's/void Wrapper_yalla_drawChessboardCorners_178\(cv::Mat \* m1_0, cv::Size_<int> \* s_1, cv::Mat \* m2_2, bool b_3\){\nreturn yalla_drawChessboardCorners\(m1_0, s_1, m2_2, b_3\);\n}//g' wrappers.yalla.cpp

    perl -0777 -i -pe 's/void Wrapper_calcChessboardCorners_3\(cv::Size_<int>\* boardSize_0, float squareSize_1, std::vector<cv::Point3_<float> \*, std::allocator<cv::Point3_<float> \*>>& corners_2\){\nreturn calcChessboardCorners\(\*boardSize_0, squareSize_1, corners_2\);\n}//g' wrappers.yalla.cpp

    perl -0777 -i -pe 's/float Wrapper_yalla_rectify3Collinear_190\(cv::Mat \* cameraMatrix1_0, cv::Mat \* distCoeffs1_1, cv::Mat \* cameraMatrix2_2, cv::Mat \* distCoeffs2_3, cv::Mat \* cameraMatrix3_4, cv::Mat \* distCoeffs3_5, std::vector<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>, std::allocator<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>>>& imgpt1_6, std::vector<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>, std::allocator<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>>>& imgpt3_7, cv::Size_<int> \* imageSize_8, cv::Mat \* R12_9, cv::Mat \* T12_10, cv::Mat \* R13_11, cv::Mat \* T13_12, cv::Mat \* R1_13, cv::Mat \* R2_14, cv::Mat \* R3_15, cv::Mat \* P1_16, cv::Mat \* P2_17, cv::Mat \* P3_18, cv::Mat \* Q_19, double alpha_20, cv::Size_<int> \* newImgSize_21, cv::Rect_<int> \* roi1_22, cv::Rect_<int> \* roi2_23, int flags_24\){\nreturn yalla_rectify3Collinear\(cameraMatrix1_0, distCoeffs1_1, cameraMatrix2_2, distCoeffs2_3, cameraMatrix3_4, distCoeffs3_5, imgpt1_6, imgpt3_7, imageSize_8, R12_9, T12_10, R13_11, T13_12, R1_13, R2_14, R3_15, P1_16, P2_17, P3_18, Q_19, alpha_20, newImgSize_21, roi1_22, roi2_23, flags_24\);\n}//g' wrappers.yalla.cpp
    perl -0777 -i -pe 's/double Wrapper_yalla_calibrateCamera_10\(std::vector<std::vector<cv::Point3_<float> \*, std::allocator<cv::Point3_<float> \*>>, std::allocator<std::vector<cv::Point3_<float> \*, std::allocator<cv::Point3_<float> \*>>>>& _0, std::vector<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>, std::allocator<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>>>& _1, cv::Size_<int> \* _2, cv::Mat \* _cameraMatrix_3, cv::Mat \* _distCoeffs_4, std::vector<cv::Mat \*, std::allocator<cv::Mat \*>>& _rvecs_5, std::vector<cv::Mat \*, std::allocator<cv::Mat \*>>& _tvecs_6, int flags_7\){\nreturn yalla_calibrateCamera\(_0, _1, _2, _cameraMatrix_3, _distCoeffs_4, _rvecs_5, _tvecs_6, flags_7\);\n}//g' wrappers.yalla.cpp
    perl -0777 -i -pe 's/double Wrapper_yalla_stereoCalibrate_37\(std::vector<std::vector<cv::Point3_<float> \*, std::allocator<cv::Point3_<float> \*>>, std::allocator<std::vector<cv::Point3_<float> \*, std::allocator<cv::Point3_<float> \*>>>>& objectPoints_0, std::vector<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>, std::allocator<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>>>& imagePoints1_1, std::vector<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>, std::allocator<std::vector<cv::Point_<float> \*, std::allocator<cv::Point_<float> \*>>>>& imagePoints2_2, cv::Mat \* cameraMatrix1_3, cv::Mat \* distCoeffs1_4, cv::Mat \* cameraMatrix2_5, cv::Mat \* distCoeffs2_6, cv::Size_<int> \* imageSize_7, cv::Mat \* R_8, cv::Mat \* T_9, cv::Mat \* E_10, cv::Mat \* F_11, int flags_12, cv::TermCriteria \* criteria_13\){\nreturn yalla_stereoCalibrate\(objectPoints_0, imagePoints1_1, imagePoints2_2, cameraMatrix1_3, distCoeffs1_4, cameraMatrix2_5, distCoeffs2_6, imageSize_7, R_8, T_9, E_10, F_11, flags_12, criteria_13\);\n}//g' wrappers.yalla.cpp

    sed -i '/template FileStorage & cv::operator<<<double>(cv::FileStorage & fs, const double & value);/d' wrappers.yalla.cpp
    sed -i '/template FileStorage & cv::operator<<<int>(cv::FileStorage & fs, const int & value);/d' wrappers.yalla.cpp
    sed -i '/template FileStorage & cv::operator<<<class cv::Mat>(cv::FileStorage & fs, const class cv::Mat & value);/d' wrappers.yalla.cpp
    sed -i '1s/^/#include <cmath>\n/' wrappers.yalla.h
    sed -i '1s/^/#include <string>\n/' wrappers.yalla.h
    sed -i '1s/^/#include <vector>\n/' wrappers.yalla.h
    sed -i 's/Wrapper_yalla_findChessboardCorners_[[:digit:]]\+/yalla_findChessboardCorners/g' 3calibration.yalla.cpp
    sed -i 's/Wrapper_yalla_drawChessboardCorners_[[:digit:]]\+/yalla_drawChessboardCorners/g' 3calibration.yalla.cpp
    sed -i 's/Wrapper_yalla_calibrateCamera_[[:digit:]]\+/yalla_calibrateCamera/g' 3calibration.yalla.cpp
    sed -i 's/Wrapper_yalla_stereoCalibrate_[[:digit:]]\+/yalla_stereoCalibrate/g' 3calibration.yalla.cpp
    sed -i 's/Wrapper_yalla_rectify3Collinear_[[:digit:]]\+/yalla_rectify3Collinear/g' 3calibration.yalla.cpp
    sed -i 's/Wrapper_run3Calibration_[[:digit:]]\+/run3Calibration/g' 3calibration.yalla.cpp
    sed -i 's/Wrapper_calcChessboardCorners_[[:digit:]]\+/calcChessboardCorners/g' 3calibration.yalla.cpp
    popd

    pushd opencv/drawing
    $YALLA_PATH --header_dir $PROJECTS_DIR/opencv/install/include/opencv4/opencv2/ drawing.cpp -- -I$PROJECTS_DIR/opencv/install/include/opencv4/
    sed -i '14s/^/namespace cv { \
        typedef Point_<int> Point2i; \
        typedef Point_<float> Point2f; \
        typedef Point_<double> Point2d; \
        typedef Point2i Point; \
        }\n/' wrappers.yalla.h
    sed -i '1s/^/#include <string>\n \
        typedef std::string String;\n/' wrappers.yalla.h

    sed -i 's/&pt/pt/g' drawing.yalla.cpp

    sed -i '/#include "opencv2\/imgproc.hpp"/d' drawing.yalla.cpp
    sed -i '/#include "opencv2\/core.hpp"/d' drawing.yalla.cpp
    sed -i '/#include "opencv2\/highgui.hpp"/d' drawing.yalla.cpp
    popd

    pushd opencv/laplace
    $YALLA_PATH --header_dir $PROJECTS_DIR/opencv/install/include/opencv4/opencv2/ laplace.cpp -- -I$PROJECTS_DIR/opencv/install/include/opencv4/
    sed -i '10s/^/#include <string>\n \
        typedef std::string String; \
        typedef void (*TrackbarCallback)(int pos, void* userdata);\n/' wrappers.yalla.h

    perl -0777 -i -pe 's/#ifdef YALLA_KEEP_DEFAULT_ARGS\n = nullptr\n #endif\n, int borderType_4\n#ifdef YALLA_KEEP_DEFAULT_ARGS\n = 4\n #endif//g' wrappers.yalla.h
    perl -0777 -i -pe 's/#ifdef YALLA_KEEP_DEFAULT_ARGS\n = nullptr\n #endif\n, int borderType_4\n#ifdef YALLA_KEEP_DEFAULT_ARGS\n = 4\n #endif//g' wrappers.yalla.cpp
    sed -i '/, borderType_4/d' wrappers.yalla.cpp

    sed -i 's/temp_string/*temp_string/g' laplace.yalla.cpp
    sed -i '/#include "opencv2\/imgproc.hpp"/d' laplace.yalla.cpp
    sed -i '/#include "opencv2\/videoio.hpp"/d' laplace.yalla.cpp
    sed -i '/#include "opencv2\/highgui.hpp"/d' laplace.yalla.cpp
    sed -i 's/, cv::Point_<int>\* anchor_3//g' wrappers.yalla.h
    sed -i 's/, cv::Point_<int>\* anchor_3//g' wrappers.yalla.cpp
    popd

    pushd boost/chat_server
    $YALLA_PATH --header_dir $PROJECTS_DIR/boost chat_server.cpp --input_headers chat_message.hpp -- -I$PROJECTS_DIR/boost
    perl -0777 -i -pe 's/#ifdef YALLA_KEEP_DEFAULT_ARGS\n = default_completion_token_t<typename AsyncWriteStream::executor_type>\n #endif\n//g' wrappers.yalla.h
    perl -0777 -i -pe 's/#ifdef YALLA_KEEP_DEFAULT_ARGS\n = default_completion_token_t<typename AsyncWriteStream::executor_type>\n #endif\n//g' wrappers.yalla.cpp
    perl -0777 -i -pe 's/namespace boost {namespace asio {template <typename AsyncReadStream, typename MutableBufferSequence, typename ReadToken\n#ifdef YALLA_KEEP_DEFAULT_ARGS\n = default_completion_token_t<typename AsyncReadStream::executor_type>\n #endif\n>\ndecltype\(async_initiate<ReadToken, void \(boost::system::error_code, std::size_t\)>\(declval<detail::initiate_async_read<AsyncReadStream> >\(\), token, buffers, transfer_all\(\)\)\) async_read\(AsyncReadStream \& s, const MutableBufferSequence \& buffers, ReadToken \&\& token, constraint_t<is_mutable_buffer_sequence<MutableBufferSequence>::value> yalla_placeholder_arg_3\);}}//g' wrappers.yalla.h
    perl -0777 -i -pe 's/namespace boost {namespace asio {template <typename AsyncWriteStream, typename ConstBufferSequence, typename WriteToken\n>\ndecltype\(async_initiate<WriteToken, void \(boost::system::error_code, std::size_t\)>\(declval<detail::initiate_async_write<AsyncWriteStream> >\(\), token, buffers, transfer_all\(\)\)\) async_write\(AsyncWriteStream & s, const ConstBufferSequence & buffers, WriteToken && token, constraint_t<is_const_buffer_sequence<ConstBufferSequence>::value> yalla_placeholder_arg_3\);}}//g' wrappers.yalla.h
    sed -i '/decltype(async_initiate<WriteToken, void (boost::system::error_code, std::size_t)>(declval<detail::initiate_async_write<AsyncWriteStream> >(), token, buffers, transfer_all()))/d' wrappers.yalla.cpp
    perl -0777 -i -pe 's/#ifdef YALLA_KEEP_DEFAULT_ARGS\n = default_completion_token_t<typename AsyncReadStream::executor_type>\n #endif\n//g' wrappers.yalla.h
    perl -0777 -i -pe 's/#ifdef YALLA_KEEP_DEFAULT_ARGS\n = default_completion_token_t<typename AsyncReadStream::executor_type>\n #endif\n//g' wrappers.yalla.cpp
    sed -i 's/chat_session:://g' wrappers.yalla.h
    sed -i 's/chat_session:://g' wrappers.yalla.cpp
    perl -0777 -i -pe 's/template <typename Protocol1, typename Executor1\n#ifdef YALLA_KEEP_DEFAULT_ARGS\n = boost::asio::any_io_executor\n #endif\n>\nboost::asio::basic_socket_acceptor<Protocol, Executor>\* Wrapper_basic_socket_acceptor\(\);//g' wrappers.yalla.h
    sed -i '/#include "wrappers\.yalla\.h"/d' chat_message.yalla.hpp
    sed -i '/#include "wrappers\.yalla\.h"/d' chat_server.yalla.cpp
    sed -i '22s/^/#include "wrappers\.yalla\.h"\n/' chat_server.yalla.cpp

    perl -0777 -i -pe 's/namespace boost {namespace asio {template <typename AsyncReadStream, typename MutableBufferSequence, typename ReadToken\n#ifdef YALLA_KEEP_DEFAULT_ARGS\n = default_completion_token_t<typename AsyncReadStream::executor_type>\n #endif\n>\ndecltype(async_initiate<ReadToken, void (boost::system::error_code, std::size_t)>(declval<detail::initiate_async_read<AsyncReadStream> >(), token, buffers, transfer_all())) async_read(AsyncReadStream & s, const MutableBufferSequence & buffers, ReadToken && token, constraint_t<is_mutable_buffer_sequence<MutableBufferSequence>::value> yalla_placeholder_arg_3);}}//g' wrappers.yalla.h
    perl -0777 -i -pe 's/namespace boost {namespace asio {template <typename AsyncWriteStream, typename ConstBufferSequence, typename WriteToken\n#ifdef YALLA_KEEP_DEFAULT_ARGS\n = default_completion_token_t<typename AsyncWriteStream::executor_type>\n #endif\n>\ndecltype(async_initiate<WriteToken, void (boost::system::error_code, std::size_t)>(declval<detail::initiate_async_write<AsyncWriteStream> >(), token, buffers, transfer_all())) async_write(AsyncWriteStream & s, const ConstBufferSequence & buffers, WriteToken && token, constraint_t<is_const_buffer_sequence<ConstBufferSequence>::value> yalla_placeholder_arg_3);}}//g' wrappers.yalla.h
    perl -0777 -i -pe 's/namespace boost {namespace asio {template <typename AsyncReadStream, typename MutableBufferSequence, typename ReadToken\n#ifdef YALLA_KEEP_DEFAULT_ARGS\n = default_completion_token_t<typename AsyncReadStream::executor_type>\n #endif\n>\ndecltype(async_initiate<ReadToken, void (boost::system::error_code, std::size_t)>(declval<detail::initiate_async_read<AsyncReadStream> >(), token, buffers, transfer_all())) async_read(AsyncReadStream & s, const MutableBufferSequence & buffers, ReadToken && token, constraint_t<is_mutable_buffer_sequence<MutableBufferSequence>::value> yalla_placeholder_arg_3);}}//g' wrappers.yalla.cpp
    perl -0777 -i -pe 's/namespace boost {namespace asio {template <typename AsyncWriteStream, typename ConstBufferSequence, typename WriteToken\n#ifdef YALLA_KEEP_DEFAULT_ARGS\n = default_completion_token_t<typename AsyncWriteStream::executor_type>\n #endif\n>\ndecltype(async_initiate<WriteToken, void (boost::system::error_code, std::size_t)>(declval<detail::initiate_async_write<AsyncWriteStream> >(), token, buffers, transfer_all())) async_write(AsyncWriteStream & s, const ConstBufferSequence & buffers, WriteToken && token, constraint_t<is_const_buffer_sequence<ConstBufferSequence>::value> yalla_placeholder_arg_3);}}//g' wrappers.yalla.cpp

    sed -i 's/boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor> Wrapper_move_2(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>* __t_0);/boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>* Wrapper_move_2(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>* __t_0);/g' wrappers.yalla.h
    sed -i 's/boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor> Wrapper_move_2(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>* __t_0);/boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>* Wrapper_move_2(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>* __t_0);/g' wrappers.yalla.cpp

    sed -i 's/std::Wrapper_move_2\(socket\)/\&std::Wrapper_move_2(socket)/g' chat_server.yalla.cpp
    sed -i '1b;/^private:/d' chat_server.yalla.cpp
    sed -i '/#include <boost\/asio.hpp>/d' chat_server.yalla.cpp
    sed -i 's/boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor> Wrapper_move_2/boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>* Wrapper_move_2/g' wrappers.yalla.h

    perl -0777 -i -pe 's/template <typename Protocol1, typename Executor1\n#ifdef YALLA_KEEP_DEFAULT_ARGS\n = boost::asio::any_io_executor\n #endif\n>\nboost::asio::basic_socket_acceptor<Protocol, Executor>\* Wrapper_basic_socket_acceptor\(\){\nreturn new boost::asio::basic_socket_acceptor<Protocol1, Executor1>\(\);\n}//g' wrappers.yalla.cpp
    sed -i 's/\*other_0/std::move(*other_0)/g' wrappers.yalla.cpp
    sed -i 's/void Wrapper_async_read_4(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>\* s_0, const boost::asio::mutable_buffers_1\* buffers_1, do_read_header_functor\& token_2, int _3/template <typename T> void Wrapper_async_read_4\(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>* s_0, const boost::asio::mutable_buffers_1* buffers_1, T\& token_2, int _3/g' wrappers.yalla.cpp
    sed -i 's/void Wrapper_async_read_4(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>\* s_0, const boost::asio::mutable_buffers_1\* buffers_1, do_read_header_functor\& token_2, int _3/template <typename T> void Wrapper_async_read_4\(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>* s_0, const boost::asio::mutable_buffers_1* buffers_1, T\& token_2, int _3/g' wrappers.yalla.h
    sed -i 's/void Wrapper_async_read_7(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>\* s_0, const boost::asio::mutable_buffers_1\* buffers_1, do_read_body_functor\& token_2, int _3/template <typename T> void Wrapper_async_read_7(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>\* s_0, const boost::asio::mutable_buffers_1\* buffers_1, T\& token_2, int _3/g' wrappers.yalla.h
    sed -i 's/void Wrapper_async_read_7(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>\* s_0, const boost::asio::mutable_buffers_1\* buffers_1, do_read_body_functor\& token_2, int _3/template <typename T> void Wrapper_async_read_7(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>\* s_0, const boost::asio::mutable_buffers_1\* buffers_1, T\& token_2, int _3/g' wrappers.yalla.cpp
    sed -i 's/void Wrapper_async_write_10(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>\* s_0, const boost::asio::mutable_buffers_1\* buffers_1, do_write_functor\& token_2, int _3/template <typename T> void Wrapper_async_write_10\(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>\* s_0, const boost::asio::mutable_buffers_1\* buffers_1, T\& token_2, int _3/g' wrappers.yalla.h
    sed -i 's/void Wrapper_async_write_10(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>\* s_0, const boost::asio::mutable_buffers_1\* buffers_1, do_write_functor\& token_2, int _3/template <typename T> void Wrapper_async_write_10\(boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::any_io_executor>\* s_0, const boost::asio::mutable_buffers_1\* buffers_1, T\& token_2, int _3/g' wrappers.yalla.cpp

    sed -i '/boost::asio::async_write/d' wrappers.yalla.cpp
    sed -i '/boost::asio::async_read/d' wrappers.yalla.cpp
    sed -i '/std::remove_reference/d' wrappers.yalla.cpp
    perl -0777 -i -pe 's/namespace boost {namespace asio {template <typename AsyncReadStream, typename MutableBufferSequence, typename ReadToken\n>\ndecltype\(async_initiate<ReadToken, void \(boost::system::error_code, std::size_t\)>\(declval<detail::initiate_async_read<AsyncReadStream> >\(\), token, buffers, transfer_all\(\)\)\) async_read\(AsyncReadStream & s, const MutableBufferSequence & buffers, ReadToken && token, constraint_t<is_mutable_buffer_sequence<MutableBufferSequence>::value> yalla_placeholder_arg_3\);}}//g' wrappers.yalla.h
    popd
}

function compile_yalla() {
    rapidjson_include=$PROJECTS_DIR/rapidjson/include
    opencv_include=$PROJECTS_DIR/opencv/install/include/opencv4
    opencv_lib=$PROJECTS_DIR/opencv/install/lib/
    boost_include=$PROJECTS_DIR/boost/

    mkdir results

    for mode in "normal" "yalla" "pch"; do
        output_file="results/compilation_other.clang++.${mode}.csv"
        echo "Source,Benchmark,PCH time[s],Compilation time[s],Linking time[s],Run time[s]" > "${output_file}"
        
        pushd rapidjson/archiver
        rm *.o
        rm a.out

        benchmark="archiver"
        if [ "${mode}" == "yalla" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c ${benchmark}.${mode}.cpp")
            eval "${COMPILER} ${flags} -c wrappers.yalla.cpp -I${rapidjson_include}"
            eval "${COMPILER} ${flags} -c archivertest.cpp"
            linking_time=$(measure_time "${COMPILER} *.o")
            pch_time="0"
        elif [ "${mode}" == "pch" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${rapidjson_include} -include-pch ${rapidjson_include}/rapidjson/${benchmark}-all.h.gch ${benchmark}.cpp")
            eval "${COMPILER} ${flags} -c archivertest.cpp"
            linking_time=$(measure_time "${COMPILER} *.o")
            pch_time=${pch_times["${benchmark}-all.h"]}
        else
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${rapidjson_include}  ${benchmark}.cpp")
            eval "${COMPILER} ${flags} -c archivertest.cpp"
            linking_time=$(measure_time "${COMPILER} *.o")
            pch_time="0"
        fi

        run_time=$(measure_time "./a.out")
        popd

        echo "rapidjson,${benchmark},${pch_time},${compilation_time},${linking_time},${run_time}" >> "${output_file}"

        pushd rapidjson/capitalize
        rm *.o
        rm a.out

        benchmark="capitalize"
        if [ "${mode}" == "yalla" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c ${benchmark}.${mode}.cpp")
            eval "${COMPILER} ${flags} -c wrappers.yalla.cpp -I${rapidjson_include}"
            linking_time=$(measure_time "${COMPILER} *.o")
            pch_time="0"
        elif [ "${mode}" == "pch" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${rapidjson_include} -include-pch ${rapidjson_include}/rapidjson/${benchmark}-all.h.gch ${benchmark}.cpp")
            linking_time="0.000"
            pch_time=${pch_times["${benchmark}-all.h"]}
        else
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${rapidjson_include} ${benchmark}.cpp")
            linking_time="0.000"
            pch_time="0"
        fi

        run_time=$(measure_time "./a.out")
        popd

        echo "rapidjson,${benchmark},${pch_time},${compilation_time},${linking_time},${run_time}" >> "${output_file}"

        pushd rapidjson/condense
        rm *.o
        rm a.out

        benchmark="condense"
        if [ "${mode}" == "yalla" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c ${benchmark}.${mode}.cpp")
            eval "${COMPILER} ${flags} -c wrappers.yalla.cpp -I${rapidjson_include}"
            linking_time=$(measure_time "${COMPILER} *.o")
            pch_time="0"
        elif [ "${mode}" == "pch" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${rapidjson_include} -include-pch ${rapidjson_include}/rapidjson/${benchmark}-all.h.gch ${benchmark}.cpp")
            linking_time="0.000"
            pch_time=${pch_times["${benchmark}-all.h"]}
        else
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${rapidjson_include} ${benchmark}.cpp")
            linking_time="0.000"
            pch_time="0"
        fi

        run_time=$(measure_time "./a.out")
        popd

        echo "rapidjson,${benchmark},${pch_time},${compilation_time},${linking_time},${run_time}" >> "${output_file}"

        pushd opencv/3calibration
        rm *.o
        rm a.out

        benchmark="3calibration"
        eval "${COMPILER} ${flags} -c 3calibration.supplementary.yalla.cpp -I${opencv_include}"
        if [ "${mode}" == "yalla" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c ${benchmark}.${mode}.cpp")
            eval "${COMPILER} ${flags} -c wrappers.yalla.cpp -I${opencv_include}"
            pch_time="0"
        elif [ "${mode}" == "pch" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${opencv_include} -include-pch ${opencv_include}/${benchmark}-all.h.gch ${benchmark}.cpp")
            pch_time=${pch_times["${benchmark}-all.h"]}
        else
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${opencv_include} ${benchmark}.cpp")
            pch_time="0"
        fi
        linking_time=$(measure_time "/bin/bash link.sh $PROJECTS_DIR/opencv/build")
        echo $linking_time
        patchelf --set-rpath ${opencv_lib} a.out

        run_time=$(measure_time "./a.out -w=10 -h=10 images/image.XML")
        popd

        echo "opencv,${benchmark},${pch_time},${compilation_time},${linking_time},${run_time}" >> "${output_file}"

        pushd opencv/drawing
        rm *.o
        rm a.out

        benchmark="drawing"
        if [ "${mode}" == "yalla" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c ${benchmark}.${mode}.cpp")
            eval "${COMPILER} ${flags} -c wrappers.yalla.cpp -I${opencv_include}"
            pch_time="0"
        elif [ "${mode}" == "pch" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${opencv_include} -include-pch ${opencv_include}/${benchmark}-all.h.gch ${benchmark}.cpp")
            pch_time=${pch_times["${benchmark}-all.h"]}
        else
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${opencv_include} ${benchmark}.cpp")
            pch_time="0"
        fi
        linking_time=$(measure_time "/bin/bash link.sh $PROJECTS_DIR/opencv/build")
        patchelf --set-rpath ${opencv_lib} a.out

        run_time=$(measure_time "./a.out")
        popd

        echo "opencv,${benchmark},${pch_time},${compilation_time},${linking_time},${run_time}" >> "${output_file}"

        pushd opencv/laplace
        rm *.o
        rm a.out

        benchmark="laplace"
        if [ "${mode}" == "yalla" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c ${benchmark}.${mode}.cpp")
            eval "${COMPILER} ${flags} -c wrappers.yalla.cpp -I${opencv_include}"
            pch_time="0"
        elif [ "${mode}" == "pch" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${opencv_include} -include-pch ${opencv_include}/${benchmark}-all.h.gch ${benchmark}.cpp")
            pch_time=${pch_times["${benchmark}-all.h"]}
        else
            compilation_time=$(measure_time "${COMPILER} ${flags} -c -I${opencv_include} ${benchmark}.cpp")
            pch_time="0"
        fi
        linking_time=$(measure_time "/bin/bash link.sh $PROJECTS_DIR/opencv/build")
        patchelf --set-rpath ${opencv_lib} a.out

        run_time=$(measure_time "./a.out")
        popd

        echo "opencv,${benchmark},${pch_time},${compilation_time},${linking_time},${run_time}" >> "${output_file}"

        pushd boost/chat_server
        rm *.o
        rm a.out

        benchmark="chat_server"
        if [ "${mode}" == "yalla" ]; then
            compilation_time=$(measure_time "${COMPILER} ${flags} -c ${benchmark}.${mode}.cpp")
            eval "${COMPILER} ${flags} -c wrappers.yalla.cpp -I${boost_include}"
            linking_time=$(measure_time "${COMPILER} ${flags} *.o -lpthread")
            pch_time="0"
        elif [ "${mode}" == "pch" ]; then
            compilation_time=$(measure_time "${COMPILER} -c ${flags} -I${boost_include} -include-pch ${boost_include}/boost/asio-all.h.gch ${benchmark}.cpp -lpthread")
            pch_time=${pch_times["asio-all.h"]}
            linking_time=$(measure_time "${COMPILER} ${flags} *.o -lpthread")
        else
            compilation_time=$(measure_time "${COMPILER} -c ${flags} -I${boost_include} ${benchmark}.cpp -lpthread")
            pch_time="0"
            linking_time=$(measure_time "${COMPILER} ${flags} *.o -lpthread")
        fi

        run_time="0.011"
        popd

        echo "boost,${benchmark},${pch_time},${compilation_time},${linking_time},${run_time}" >> "${output_file}"
    done
}

function setup_pykokkos_cpp_for_yalla() {
    for kernel in "${KERNELS[@]}"; do
        modified_functor_path=${PWD}/kokkos/cpp_versions/${kernel}/functor.hpp
        modified_kernel_path=${PWD}/kokkos/cpp_versions/${kernel}/kernel.cpp
        normal_bindings_path=${PWD}/kokkos/cpp_versions/${kernel}/bindings.normal.cpp
        yalla_bindings_path=${PWD}/kokkos/cpp_versions/${kernel}/bindings.yalla.cpp

        kernel_dir=$(find ${PWD}/kokkos/python_versions -name ${kernel})

        pushd ${kernel_dir}
        functor_path=$(find -name functor.hpp)
        bindings_path=$(find -name bindings.cpp | grep -v Serial)
        bindings_dir=$(dirname ${bindings_path})
        ${CLANG_BIN_PATH}/clang-format -i ${bindings_path}
        module_id=$(grep ", k) {" ${bindings_path} | cut -d, -f1 | xargs)
        echo "${module_id}"

        functor_dir=$(dirname ${functor_path})
        new_normal_bindings_path=${bindings_dir}/bindings.normal.cpp
        new_yalla_bindings_path=${bindings_dir}/bindings.yalla.cpp

        cp ${modified_functor_path} ${functor_dir}
        cp ${modified_kernel_path} ${functor_dir}
        cp ${normal_bindings_path} ${new_normal_bindings_path}
        cp ${yalla_bindings_path} ${new_yalla_bindings_path}

        sed -i -e "s/PLACEHOLDER/${module_id}/g" ${new_normal_bindings_path}
        sed -i -e "s/PLACEHOLDER/${module_id}/g" ${new_yalla_bindings_path}
        popd
    done
}

function run_yalla_pyk() {
    for kernel in "${KERNELS[@]}"; do
        kernel_dir=$(find ${PWD}/kokkos/python_versions -name ${kernel})
        kernel_dir=$(find ${kernel_dir} -name functor.hpp)
        kernel_dir=$(dirname ${kernel_dir})
        pushd ${kernel_dir}

        functor_path=$(find -name functor.hpp)
        kernel_path=$(find -name kernel.cpp)

        if [ "${kernel}" == "02_yAx" ]; then
            echo "Measuring time of running Yalla for kernel 02_yAx"
            yalla_tool_time_02=$(measure_time "$YALLA_PATH --header_dir ${KOKKOS_INCLUDE_PATH} ${kernel_path} --input_headers ${functor_path} -- -isystem ${KOKKOS_INCLUDE_PATH} -DEXEC_SPACE=Kokkos::OpenMP -Dpk_exec_space=Kokkos::OpenMP -fopenmp")
        else
            $YALLA_PATH --header_dir "${KOKKOS_INCLUDE_PATH}" "${kernel_path}" \
            --input_headers "${functor_path}" -- -isystem "${KOKKOS_INCLUDE_PATH}" -DEXEC_SPACE=Kokkos::OpenMP -Dpk_exec_space=Kokkos::OpenMP -fopenmp
        fi

        sed -i '/#include <Kokkos_Core.hpp>/d' kernel.yalla.cpp
        sed -i 's/#include "functor.hpp"/#include "functor.yalla.hpp"/g' kernel.yalla.cpp
        popd
    done
}

function generate_all_so_files() {
    mkdir results
    compiler_name=$(basename ${COMPILER})
    normal_output_file="results/compilation_kokkos.normal.${compiler_name}.csv"
    yalla_output_file="results/compilation_kokkos.yalla.${compiler_name}.csv"
    pch_output_file="results/compilation_kokkos.pch.${compiler_name}.csv"

    echo "Benchmark,Kernel time [s],Bindings time [s],Link time [s]" > "${normal_output_file}"
    echo "Benchmark,Kernel time [s],Wrappers time [s],Bindings time [s],Link time [s]" > "${yalla_output_file}"
    echo "Benchmark,PCH time [s],Kernel time [s],Bindings time [s],Link time [s]" > "${pch_output_file}"

    for kernel in "${KERNELS[@]}"; do
        dir=$(find ${PWD}/kokkos/python_versions -name ${kernel})
        dir=$(find ${dir} -name functor.hpp)
        dir=$(dirname ${dir})
        if [ -d "$dir" ]; then
            pushd $dir
            echo "Compiling normal in $dir"
            kernel_time_normal=$(measure_time "$NORMAL_COMMAND")
            bindings_time_normal=$(measure_time "$NORMAL_BINDINGS_COMMAND")
            link_time_normal=$(measure_time "$NORMAL_LINK_COMMAND")
            # kernel_time_pch=$(measure_time "$GCC_PCH_COMMAND")

            echo "Compiling yalla in $dir"
            kernel_time_yalla=$(measure_time "$YALLA_COMMAND")
            wrappers_time_yalla=$(measure_time "$YALLA_WRAPPERS_COMMAND")
            bindings_time_yalla=$(measure_time "$YALLA_BINDINGS_COMMAND")
            link_time_yalla=$(measure_time "$YALLA_LINK_COMMAND")
            
            echo "Compiling pch in $dir"
            # echo "PCH Command: $PCH_COMMAND"
            pch_time_pch=$(measure_time "$PCH_COMMAND")
            # echo "Kernel Command: $CLANG_PCH_COMMAND"
            kernel_time_pch=$(measure_time "$CLANG_PCH_COMMAND")
            # echo "Bindings Command: $NORMAL_BINDINGS_COMMAND"
            bindings_time_pch=$(measure_time "$PCH_BINDINGS_COMMAND")
            # echo "Link Command: $NORMAL_LINK_COMMAND"
            link_time_pch=$(measure_time "$NORMAL_LINK_COMMAND")

            if [ "${kernel}" == "02_yAx" ]; then
                # record time for 02_yAx
                normal_comp_time_02=${kernel_time_normal}
                yalla_comp_time_02=${kernel_time_yalla}
                yalla_wrapper_time_02=${wrappers_time_yalla}

                $NORMAL_COMMAND -ftime-trace
                mv kernel.normal.json ${_DIR}/results/traces/02-normal.json
                $YALLA_COMMAND -ftime-trace
                mv kernel.yalla.json ${_DIR}/results/traces/02-yalla.json
                $CLANG_PCH_COMMAND -ftime-trace
                mv kernel.normal.json ${_DIR}/results/traces/02-pch.json
            fi

            popd

            echo "${kernel},${kernel_time_normal},${bindings_time_normal},${link_time_normal}" >> "${normal_output_file}"
            echo "${kernel},${kernel_time_yalla},${wrappers_time_yalla},${bindings_time_yalla},${link_time_yalla}" >> "${yalla_output_file}"
            echo "${kernel},${pch_time_pch},${kernel_time_pch},${bindings_time_pch},${link_time_pch}" >> "${pch_output_file}"

        fi
    done
}

function copy_so_files() {
    mode="${1}"

    for kernel in "${KERNELS[@]}"; do
        dir=$(find ${PWD}/kokkos/python_versions -name ${kernel})
        dir=$(find ${dir} -name functor.hpp)
        dir=$(dirname ${dir})
        echo "entering ${dir}"
        if [ -d "$dir" ]; then
            pushd "${dir}"
            cp ${MODULE}.${mode} OpenMP/${MODULE}
            patchelf --add-rpath "${KOKKOS_LIB_PATH}" OpenMP/${MODULE}
            popd
        fi
    done
}

function run_benchmarks() {
    conda activate pyk_cgo
    export KOKKOS_TOOLS_LIBS=${PWD}/kokkos-tools/profiling/simple-kernel-timer/kp_kernel_timer.so
    KP_READER=${PWD}/kokkos-tools/profiling/simple-kernel-timer/kp_reader
    compiler_name=$(basename ${COMPILER})

    for mode in "normal" "yalla"; do
        echo "Running with mode ${mode}"
        copy_so_files "${mode}"
        
        kernels_output_file="results/kernels.${mode}.${compiler_name}.csv"
        total_output_file="results/total.${mode}.${compiler_name}.csv"
        echo "Benchmark,Kernel,${mode} time [s]" > "${kernels_output_file}"
        echo "Total,${mode} time [s]" > "${total_output_file}"

        pushd ${PWD}/kokkos/python_versions/02
        command="python 02.py"

        echo "Running command ${command}"

        std_output=$(eval "${command}")
        dat_file=$(echo "${std_output}" | tail -n 1 | cut -d' ' -f6)
        profiler_output_02=$(eval "${KP_READER} ${dat_file}")

        total_02=$(measure_time "$command")
        rm *.dat
        popd

        kernel_02=$(echo "${profiler_output_02}" | grep "pk_functor_yAx" -A 1 | tail -n 1 | cut -d' ' -f7)

        echo "02,02,${kernel_02}" >> "${kernels_output_file}"
        echo "02,${total_02}" >> "${total_output_file}"

        pushd ${PWD}/kokkos/python_versions/ExaMiniMD
        command="python src/main.py -il input/in.lj --fill"

        echo "Running command ${command}"

        std_output=$(eval "${command}")
        dat_file=$(echo "${std_output}" | tail -n 1 | cut -d' ' -f6)
        profiler_output_examinimd=$(eval "${KP_READER} ${dat_file}")

        total_exa=$(measure_time "$command")
        rm *.dat
        popd

        kernel_binning=$(echo "${profiler_output_examinimd}" | grep -x "\- Binning::AssignOffsets" -A 1 | tail -n 1 | cut -d' ' -f7)
        kernel_final_integrate=$(echo "${profiler_output_examinimd}" | grep -x "\- IntegratorNVE::final_integrate" -A 1 | tail -n 1 | cut -d' ' -f7)
        kernel_fullneigh_for=$(echo "${profiler_output_examinimd}" | grep -x "\- ForceLJNeigh::compute" -A 1 | tail -n 1 | cut -d' ' -f7)
        kernel_fullneigh_reduce=$(echo "${profiler_output_examinimd}" | grep -x "\- ForceLJNeigh::compute_energy" -A 1 | tail -n 1 | cut -d' ' -f7)
        kernel_initial_integrate=$(echo "${profiler_output_examinimd}" | grep -x "\- IntegratorNVE::initial_integrate" -A 1 | tail -n 1 | cut -d' ' -f7)
        kernel_get_n=$(echo "${profiler_output_examinimd}" | grep -x "\- init_s" -A 1 | tail -n 1 | cut -d' ' -f7) # currently much slower with gcc lto
        kernel_init_x=$(echo "${profiler_output_examinimd}" | grep -x "\- init_x" -A 1 | tail -n 1 | cut -d' ' -f7)
        kernel_temperature=$(echo "${profiler_output_examinimd}" | grep -x "\- Temperature" -A 1 | tail -n 1 | cut -d' ' -f7)
        kernel_sort_binbinning=$(echo "${profiler_output_examinimd}" | grep -x "\- Kokkos::Sort::BinBinning" -A 1 | tail -n 1 | cut -d' ' -f7)
        kernel_sort_bincount=$(echo "${profiler_output_examinimd}" | grep -x "\- Kokkos::Sort::BinCount" -A 1 | tail -n 1 | cut -d' ' -f7)
        kernel_sort_binoffset=$(echo "${profiler_output_examinimd}" | grep -x "\- Kokkos::Sort::BinOffset" -A 1 | tail -n 1 | cut -d' ' -f7)
        kernel_sort_copy=$(echo "${profiler_output_examinimd}" | grep -x "\- Kokkos::Sort::Copy" -A 1 | tail -n 1 | cut -d' ' -f7)
        kernel_sort_copypermute=$(echo "${profiler_output_examinimd}" | grep -x "\- Kokkos::Sort::CopyPermute" -A 1 | tail -n 1 | cut -d' ' -f7)

        echo "ExaMiniMD,Binning::AssignOffset,${kernel_binning}" >> "${kernels_output_file}"
        echo "ExaMiniMD,IntegratorNVE::final_integrate,${kernel_final_integrate}" >> "${kernels_output_file}"
        echo "ExaMiniMD,ForceLJNeigh::compute,${kernel_fullneigh_for}" >> "${kernels_output_file}"
        echo "ExaMiniMD,ForceLJNeigh::compute_energy,${kernel_fullneigh_reduce}" >> "${kernels_output_file}"
        echo "ExaMiniMD,IntegratorNVE::initial_integrate,${kernel_initial_integrate}" >> "${kernels_output_file}"
        echo "ExaMiniMD,init_s,${kernel_get_n}" >> "${kernels_output_file}"
        echo "ExaMiniMD,init_x,${kernel_init_x}" >> "${kernels_output_file}"
        echo "ExaMiniMD,Temperature,${kernel_temperature}" >> "${kernels_output_file}"
        echo "ExaMiniMD,Binning::AssignOffset,${kernel_binning}" >> "${kernels_output_file}"
        echo "ExaMiniMD,Kokkos::Sort::BinBinning,${kernel_sort_binbinning}" >> "${kernels_output_file}"
        echo "ExaMiniMD,Kokkos::Sort::BinCount,${kernel_sort_bincount}" >> "${kernels_output_file}"
        echo "ExaMiniMD,Kokkos::Sort::BinOffset,${kernel_sort_binoffset}" >> "${kernels_output_file}"
        echo "ExaMiniMD,Kokkos::Sort::Copy,${kernel_sort_copy}" >> "${kernels_output_file}"
        echo "ExaMiniMD,Kokkos::Sort::CopyPermute,${kernel_sort_copypermute}" >> "${kernels_output_file}"
        echo "ExaMiniMD,${total_exa}" >> "${total_output_file}"

        pushd ${PWD}/kokkos/python_versions/team_policy
        command="python team_policy.py --fill -S 25"

        echo "Running command ${command}"

        std_output=$(eval "${command}")
        dat_file=$(echo "${std_output}" | tail -n 1 | cut -d' ' -f6)
        profiler_output_team_policy=$(eval "${KP_READER} ${dat_file}")

        total_team_policy=$(measure_time "$command")
        rm *.dat
        popd

        kernel_team_policy=$(echo "${profiler_output_team_policy}" | grep -x "pk_functor_yAx" -A 1 | tail -n 1 | cut -d' ' -f7)

        echo "team_policy,team_policy,${kernel_team_policy}" >> "${kernels_output_file}"
        echo "team_policy,${total_team_policy}" >> "${total_output_file}"

        pushd ${PWD}/kokkos/python_versions/nstream
        command="python nstream.py 100 13"

        echo "Running command ${command}"

        std_output=$(eval "${command}")
        dat_file=$(echo "${std_output}" | tail -n 1 | cut -d' ' -f6)
        profiler_output_nstream=$(eval "${KP_READER} ${dat_file}")

        total_nstream=$(measure_time "$command")
        rm *.dat
        popd

        kernel_nstream=$(echo "${profiler_output_nstream}" | grep -x "18pk_functor_nstream" -A 1 | tail -n 1 | cut -d' ' -f7)

        echo "nstream,nstream,${kernel_nstream}" >> "${kernels_output_file}"
        echo "nstream,${total_nstream}" >> "${total_output_file}"
    done
}

function get_LOCs_and_headers() {
    compiler_name=$(basename ${COMPILER})
    output_file="results/stats.${compiler_name}.csv"

    echo "Source,Benchmark,Normal LOCs,Normal Headers,Yalla LOCs,Yalla Headers" > "${output_file}"

    for kernel in "${KERNELS[@]}"; do
        dir=$(find ${PWD}/kokkos/python_versions -name ${kernel})
        dir=$(find ${dir} -name functor.hpp)
        dir=$(dirname ${dir})
        if [ -d "$dir" ]; then
            pushd $dir
            yalla_LOCs_command="${COMPILER} -fopenmp -Wno-everything -E -c kernel.yalla.cpp -std=c++${CXX_STANDARD}"
            # yalla_LOCs_command="clang++ -fopenmp -Wno-everything -c kernel.yalla.cpp -std=c++${CXX_STANDARD}"
            default_LOCs_command="${COMPILER} -fopenmp -Wno-everything -E -c kernel.cpp -std=c++${CXX_STANDARD} -isystem ${KOKKOS_INCLUDE_PATH}"
            # default_LOCs_command="clang++ -fopenmp -Wno-everything -c kernel.cpp -std=c++${CXX_STANDARD} -isystem ${KOKKOS_INCLUDE_PATH}"

            yalla_headers_command="${COMPILER}+ -fopenmp -Wno-everything -H -c kernel.yalla.cpp -std=c++${CXX_STANDARD}"
            # yalla_headers_command="clang++ -fopenmp -Wno-everything -c kernel.yalla.cpp -std=c++${CXX_STANDARD}"
            default_headers_command="${COMPILER} -fopenmp -Wno-everything -H -c kernel.cpp -std=c++${CXX_STANDARD} -isystem ${KOKKOS_INCLUDE_PATH}"
            # default_headers_command="clang++ -fopenmp -Wno-everything -c kernel.cpp -std=c++${CXX_STANDARD} -isystem ${KOKKOS_INCLUDE_PATH}"

            yalla_LOCs=$($yalla_LOCs_command | wc -l)
            # eval $yalla_LOCs_command
            default_LOCs=$($default_LOCs_command | wc -l)
            # eval $default_LOCs_command
            yalla_headers=$($yalla_headers_command 2>&1 >/dev/null | wc -l)
            # eval $yalla_headers_command
            default_headers=$($default_headers_command 2>&1 >/dev/null | wc -l)
            # eval $default_headers_command
            popd

            echo "PyKokkos,${kernel},${default_LOCs},${default_headers},${yalla_LOCs},${yalla_headers}" >> "${output_file}"
        fi
    done

    rapidjson_include=$PROJECTS_DIR/rapidjson/include
    opencv_include=$PROJECTS_DIR/opencv/install/include/opencv4
    opencv_lib=$PROJECTS_DIR/opencv/install/lib/
    boost_include=$PROJECTS_DIR/boost/

    pushd rapidjson/archiver

    benchmark="archiver"
    yalla_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.yalla.cpp"
    default_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.cpp -I${rapidjson_include}"

    yalla_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.yalla.cpp"
    default_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.cpp -I${rapidjson_include}"

    yalla_LOCs=$($yalla_LOCs_command | wc -l)
    default_LOCs=$($default_LOCs_command | wc -l)
    yalla_headers=$($yalla_headers_command 2>&1 >/dev/null | wc -l)
    default_headers=$($default_headers_command 2>&1 >/dev/null | wc -l)

    popd

    echo "rapidjson,${benchmark},${default_LOCs},${default_headers},${yalla_LOCs},${yalla_headers}" >> "${output_file}"

    pushd rapidjson/capitalize
    benchmark="capitalize"
    yalla_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.yalla.cpp"
    default_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.cpp -I${rapidjson_include}"

    yalla_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.yalla.cpp"
    default_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.cpp -I${rapidjson_include}"

    yalla_LOCs=$($yalla_LOCs_command | wc -l)
    default_LOCs=$($default_LOCs_command | wc -l)
    yalla_headers=$($yalla_headers_command 2>&1 >/dev/null | wc -l)
    default_headers=$($default_headers_command 2>&1 >/dev/null | wc -l)

    popd

    echo "rapidjson,${benchmark},${default_LOCs},${default_headers},${yalla_LOCs},${yalla_headers}" >> "${output_file}"

    pushd rapidjson/condense
    benchmark="condense"
    yalla_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.yalla.cpp"
    default_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.cpp -I${rapidjson_include}"

    yalla_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.yalla.cpp"
    default_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.cpp -I${rapidjson_include}"

    yalla_LOCs=$($yalla_LOCs_command | wc -l)
    default_LOCs=$($default_LOCs_command | wc -l)
    yalla_headers=$($yalla_headers_command 2>&1 >/dev/null | wc -l)
    default_headers=$($default_headers_command 2>&1 >/dev/null | wc -l)

    popd

    echo "rapidjson,${benchmark},${default_LOCs},${default_headers},${yalla_LOCs},${yalla_headers}" >> "${output_file}"

    pushd opencv/3calibration

    benchmark="3calibration"
    yalla_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.yalla.cpp"
    default_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.cpp -I${opencv_include}"

    yalla_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.yalla.cpp"
    default_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.cpp -I${opencv_include}"

    yalla_LOCs=$($yalla_LOCs_command | wc -l)
    default_LOCs=$($default_LOCs_command | wc -l)
    yalla_headers=$($yalla_headers_command 2>&1 >/dev/null | wc -l)
    default_headers=$($default_headers_command 2>&1 >/dev/null | wc -l)

    popd

    echo "opencv,${benchmark},${default_LOCs},${default_headers},${yalla_LOCs},${yalla_headers}" >> "${output_file}"
    
    pushd opencv/drawing

    benchmark="drawing"
    yalla_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.yalla.cpp"
    default_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.cpp -I${opencv_include}"

    yalla_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.yalla.cpp"
    default_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.cpp -I${opencv_include}"

    yalla_LOCs=$($yalla_LOCs_command | wc -l)
    default_LOCs=$($default_LOCs_command | wc -l)
    yalla_headers=$($yalla_headers_command 2>&1 >/dev/null | wc -l)
    default_headers=$($default_headers_command 2>&1 >/dev/null | wc -l)

    popd

    echo "opencv,${benchmark},${default_LOCs},${default_headers},${yalla_LOCs},${yalla_headers}" >> "${output_file}"

    pushd opencv/laplace

    benchmark="laplace"
    yalla_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.yalla.cpp"
    default_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.cpp -I${opencv_include}/"

    yalla_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.yalla.cpp"
    default_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.cpp -I${opencv_include}/"

    yalla_LOCs=$($yalla_LOCs_command | wc -l)
    default_LOCs=$($default_LOCs_command | wc -l)
    yalla_headers=$($yalla_headers_command 2>&1 >/dev/null | wc -l)
    default_headers=$($default_headers_command 2>&1 >/dev/null | wc -l)
    popd

    echo "opencv,${benchmark},${default_LOCs},${default_headers},${yalla_LOCs},${yalla_headers}" >> "${output_file}"

    pushd boost/chat_server

    benchmark="chat_server"
    yalla_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.yalla.cpp"
    default_LOCs_command="${COMPILER} -Wno-everything -E -c ${benchmark}.cpp -I${boost_include}"

    yalla_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.yalla.cpp"
    default_headers_command="${COMPILER} -Wno-everything -H -c ${benchmark}.cpp -I${boost_include}"

    yalla_LOCs=$($yalla_LOCs_command | wc -l)
    default_LOCs=$($default_LOCs_command | wc -l)
    yalla_headers=$($yalla_headers_command 2>&1 >/dev/null | wc -l)
    default_headers=$($default_headers_command 2>&1 >/dev/null | wc -l)
    popd

    echo "boost,${benchmark},${default_LOCs},${default_headers},${yalla_LOCs},${yalla_headers}" >> "${output_file}"
}

function generate_drawing_trace() {
    echo "Generating trace for drawing"
    pushd opencv/drawing
    # normal
    ${COMPILER} -c ${flags} -I../../oss/opencv/install/include/opencv4/ drawing.cpp -ftime-trace
    mv drawing.json ${_DIR}/results/traces/drawing-normal.json
    # pch
    ${COMPILER} -c ${flags} -I../../oss/opencv/install/include/opencv4/ -include-pch ../../oss/opencv/install/include/opencv4/drawing-all.h.gch drawing.cpp -ftime-trace
    mv drawing.json ${_DIR}/results/traces/drawing-pch.json
    # yalla
    ${COMPILER} -c ${flags} drawing.yalla.cpp -ftime-trace
    mv drawing.yalla.json ${_DIR}/results/traces/drawing-yalla.json
    popd
}

function get_tool_time() {
    echo "Getting tool time"

    compiler_name=$(basename ${COMPILER})
    tool_output_file="results/tool_time.${compiler_name}.csv"
    echo "Mode, Tool time [s], Compilation time[s], Wrappers time[s]" > "${tool_output_file}"
    echo "Default,0,${normal_comp_time_02},0" >> "${tool_output_file}"
    echo "Yalla,${yalla_tool_time_02},${yalla_comp_time_02},${yalla_wrapper_time_02}" >> "${tool_output_file}"
}

function setup_all() {
    setup_compiler
    setup_yalla
    setup_pykokkos
    get_repos
}

function run_all() {
    mkdir results
    mkdir results/traces

    # kokkos related
    KOKKOS_PATH=`python -c "import importlib; print(importlib.import_module('kokkos').__file__)"`
    KOKKOS_PATH="${KOKKOS_PATH/"/kokkos/__init__.py"/}" # remove "/kokkos/__init__.py" from the end of the string

    echo "Got Kokkos Path ${KOKKOS_PATH}"

    KOKKOS_LIB_PATH="${KOKKOS_PATH}/lib"
    if [ ! -d "${KOKKOS_LIB_PATH}" ]; then
        KOKKOS_LIB_PATH="${KOKKOS_PATH}/lib64"
    fi

    KOKKOS_INCLUDE_PATH="${KOKKOS_PATH}/include/kokkos"
    CXX_STANDARD=$(g++ -dM -E -DKOKKOS_MACROS_HPP ${KOKKOS_INCLUDE_PATH}/KokkosCore_config.h | grep KOKKOS_ENABLE_CXX | tr -d ' ' | sed -e 's/.*\(..\)$/\1/')

    # Do pykokkos first
    setup_pykokkos_cpp_for_yalla
    run_yalla_pyk
    generate_all_so_files
    get_tool_time
    run_benchmarks

    # Do the rest
    run_yalla
    preprocess_all
    compile_yalla
    generate_drawing_trace
    get_LOCs_and_headers
}

check_deps || \
    { echo "Missing dependencies"; exit 1; }

"$@"
