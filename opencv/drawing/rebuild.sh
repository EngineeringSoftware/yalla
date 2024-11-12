INC_DIR=../../../projects/opencv/install/include/opencv4
LIB_DIR=../../../projects/opencv/install/lib/
COMPILER=g++

${COMPILER} -c drawing.yalla.cpp
${COMPILER}  -c wrappers.yalla.cpp -I${INC_DIR}
./link_drawing.sh
patchelf --set-rpath ${LIB_DIR} a.out