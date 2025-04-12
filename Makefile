TARGET = extractor
SOURCE = beaconstorekey-extractor.swift
ENTITLEMENTS = entitlements.plist
DEVELOPER_ID = "Apple Development"

sign: $(TARGET) $(ENTITLEMENTS)
	codesign -f -s $(DEVELOPER_ID) --entitlements $(ENTITLEMENTS) $(TARGET)

$(TARGET): $(SOURCE)
	swiftc -o $@ $^

clean:
	rm $(TARGET)

run: sign
	./$(TARGET)

decrypt:
	swift searchpartyd-decryptor.swift 

.PHONY: sign clean
