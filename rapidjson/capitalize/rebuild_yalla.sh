INC_DIR=../../../projects/rapidjson/include
COMPILER=${1:-clang++} # g++ or clang++

${COMPILER} -c capitalize.yalla.cpp
${COMPILER} -c wrappers.yalla.cpp -I${INC_DIR}
${COMPILER} *.o -o a.out