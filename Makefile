APP_NAME := PackIt
BUNDLE := $(APP_NAME).app
INSTALL_DIR := /Applications

build:
	swift build -c release

bundle: build icon
	@mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources $(BUNDLE)/Contents/Frameworks
	command cp .build/release/PackIt $(BUNDLE)/Contents/MacOS/$(APP_NAME)
	install_name_tool -add_rpath @loader_path/../Frameworks $(BUNDLE)/Contents/MacOS/$(APP_NAME) 2>/dev/null || true
	command cp AppIcon.icns $(BUNDLE)/Contents/Resources/AppIcon.icns
	command cp Info.plist $(BUNDLE)/Contents/Info.plist
	cp -R .build/arm64-apple-macosx/release/Sparkle.framework $(BUNDLE)/Contents/Frameworks/

icon:
	@test -f AppIcon.icns || swift scripts/generate-icon.swift

deploy: bundle
	pkill -9 -f "$(APP_NAME)" 2>/dev/null || true
	@sleep 1
	command rm -rf $(INSTALL_DIR)/$(BUNDLE)
	ditto $(BUNDLE) $(INSTALL_DIR)/$(BUNDLE)
	@osascript -e 'use framework "AppKit"' \
		-e 'set iconImage to current application'\''s NSImage'\''s alloc()'\''s initWithContentsOfFile:"$(INSTALL_DIR)/$(BUNDLE)/Contents/Resources/AppIcon.icns"' \
		-e 'current application'\''s NSWorkspace'\''s sharedWorkspace()'\''s setIcon:iconImage forFile:"$(INSTALL_DIR)/$(BUNDLE)" options:0'
	@killall Dock 2>/dev/null || true
	@echo "Deployed to $(INSTALL_DIR)/$(BUNDLE)"
	open $(INSTALL_DIR)/$(BUNDLE)

clean:
	rm -rf .build $(BUNDLE)

test:
	swift test

uitest:
	xcodegen generate
	xcodebuild test \
		-project PackIt.xcodeproj \
		-scheme PackIt \
		-only-testing PackItUITests \
		-destination 'platform=macOS'

seed:
	swift scripts/seed-templates.swift

dmg: bundle
	@test -f dmg-background.png || swift scripts/generate-dmg-bg.swift
	rm -f PackIt.dmg
	create-dmg \
		--volname "PackIt" \
		--background "dmg-background.png" \
		--window-pos 200 120 \
		--window-size 660 400 \
		--icon-size 80 \
		--icon "$(BUNDLE)" 170 170 \
		--app-drop-link 490 170 \
		--hide-extension "$(BUNDLE)" \
		--no-internet-enable \
		"PackIt.dmg" \
		"$(BUNDLE)"

release:
	@test -n "$(VERSION)" || (echo "Usage: make release VERSION=1.0.0" && exit 1)
	./scripts/release.sh $(VERSION)

.PHONY: build bundle icon deploy clean test uitest seed dmg release
