# PackIt

A macOS app for managing reusable packing list templates and trip-specific checklists.

## Features

### Templates
- Create reusable packing list templates organized by category
- Add items with name, category, priority, quantity, notes, and context tags
- Auto-suggest item names from existing templates and trips with auto-fill of fields
- Comma-separated tag input with auto-suggest and Tab-cycling
- Double-click items to edit; drag and drop to reorder
- Duplicate, export, and share templates

### Trips
- Create trips from one or more templates with optional tag-based filtering
- Packing checklist with visual progress ring and color-coded priorities
- Batch pack/unpack by category
- Add ad-hoc items during a trip (marked with "new" badge)
- Merge ad-hoc items back into templates after the trip
- TODOs, notes, and inspector sidebar
- Trip statuses: Planning, Active, Completed, Archived

### Context Tags
- Tag templates and individual items for flexible filtering
- Tags cascade across all views; renaming updates everywhere
- Deleting a tag removes it from all templates and items
- Manage tags globally from the Tags sidebar section

### Statistics
- Dashboard with trip counts, items packed, completion rate
- Most packed items, top categories, frequently added ad-hoc items
- Trip timeline with history

### Other
- Print packing lists with customizable watermarks, borders, and patterns
- Export trips and templates as PackIt files, HTML, or CSV
- Departure and item due date reminders via macOS notifications
- Quick search across templates and trips
- Full keyboard shortcut support
- Contextual help system

## Requirements

- macOS 15.0+
- Swift 6.0+
- No external dependencies

## Build & Run

```sh
# Debug build
swift build

# Release build
make build

# Run tests
make test

# Run UI tests (requires xcodegen)
make uitest

# Deploy to /Applications
make deploy

# Seed sample templates
make seed
```

## Architecture

- **SwiftUI** with `@Observable` + `@MainActor` state management
- **File-based JSON persistence** in `~/.packit/` (templates/, trips/, tags.json, config.json)
- **`PackItStore`** — central state manager with undo/redo support
- **`Persistence`** actor — async file I/O
- **Three-column layout** — Sidebar / List / Detail via `NavigationSplitView`

### Data Flow

Templates (reusable packing lists) are instantiated into TripInstances (actual trips with checklists). Context tags on templates and items enable composing new trips from multiple tagged sources. Ad-hoc items added during a trip can be promoted/merged back into templates.

## Testing

- **Unit tests** — Swift Testing framework (`@Test`, `#expect`) covering models, persistence, and store logic
- **UI tests** — XCTest/XCUIApplication E2E tests covering navigation, selection, and empty states
- Run `make test` for unit tests, `make uitest` for UI tests
