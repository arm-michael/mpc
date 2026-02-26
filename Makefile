.PHONY: lint build test clean

SCHEME = mpc
PROJECT = mpc/mpc.xcodeproj
DESTINATION = platform=iOS Simulator,name=iPhone 16,OS=18.2
SWIFTLINT_CONFIG = mpc/.swiftlint.yml

lint:
	swiftlint lint --config $(SWIFTLINT_CONFIG)

lint-fix:
	swiftlint --fix --config $(SWIFTLINT_CONFIG)

build:
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		CODE_SIGNING_ALLOWED=NO

test:
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		-resultBundlePath TestResults.xcresult \
		CODE_SIGNING_ALLOWED=NO

clean:
	xcodebuild clean \
		-project $(PROJECT) \
		-scheme $(SCHEME)
	rm -rf TestResults.xcresult
