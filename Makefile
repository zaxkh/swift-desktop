DERIVED_DATA ?= /private/tmp/MattermostDerivedData

.PHONY: generate build clean

generate:
	xcodegen generate

build:
	xcodebuild -project Mattermost.xcodeproj -scheme Mattermost -configuration Debug -derivedDataPath $(DERIVED_DATA) build

clean:
	rm -rf $(DERIVED_DATA)
