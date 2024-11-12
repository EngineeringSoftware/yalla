INC_DIR=../../../projects/boost/
COMPILER=clang++

# ${COMPILER} -c chat_server.yalla.cpp
# ${COMPILER} -c wrappers.yalla.cpp -I${INC_DIR}
# ${COMPILER} *.o -lpthread -o a.out
${COMPILER} chat_server.normal.cpp -I${INC_DIR} -lpthread -o a.out