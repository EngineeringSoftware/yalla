INC_DIR=../../../projects/opencv/install/include/opencv4
LIB_DIR=~/repos/yalla/eval/projects/opencv/build/lib
COMPILER=g++

$COMPILER -c 3calibration.yalla.cpp
$COMPILER -c wrappers.yalla.cpp -I${INC_DIR}
$COMPILER -c 3calibration.supplementary.yalla.cpp -I. -I${INC_DIR}
./link.sh
patchelf --set-rpath ${LIB_DIR} a.out