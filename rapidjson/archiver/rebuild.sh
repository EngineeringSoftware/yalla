INC_DIR=../../../projects/rapidjson/include
COMPILER=g++

${COMPILER} -c archiver.yalla.cpp
${COMPILER} -c wrappers.yalla.cpp -I${INC_DIR}
${COMPILER} -c archivertest.cpp
${COMPILER} *.o -o a.out