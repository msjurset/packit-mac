# Project Rules

- Do not add any Claude or Anthropic authorship references (Co-Authored-By, comments, documentation, commit messages, or otherwise) anywhere in this project.

# Build & Test

- Build: `swift build` or `make build` (release)
- Test: `swift test` or `make test`
- Deploy: `make deploy` (builds, bundles, installs to /Applications)
- Generate Xcode project: `swift package generate-xcodeproj`

# Architecture

PackIt is a SwiftUI macOS app for managing packing list templates and trip instances. Data is persisted as JSON files in `~/.packit/` via a `Persistence` actor. The Store reads/writes through Persistence the same way other apps in this family use CLI actors.

- Uses Swift 6.0 Testing framework (`@Test`, `#expect`), not XCTest
- macOS 15.0+ only, no external dependencies
- `@Observable` + `@MainActor` for state management
- File-based JSON persistence in `~/.packit/` (templates/, trips/, tags.json, config.json)

# Data Flow

Templates (reusable packing lists) → instantiated into TripInstances (actual trips with checklists).
Context tags on templates and items enable composing new trips from multiple tagged sources.
Ad-hoc items added during a trip can be promoted/merged back into templates.

# Maintenance Rules

When source code changes, the following files must be kept in sync:

## View/Feature Changes
When views or features are added or modified:
- Update the README.md features list
- Update the help content in `Views/Help/HelpContent.swift` (add/update relevant topic)
- Add contextual help buttons to new views where appropriate
- Update keyboard shortcuts topic if new shortcuts are added

## Model Changes
When data models are modified:
- Ensure JSON encoding/decoding round-trips correctly
- Update `PackItStore` if the model change affects state management
- Update detail views if display fields change
- Add or update tests in `Tests/PackItTests/`

## Persistence Changes
When file storage format or paths change:
- Update methods in `Services/Persistence.swift`
- Update the README.md Architecture section

## Dependency Changes
When dependencies are added, removed, or updated:
- Update the NOTICES file with the dependency's license information
- For removed dependencies, remove their entry from NOTICES

## Build/Release Changes
When build targets, supported platforms, or release artifacts change:
- Update the Makefile accordingly
- Update the README.md install/build sections if instructions changed

## Function/API Changes
When exported or public functions/computed properties are added or modified:
- Add or update corresponding unit tests to cover the new/changed behavior
- Test edge cases, error paths, and boundary conditions
