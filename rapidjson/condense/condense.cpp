// JSON condenser example

// This example parses JSON text from stdin with validation, 
// and re-output the JSON content to stdout without whitespace.

#include "rapidjson/reader.h"
#include "rapidjson/writer.h"
#include "rapidjson/filereadstream.h"
#include "rapidjson/filewritestream.h"
#include "rapidjson/error/en.h"

using namespace rapidjson;

int main(int, char*[]) {
    // Prepare JSON reader and input stream.
    Reader reader;
    char readBuffer[65536];
    FILE* in = fopen("../rapidjson_random_json.json", "r");
    FileReadStream is(in, readBuffer, sizeof(readBuffer));

    // Prepare JSON writer and output stream.
    char writeBuffer[65536];
    FileWriteStream os(stdout, writeBuffer, sizeof(writeBuffer));
    Writer<FileWriteStream> writer(os);

    auto temp = reader.Parse(is, writer);
    auto pe_code = reader.GetParseErrorCode();

    // JSON reader parse from the input stream and let writer generate the output.
    if (temp) {
        fprintf(stderr, "\nError(%u): %s\n", static_cast<unsigned>(reader.GetErrorOffset()), GetParseError_En(pe_code));
        return 1;
    }

    return 0;
}
