#include "archiver.h"
#include <cassert>
#include <stack>
#include "rapidjson/document.h"
#include "rapidjson/prettywriter.h"
#include "rapidjson/stringbuffer.h"

using namespace rapidjson;

struct JsonReaderStackItem {
    enum State {
        BeforeStart,    //!< An object/array is in the stack but it is not yet called by StartObject()/StartArray().
        Started,        //!< An object/array is called by StartObject()/StartArray().
        Closed          //!< An array is closed after read all element, but before EndArray().
    };

    JsonReaderStackItem(const Value* value, State state) : value(value), state(state), index() {}

    const Value* value;
    State state;
    SizeType index;   // For array iteration
};

typedef std::stack<JsonReaderStackItem> JsonReaderStack;

#define DOCUMENT reinterpret_cast<Document*>(mDocument)
#define STACK (reinterpret_cast<JsonReaderStack*>(mStack))
#define TOP (STACK->top())
#define CURRENT (*TOP.value)

JsonReader::JsonReader(const char* json) : mDocument(), mStack(), mError(false) {
    mDocument = new Document;
    Document* temp = DOCUMENT;

    if (temp->HasParseError())
        mError = true;
    else {
        mStack = new JsonReaderStack;
        // STACK->push(JsonReaderStackItem(DOCUMENT, JsonReaderStackItem::BeforeStart));
        STACK->push(JsonReaderStackItem(reinterpret_cast<Value*>(DOCUMENT), JsonReaderStackItem::BeforeStart));
    }
}

JsonReader::~JsonReader() {
    delete DOCUMENT;
    delete STACK;
}

// Archive concept
JsonReader& JsonReader::StartObject() {
    if (!mError) {
        JsonReaderStack* temp = STACK;
        JsonReaderStackItem& temp2 = (*temp).top();
        const rapidjson::Value* temp3 = temp2.value;

        if (temp3->IsObject() && temp2.state == JsonReaderStackItem::BeforeStart)
            TOP.state = JsonReaderStackItem::Started;
        else
            mError = true;
    }
    return *this;
}

JsonReader& JsonReader::EndObject() {
    if (!mError) {
        JsonReaderStack* temp = STACK;
        JsonReaderStackItem& temp2 = (*temp).top();
        const rapidjson::Value* temp3 = temp2.value;

        if (temp3->IsObject() && temp2.state == JsonReaderStackItem::Started)
            Next();
        else
            mError = true;
    }
    return *this;
}

JsonReader& JsonReader::Member(const char* name) {
    // if (!mError) {
    //     JsonReaderStack* temp = STACK;
    //     JsonReaderStackItem& temp2 = (*temp).top();
    //     const rapidjson::Value* temp3 = temp2.value;

    //     if (temp3->IsObject() && temp2.state == JsonReaderStackItem::Started) {
    //         Value::ConstMemberIterator memberItr = temp3->FindMember(name);
    //         auto temp4 = temp3->MemberEnd();

    //         if (memberItr != temp4)
    //             STACK->push(JsonReaderStackItem(&memberItr->value, JsonReaderStackItem::BeforeStart));
    //         else
    //             mError = true;
    //     }
    //     else
    //         mError = true;
    // }
    return *this;
}

bool JsonReader::HasMember(const char* name) const {
    JsonReaderStack* temp = STACK;
    JsonReaderStackItem& temp2 = (*temp).top();
    const rapidjson::Value* temp3 = temp2.value;

    if (!mError && temp3->IsObject() && temp2.state == JsonReaderStackItem::Started)
        return temp3->HasMember(name);
    return false;
}

JsonReader& JsonReader::StartArray(size_t* size) {
    if (!mError) {
        JsonReaderStack* temp = STACK;
        JsonReaderStackItem& temp2 = (*temp).top();
        const rapidjson::Value* temp3 = temp2.value;

        if (temp3->IsArray() && temp2.state == JsonReaderStackItem::BeforeStart) {
            TOP.state = JsonReaderStackItem::Started;
            if (size)
                *size = temp3->Size();

            if (!temp3->Empty()) {
                // TODO: some weird stuff happening here
                // const Value* value = &CURRENT[TOP.index];
                // STACK->push(JsonReaderStackItem(value, JsonReaderStackItem::BeforeStart));
            }
            else
                TOP.state = JsonReaderStackItem::Closed;
        }
        else
            mError = true;
    }
    return *this;
}

JsonReader& JsonReader::EndArray() {
    if (!mError) {
        JsonReaderStack* temp = STACK;
        JsonReaderStackItem& temp2 = (*temp).top();
        const rapidjson::Value* temp3 = temp2.value;

        if (temp3->IsArray() && temp2.state == JsonReaderStackItem::Closed)
            Next();
        else
            mError = true;
    }
    return *this;
}

JsonReader& JsonReader::operator&(bool& b) {
    if (!mError) {
        JsonReaderStack* temp = STACK;
        JsonReaderStackItem& temp2 = (*temp).top();
        const rapidjson::Value* temp3 = temp2.value;

        if (temp3->IsBool()) {
            b = temp3->GetBool();
            Next();
        }
        else
            mError = true;
    }
    return *this;
}

JsonReader& JsonReader::operator&(unsigned& u) {
    if (!mError) {
        JsonReaderStack* temp = STACK;
        JsonReaderStackItem& temp2 = (*temp).top();
        const rapidjson::Value* temp3 = temp2.value;

        if (temp3->IsUint()) {
            u = temp3->GetUint();
            Next();
        }
        else
            mError = true;
    }
    return *this;
}

JsonReader& JsonReader::operator&(int& i) {
    if (!mError) {
        JsonReaderStack* temp = STACK;
        JsonReaderStackItem& temp2 = (*temp).top();
        const rapidjson::Value* temp3 = temp2.value;

        if (temp3->IsInt()) {
            i = temp3->GetInt();
            Next();
        }
        else
            mError = true;
    }
    return *this;
}

JsonReader& JsonReader::operator&(double& d) {
    if (!mError) {
        JsonReaderStack* temp = STACK;
        JsonReaderStackItem& temp2 = (*temp).top();
        const rapidjson::Value* temp3 = temp2.value;

        if (temp3->IsNumber()) {
            d = temp3->GetDouble();
            Next();
        }
        else
            mError = true;
    }
    return *this;
}

JsonReader& JsonReader::operator&(std::string& s) {
    if (!mError) {
        JsonReaderStack* temp = STACK;
        JsonReaderStackItem& temp2 = (*temp).top();
        const rapidjson::Value* temp3 = temp2.value;

        if (temp3->IsString()) {
            s = temp3->GetString();
            Next();
        }
        else
            mError = true;
    }
    return *this;
}

JsonReader& JsonReader::SetNull() {
    // This function is for JsonWriter only.
    mError = true;
    return *this;
}

void JsonReader::Next() {
    if (!mError) {
        JsonReaderStack* temp = STACK;
        JsonReaderStackItem& temp2 = (*temp).top();
        const rapidjson::Value* temp3 = temp2.value;

        assert(!STACK->empty());
        STACK->pop();

        if (!STACK->empty() && temp3->IsArray()) {
            if (temp2.state == JsonReaderStackItem::Started) { // Otherwise means reading array item pass end
                if (temp2.index < temp3->Size() - 1) {
                    // const Value* value = &CURRENT[++TOP.index];
                    // STACK->push(JsonReaderStackItem(value, JsonReaderStackItem::BeforeStart));
                }
                else
                    TOP.state = JsonReaderStackItem::Closed;
            }
            else
                mError = true;
        }
    }
}

#undef DOCUMENT
#undef STACK
#undef TOP
#undef CURRENT

////////////////////////////////////////////////////////////////////////////////
// JsonWriter

#define WRITER reinterpret_cast<PrettyWriter<StringBuffer>*>(mWriter)
#define STREAM reinterpret_cast<StringBuffer*>(mStream)

JsonWriter::JsonWriter() : mWriter(), mStream() {
    mStream = new StringBuffer;
    // TODO:
    mWriter = new PrettyWriter<StringBuffer>(*STREAM);
}

JsonWriter::~JsonWriter() { 
    delete WRITER;
    delete STREAM;
}

const char* JsonWriter::GetString() const {
    StringBuffer* temp = STREAM;
    return temp->GetString();
}

JsonWriter& JsonWriter::StartObject() {
    PrettyWriter<StringBuffer>* temp = WRITER;
    temp->StartObject();
    return *this;
}

JsonWriter& JsonWriter::EndObject() {
    PrettyWriter<StringBuffer>* temp = WRITER;
    temp->EndObject();
    return *this;
}

JsonWriter& JsonWriter::Member(const char* name) {
    PrettyWriter<StringBuffer>* temp = WRITER;
    temp->String(name, static_cast<unsigned int>(strlen(name)));
    return *this;
}

bool JsonWriter::HasMember(const char*) const {
    // This function is for JsonReader only.
    assert(false);
    return false;
}

JsonWriter& JsonWriter::StartArray(size_t*) {
    PrettyWriter<StringBuffer>* temp = WRITER;
    temp->StartArray();   
    return *this;
}

JsonWriter& JsonWriter::EndArray() {
    PrettyWriter<StringBuffer>* temp = WRITER;
    temp->EndArray();
    return *this;
}

JsonWriter& JsonWriter::operator&(bool& b) {
    PrettyWriter<StringBuffer>* temp = WRITER;
    temp->Bool(b);
    return *this;
}

JsonWriter& JsonWriter::operator&(unsigned& u) {
    PrettyWriter<StringBuffer>* temp = WRITER;
    temp->Uint(u);
    return *this;
}

JsonWriter& JsonWriter::operator&(int& i) {
    PrettyWriter<StringBuffer>* temp = WRITER;
    temp->Int(i);
    return *this;
}

JsonWriter& JsonWriter::operator&(double& d) {
    PrettyWriter<StringBuffer>* temp = WRITER;
    temp->Double(d);
    return *this;
}

JsonWriter& JsonWriter::operator&(std::string& s) {
    PrettyWriter<StringBuffer>* temp = WRITER;
    temp->String(s.c_str(), static_cast<unsigned int>(s.size()));
    return *this;
}

JsonWriter& JsonWriter::SetNull() {
    PrettyWriter<StringBuffer>* temp = WRITER;
    temp->Null();
    return *this;
}

#undef STREAM
#undef WRITER
