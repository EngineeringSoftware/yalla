INC_DIR=../../../projects/opencv/install/include/opencv4
LIB_DIR=~/repos/yalla/eval/projects/opencv/build/lib
COMPILER=g++

${COMPILER} -c laplace.yalla.cpp
${COMPILER} -c wrappers.yalla.cpp -I${INC_DIR}
./link_laplace.sh
patchelf --set-rpath ${LIB_DIR} a.out