template<typename OutputHandler>
struct CapitalizeFilter {
    CapitalizeFilter(OutputHandler& out) : out_(out), buffer_() {}

    bool Null() { return out_.Null(); }
    bool Bool(bool b) { return out_.Bool(b); }
    bool Int(int i) { return out_.Int(i); }
    bool Uint(unsigned u) { return out_.Uint(u); }
    bool Int64(int64_t i) { return out_.Int64(i); }
    bool Uint64(uint64_t u) { return out_.Uint64(u); }
    bool Double(double d) { return out_.Double(d); }
    bool RawNumber(const char* str, SizeType length, bool copy) { return out_.RawNumber(str, length, copy); }
    bool String(const char* str, SizeType length, bool) {
        buffer_.clear();
        for (SizeType i = 0; i < length; i++)
            buffer_.push_back(static_cast<char>(std::toupper(str[i])));
        return out_.String(&buffer_.front(), length, true); // true = output handler need to copy the string
    }
    bool StartObject() { return out_.StartObject(); }
    bool Key(const char* str, SizeType length, bool copy) { return String(str, length, copy); }
    bool EndObject(SizeType memberCount) { return out_.EndObject(memberCount); }
    bool StartArray() { return out_.StartArray(); }
    bool EndArray(SizeType elementCount) { return out_.EndArray(elementCount); }

    OutputHandler& out_;
    std::vector<char> buffer_;

private:
    CapitalizeFilter(const CapitalizeFilter&);
    CapitalizeFilter& operator=(const CapitalizeFilter&);
};