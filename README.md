# PackIt

A macOS app for managing reusable packing list templates, trip-specific checklists, meal planning, and trip preparation workflows.

## Features

### Templates
- Create reusable packing list templates organized by category
- Add items with name, category, owner, priority, quantity, notes, and context tags
- Auto-suggest item names from existing templates and trips with auto-fill
- Comma-separated tag input with auto-suggest and Tab-cycling
- Double-click items to edit; drag and drop to reorder
- Composite templates that link other templates for one-click trip creation
- Prep task templates with 6-tier timing (Early, 2 Weeks, 1 Week, Day Before, Day Of, On Return)
- Procedure templates with ordered step-by-step workflows and phases
- Reference links on templates that carry through to trips
- Duplicate, export, and share templates

### Trips
- Create trips from one or more templates with optional tag-based filtering
- Packing checklist with visual progress ring and color-coded priorities
- Batch pack/unpack by category
- Add ad-hoc items during a trip (marked with "new" badge)
- Merge ad-hoc items back into templates after the trip
- Import additional templates into existing trips with dedup
- Trip icons (48 themed options: beach, mountain, city, camping, surfing, sailing, biking, RV, …) with searchable picker and keyboard navigation (arrows / hjkl / Enter)
- Destination with geocoding search
- Trip statuses: Planning, Active, Completed, Archived
- Fullscreen detail mode
- Drag-to-reorder trips within each section
- Auto-select last viewed trip per section when navigating
- Duplicate a trip (deep copy with reset packed/complete state, status reset to Planning)
- Travel mode (Plane, Car, Train, Bus, RV, Boat, Bicycle, Walking) — drives the prep timeline "Day Of" / "On Return" icons and the trip header departure/return rows

### Members & Item Ownership
- Define members per trip (e.g. you + Kim) with chip-style add/remove
- Assign trip items to one or more members; items with no owner are shared
- Member filter checkboxes at the top of the packing list — show only the members you care about (shared items always visible)
- Owner suffix on item rows when filter shows multiple members
- Edit-item sheet supports multi-owner selection — saving creates per-owner duplicates automatically
- Right-click any item: Owner submenu (reassign in place), Duplicate For submenu (clone for another owner), or apply to a multi-selection

### List interactions
- Multi-select packing items with Cmd-click (toggle) and Shift-click (range)
- Floating bulk action bar: Owner, Duplicate For, Remove
- Right-click on a row in a multi-selection applies the action to the entire selection
- Plain click anywhere clears the selection
- Double-click a row to open the Edit sheet
- Press `/` or `⌘F` to find in list — text search with N / spacebar / arrow buttons to advance, Esc to close
- Tokenized search filters: `category:`, `owner:`, `name:`, `priority:`, `packed:`, `notes:` with Tab-cycle autocomplete
- Drag items into another category to recategorize; double-click a category header to rename
- Drag-drop indicators with row-parting animation

### Categories
- First-class categories with custom icon (curated SF Symbol library) and color
- Manage from Settings → Categories: rename, recolor, choose new icon, see usage counts
- Sort categories Manually (drag-to-reorder with insertion mark) or by Name (alphabetical)
- Inline icon picker — double-click any category icon in a packing list to change it
- Renaming a category to an existing name merges items under the existing one

### Prep Tasks
- 6-tier timing: Early (-21d), 2 Weeks (-14d), 1 Week (-7d), Day Before (-1d), Day Of, On Return
- Timeline view with flow connectors in the trip detail
- Due dates auto-calculated from departure/return dates
- Ad-hoc prep tasks can be added directly to trips
- Categories with auto-suggest (Home, Supplies, Travel Docs, Pets, Financial, and custom)

### Procedures
- Step-by-step workflow checklists (Before Departure, On Arrival, Before Leaving, On Return)
- Ordered numbered steps with checkboxes, notes, and progress tracking
- Edit mode with drag-to-reorder, add/remove steps, position insertion
- Collapsible procedure cards grouped by phase
- Templates carry procedures through to trips

### Meal Planning
- Day-by-day meal grid (Breakfast, Lunch, Dinner, Snacks, Beverages)
- Auto-generated from trip dates
- Click-to-edit cells with comma-separated food items
- Food prep notes section
- Dedicated "Meals" tab in trip detail

### Weather
- Daily weather forecast for trip destination
- Three providers: Open-Meteo (free), WeatherAPI.com, Visual Crossing
- Historical fallback for trips beyond forecast range
- Compact widget in inspector with day/icon/temp/precip
- Detail popover with wind, humidity, pressure, UV, feels-like, air quality
- Configurable in Settings

### Inspector Sidebar
- TODOs with quick-add and priority
- Activities for trip inspiration (inline add/edit)
- Weather forecast widget
- Notes with markdown support and pop-out editor
- Reference links (clickable, with add/remove)
- Trip info summary
- All sections collapsible

### Context Tags
- Tag templates and individual items for flexible filtering
- Tags cascade across all views; renaming/deleting updates everywhere
- Manage tags globally from the Tags sidebar section

### Sharing
- Selective sharing via configurable shared folder (Google Drive, Dropbox, iCloud)
- Share/unshare individual trips and templates
- Background polling (45s) detects changes from other users
- Conflict detection with notification banners
- Version tracking and last-modified-by stamps
- "Shared by &lt;name&gt;" badge on templates and trips someone else shared with you
- "Shared" badge on templates and trips you're sharing out
- In-app modal plus macOS notification the first time a new shared item shows up

### Print
- Three layout modes: Standard (columns), Compact (category boxes), Dense (maximum density)
- Print settings sheet with live preview before printing
- Customizable watermarks: repeating patterns, full-page art, decorative borders
- Each section prints on its own page (items, prep tasks, procedures, meal plan, activities/links)
- All trip data included in print output

### Export & Import
- PackIt native files (.packitlist, .packittemplate) — full data round-trip
- HTML export with dark mode support, styled tables, clickable links
- CSV export with labeled sections for all data types
- Multi-file import — select all and import in one batch
- Import from Template button in the trip editor

### Statistics
- Dashboard with trip counts, items packed, completion rate
- Most packed items, top categories, frequently added ad-hoc items
- Trip timeline with history

### Other
- Appearance toggle (System/Dark/Light)
- Open on launch (Templates/Last Used)
- Sparkle auto-update with EdDSA signing
- Contextual help system with searchable topics
- Full keyboard shortcut support
- Codesigned and notarized for macOS distribution

## Requirements

- macOS 15.0+
- Swift 6.0+
- Sparkle 2.7+ (auto-update framework)

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

# Create DMG
make dmg

# Full release (build, sign, notarize, publish)
make release VERSION=1.0.0

# Seed RV camping templates
swift scripts/seed-rv-templates.swift
```

## Architecture

- **SwiftUI** with `@Observable` + `@MainActor` state management
- **File-based JSON persistence** in `~/.packit/` (local) and configurable shared folder
- **`PackItStore`** — central state manager with undo/redo, sharing, conflict detection
- **`Persistence`** actor — dual-directory async file I/O (local + shared)
- **Two-column layout** — Sidebar via `NavigationSplitView`, detail with `HStack` sub-panels

### Data Flow

Templates (reusable packing lists) are instantiated into TripInstances (actual trips with checklists). Composite templates link other templates for one-click trip creation. Context tags on templates and items enable filtering during trip creation. Ad-hoc items added during a trip can be promoted/merged back into templates. Selective sharing moves individual resources between local and shared storage.

## Testing

- **Unit tests** — Swift Testing framework (`@Test`, `#expect`) covering models, persistence, and store logic
- **UI tests** — XCTest/XCUIApplication E2E tests covering navigation, selection, and empty states
- Run `make test` for unit tests, `make uitest` for UI tests

## License

MIT License — see [LICENSE](LICENSE) for details.

## Third-Party

See [NOTICES](NOTICES) for third-party licenses and attributions.
