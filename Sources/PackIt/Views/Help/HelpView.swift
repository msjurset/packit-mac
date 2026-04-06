import SwiftUI

struct HelpView: View {
    @State private var selectedTopic: HelpTopic? = .gettingStarted
    @State private var searchText = ""

    var filteredTopics: [HelpTopic] {
        guard !searchText.isEmpty else { return HelpTopic.allCases }
        let q = searchText.lowercased()
        return HelpTopic.allCases.filter {
            $0.title.lowercased().contains(q) ||
            $0.searchKeywords.contains(where: { $0.contains(q) }) ||
            $0.sections.contains(where: { $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q) })
        }
    }

    var body: some View {
        NavigationSplitView {
            List(filteredTopics, selection: $selectedTopic) { topic in
                Label(topic.title, systemImage: topic.icon)
                    .tag(topic)
            }
            .listStyle(.sidebar)
            .searchable(text: $searchText, prompt: "Search help...")
            .navigationTitle("PackIt Help")
        } detail: {
            if let topic = selectedTopic {
                HelpDetailView(topic: topic)
            } else {
                ContentUnavailableView("Select a Topic", systemImage: "questionmark.circle", description: Text("Choose a help topic from the sidebar."))
            }
        }
        .frame(minWidth: 700, minHeight: 450)
    }
}

// MARK: - Detail View

struct HelpDetailView: View {
    let topic: HelpTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: topic.icon)
                        .font(.largeTitle)
                        .foregroundStyle(.packitTeal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(topic.title)
                            .font(.title.bold())
                        Text(topic.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Sections
                ForEach(topic.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        if !section.title.isEmpty {
                            Text(section.title)
                                .font(.headline)
                        }
                        Text(.init(section.body))
                            .font(.body)
                            .foregroundStyle(.primary.opacity(0.85))
                            .lineSpacing(4)

                        if !section.tips.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(section.tips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.caption)
                                            .foregroundStyle(.packitAmber)
                                            .frame(width: 14, alignment: .center)
                                            .padding(.top, 3)
                                        Text(.init(tip))
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(12)
                            .background(.secondary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 600, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Contextual Help Button

struct ContextualHelpButton: View {
    let topic: HelpTopic
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button {
            openWindow(id: "help")
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .help(topic.title)
    }
}

// MARK: - Help Topics

struct HelpSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    var tips: [String] = []
}

enum HelpTopic: String, CaseIterable, Identifiable {
    case gettingStarted
    case templates
    case templateItems
    case contextTags
    case creatingTrips
    case packingChecklist
    case todosAndNotes
    case merging
    case printing
    case exporting
    case reminders
    case statistics
    case settings
    case shortcuts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gettingStarted: return "Getting Started"
        case .templates: return "Templates"
        case .templateItems: return "Template Items"
        case .contextTags: return "Context Tags"
        case .creatingTrips: return "Creating a Trip"
        case .packingChecklist: return "Packing Checklist"
        case .todosAndNotes: return "TODOs & Notes"
        case .merging: return "Merging Items"
        case .printing: return "Printing"
        case .exporting: return "Exporting & Sharing"
        case .reminders: return "Reminders"
        case .statistics: return "Statistics"
        case .settings: return "Settings"
        case .shortcuts: return "Keyboard Shortcuts"
        }
    }

    var subtitle: String {
        switch self {
        case .gettingStarted: return "Learn the basics of PackIt"
        case .templates: return "Reusable packing list blueprints"
        case .templateItems: return "Managing items within templates"
        case .contextTags: return "Flexible filtering with tags"
        case .creatingTrips: return "Building a trip from templates"
        case .packingChecklist: return "Checking off items as you pack"
        case .todosAndNotes: return "Track tasks and notes for your trip"
        case .merging: return "Promote new items back to templates"
        case .printing: return "Print your packing list with watermarks"
        case .exporting: return "Share lists in multiple formats"
        case .reminders: return "Automatic departure and item reminders"
        case .statistics: return "Trip history and packing insights"
        case .settings: return "Customize print and watermark options"
        case .shortcuts: return "Quick access with keyboard shortcuts"
        }
    }

    var icon: String {
        switch self {
        case .gettingStarted: return "star.fill"
        case .templates: return "doc.on.doc.fill"
        case .templateItems: return "list.bullet.rectangle.fill"
        case .contextTags: return "tag.fill"
        case .creatingTrips: return "suitcase.rolling.fill"
        case .packingChecklist: return "checklist"
        case .todosAndNotes: return "sidebar.trailing"
        case .merging: return "arrow.up.doc.fill"
        case .printing: return "printer.fill"
        case .exporting: return "square.and.arrow.up.fill"
        case .reminders: return "bell.fill"
        case .statistics: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        case .shortcuts: return "keyboard.fill"
        }
    }

    var searchKeywords: [String] {
        switch self {
        case .gettingStarted: return ["start", "begin", "overview", "intro", "welcome", "how to"]
        case .templates: return ["template", "list", "create", "reusable", "blueprint", "duplicate", "copy", "clone"]
        case .templateItems: return ["item", "category", "priority", "quantity", "add", "edit", "delete", "drag", "drop", "reorder", "move", "sort", "suggest", "auto-fill", "double-click"]
        case .contextTags: return ["tag", "filter", "context", "beach", "winter", "fishing", "comma", "suggest", "auto-suggest", "tab", "cycling"]
        case .creatingTrips: return ["trip", "vacation", "travel", "departure", "create", "new"]
        case .packingChecklist: return ["pack", "check", "checkbox", "progress", "color", "category", "drag", "reorder", "batch", "all", "check all", "uncheck all"]
        case .todosAndNotes: return ["todo", "task", "note", "inspector", "sidebar"]
        case .merging: return ["merge", "promote", "ad-hoc", "new items", "template"]
        case .printing: return ["print", "watermark", "border", "paper", "pdf"]
        case .exporting: return ["export", "share", "html", "csv", "packitlist", "packittemplate", "airdrop", "template"]
        case .reminders: return ["remind", "notification", "alert", "departure", "due date"]
        case .statistics: return ["statistics", "stats", "history", "dashboard", "insights", "frequency", "most packed", "ad-hoc", "timeline"]
        case .settings: return ["setting", "preference", "config", "watermark", "opacity"]
        case .shortcuts: return ["keyboard", "shortcut", "hotkey", "key", "undo", "redo", "tab", "suggest", "auto-suggest", "double-click", "ctrl-j", "ctrl-k"]
        }
    }

    var sections: [HelpSection] {
        switch self {

        case .gettingStarted:
            return [
                HelpSection(title: "", body: """
                PackIt helps you create reusable packing list templates and turn them into trip-specific checklists. Whether you're heading to the beach or the mountains, PackIt keeps you organized.
                """),
                HelpSection(title: "The Workflow", body: """
                **1. Create Templates** — Build reusable packing lists organized by category (Toiletries, Electronics, Clothing, etc.). Tag them with contexts like "beach" or "winter".

                **2. Create a Trip** — Select one or more templates and optionally filter by context tags. PackIt combines and deduplicates the items into your trip's packing list.

                **3. Pack** — Check off items as you pack. Track TODOs, add notes, and monitor your progress with the visual progress ring.

                **4. After the Trip** — Merge any new items you added during the trip back into your templates for next time.
                """),
                HelpSection(title: "The Interface", body: """
                PackIt uses a three-column layout:

                **Left sidebar** — Navigate between Templates, Trips (by status), Tags, and Search. Tips and quotes rotate at the bottom.

                **Middle column** — Lists of templates or trips. Click one to see its details.

                **Right column** — The detail view. For templates, this shows items grouped by category. For trips, this shows the packing checklist with a progress ring.

                When viewing a trip, toggle the **inspector sidebar** (right panel) to see TODOs, notes, and trip info.
                """),
            ]

        case .templates:
            return [
                HelpSection(title: "What Are Templates?", body: """
                Templates are reusable packing list blueprints. Instead of recreating your packing list for every trip, you build templates once and reuse them.
                """, tips: [
                    "Create templates by **theme** (Beach, Camping, Business) or by **category** (Toiletries, Electronics, Clothing)",
                    "You can select **multiple templates** when creating a trip — PackIt merges them and removes duplicates",
                ]),
                HelpSection(title: "Creating a Template", body: """
                Click the **+** button at the top of the template list, or use **⌘N**. Give your template a name and optionally assign context tags.
                """),
                HelpSection(title: "Editing a Template", body: """
                Right-click a template in the list and choose **Edit** to change its name or tags. From the template detail view, use the **pencil** button in the toolbar to edit, or the **+** button to add items.
                """),
                HelpSection(title: "Duplicating a Template", body: """
                Right-click a template and choose **Duplicate**, or click the **Duplicate** button in the template detail toolbar. This creates a full copy — including all items and tags — named "Template Copy". Edit the copy to customize it for a different trip type.
                """, tips: [
                    "Great for creating variants like \"Beach – Domestic\" and \"Beach – International\" from a single base template",
                ]),
                HelpSection(title: "Deleting a Template", body: """
                Right-click a template and choose **Delete**. You'll be asked to confirm since this permanently removes the template and all its items.
                """),
            ]

        case .templateItems:
            return [
                HelpSection(title: "Adding Items", body: """
                From the template detail view, click **Add Item**. Each item has:

                **Name** — What you're packing (e.g., "Sunscreen"). As you type, PackIt suggests matching items from your other templates and trips. Press **Tab** to cycle through suggestions, **Enter** to accept.
                **Category** — Groups items visually (e.g., "Toiletries", "Electronics"). Suggests categories you've used before.
                **Priority** — Low, Medium, High, or Critical. Affects color coding and reminder behavior.
                **Quantity** — How many to pack (default 1). Shown as "×3" next to the item name when greater than 1.
                **Notes** — Optional details (e.g., "SPF 50+", "Check expiry date")
                **Context Tags** — Optional tags for fine-grained filtering when creating trips. Type comma-separated tag names or use the suggestion dropdown.

                When you select a suggested item name, PackIt **auto-fills** the category, priority, tags, notes, and quantity from that item — saving you from re-entering details.
                """, tips: [
                    "**Double-click** any item in the template detail view to edit it",
                    "You can **delete** an item from the edit form using the trash button at the bottom",
                ]),
                HelpSection(title: "Reordering Items", body: """
                Drag and drop items to reorder them within a category. Simply click and drag an item onto another item in the same category, and it will be placed before the target. The new order is saved automatically and preserved when creating trips.
                """, tips: [
                    "Reordering works in both template detail views and trip packing checklists",
                    "Items can only be reordered within the same category — drag between categories is ignored",
                ]),
                HelpSection(title: "Categories", body: """
                Categories organize items within a template. They appear as section headers with icons. Use consistent category names across templates for a clean look.
                """, tips: [
                    "Common categories: Documents, Electronics, Clothing, Toiletries, Footwear, Accessories",
                    "Each category gets an automatic **color-coded icon** in the packing checklist",
                ]),
                HelpSection(title: "Priority Levels", body: """
                **Low** (gray dot) — Nice to have, not essential
                **Medium** (blue dot) — Standard items
                **High** (orange dot) — Important, would be a problem to forget
                **Critical** (red dot) — Must-have, trip-breaking if forgotten (passport, medications)

                High and critical items with due dates trigger **reminder notifications**.
                """),
            ]

        case .contextTags:
            return [
                HelpSection(title: "How Tags Work", body: """
                Context tags are the key to PackIt's flexibility. They let you tag both templates and individual items, then filter when creating a trip.
                """),
                HelpSection(title: "Template-Level Tags", body: """
                Applied to the template as a whole. Used to categorize and find templates. A "Clothing" template might be tagged with "beach", "winter", "hiking", "formal".
                """),
                HelpSection(title: "Item-Level Tags", body: """
                Applied to individual items within a template. When creating a trip and filtering by tags:

                - Items **with no tags** are always included
                - Items **matching any selected tag** are included
                - Items **not matching any selected tag** are excluded

                This means your "Clothing" template can contain both swimsuits (tagged "beach") and heavy coats (tagged "winter"), and the right items are selected based on your trip's context.
                """, tips: [
                    "Leave everyday items **untagged** so they're always included regardless of trip type",
                    "Use specific tags like \"fly-fishing\" for niche gear that should only appear for specific trips",
                ]),
                HelpSection(title: "Adding Tags", body: """
                You can add tags in several places:

                **Template editor** — The "New tag" field at the bottom of the Context Tags section supports **comma-separated input** (e.g., "beach, summer, tropical") and **auto-suggests** existing tags as you type. Press **Tab** to cycle through suggestions, **Enter** to accept.

                **Item editor** — Same tag input field with auto-suggest and comma-separation.

                **Inline tag editor** — Click the **+** button next to tags in the template detail header to add tags directly.

                **Tag manager** — Go to Tags in the sidebar and add tags from the top input field.
                """, tips: [
                    "Use **Tab** and **Shift-Tab** to cycle through suggestions, or **Arrow keys** / **Ctrl-J/K**",
                    "Press **Escape** to dismiss suggestions without accepting",
                ]),
                HelpSection(title: "Managing Tags", body: """
                Go to **Tags** in the sidebar to see all tags, rename them, or delete unused ones. Renaming a tag updates it across all templates automatically.

                **Deleting a tag** removes it everywhere — from the global tag list, from all template-level tags, and from all item-level tags across every template.
                """),
            ]

        case .creatingTrips:
            return [
                HelpSection(title: "New Trip", body: """
                Click the **+** button in the trip list, or use **⌘⇧N**. You'll set:

                **Trip Name** — e.g., "Hawaii 2026"
                **Departure Date** — When you leave
                **Return Date** — Optional
                **Templates** — Toggle on the templates to include
                **Context Tags** — Optionally filter items by tags
                """),
                HelpSection(title: "How Items Are Selected", body: """
                When you select templates and tags:

                1. All items from selected templates are gathered
                2. If you selected context tags, only items matching those tags (or untagged items) are included
                3. Duplicate items (same name) across templates are merged — you won't get "Toothbrush" twice
                4. The combined list becomes your trip's packing checklist
                """, tips: [
                    "Select **no context tags** to include everything from the selected templates",
                    "The preview at the bottom of the sheet shows approximately how many items will be included",
                ]),
                HelpSection(title: "Trip Status", body: """
                **Planning** — Building your list, adding items, organizing
                **Active** — Trip is happening, you're packing
                **Completed** — Trip is done, good for reference
                **Archived** — Hidden from active views, stored for history

                Change status from the **actions menu** (ellipsis icon) in the trip detail view.
                """),
            ]

        case .packingChecklist:
            return [
                HelpSection(title: "Using the Checklist", body: """
                The packing checklist is the heart of PackIt. Click the **circle** next to any item to mark it as packed. The circle fills with a green checkmark and the item gets a subtle green background.
                """),
                HelpSection(title: "Visual Indicators", body: """
                **Priority dots** — Colored dots next to the checkbox indicate priority level
                **Green background** — Item is packed
                **Red background** — High/critical priority item that's overdue
                **Purple "new" badge** — Item was added during the trip (ad-hoc), not from a template
                **Category icons** — Each category has a unique colored icon
                **Alternating backgrounds** — Every other category has a subtle shaded background
                """),
                HelpSection(title: "Multi-Column Layout", body: """
                Items within each category flow into **multiple columns** when the window is wide enough. This makes better use of screen space and gives you an at-a-glance view of your progress.
                """),
                HelpSection(title: "Progress Ring", body: """
                The progress ring in the top-right shows your overall packing completion:

                **Orange** — Less than 50% packed
                **Teal** — 50-99% packed
                **Green** — 100% packed
                """),
                HelpSection(title: "Batch Pack/Unpack", body: """
                Click the **circle icon** next to a category header to pack or unpack all items in that category at once. The icon shows a dashed circle when some items are unpacked, and a filled checkmark when all items are packed.

                This is useful for quickly marking entire categories as packed (e.g., all Toiletries) or resetting a category to start over.
                """, tips: [
                    "Batch operations are undoable — press **⌘Z** to undo if you accidentally pack/unpack a whole category",
                ]),
                HelpSection(title: "Adding Items During a Trip", body: """
                Click **Add Item** at the top of the packing list. Items added during a trip are marked as **ad-hoc** (purple "new" badge). After the trip, you can merge these back into a template.
                """),
            ]

        case .todosAndNotes:
            return [
                HelpSection(title: "The Inspector Sidebar", body: """
                Toggle the inspector using the **sidebar icon** in the action bar (top-right of the trip detail view). The inspector shows three sections:

                **TODOs** — A checklist for trip-related tasks
                **Notes** — Free-form text for the trip
                **Trip Info** — Quick reference for dates, status, and counts
                """),
                HelpSection(title: "Using the Task List", body: """
                Type in the **"Add a todo..."** field and press Enter to quickly add a task. Click the circle to mark it complete. Right-click to delete.

                These tasks are separate from packing items. Use them for things like "Call hotel for late check-in", "Print boarding passes", or "Buy travel adapter".
                """),
                HelpSection(title: "Trip Notes", body: """
                Click **Edit** to open the notes editor. Notes are free-form text for anything related to the trip: confirmation numbers, restaurant recommendations, packing reminders, or directions.
                """),
            ]

        case .merging:
            return [
                HelpSection(title: "What Is Merging?", body: """
                When you add items during a trip that weren't in the original templates, they're marked as **ad-hoc** (purple "new" badge). Merging promotes these items back into a template so they're included in future trips.
                """),
                HelpSection(title: "How to Merge", body: """
                1. Open the trip detail view
                2. Click the **actions menu** (ellipsis icon)
                3. Select **"Merge to Template..."**
                4. Check the ad-hoc items you want to merge
                5. Choose the target template
                6. Click **Merge**

                Items that already exist in the template (by name) are automatically skipped.
                """, tips: [
                    "Merge after every trip to keep your templates growing and improving over time",
                    "You can merge items into a **different template** than the one that seeded the trip",
                ]),
            ]

        case .printing:
            return [
                HelpSection(title: "Print Your Packing List", body: """
                Click the **printer icon** in the trip action bar. PackIt renders a formatted multi-column packing list with checkboxes, priority dots, and category headers.
                """),
                HelpSection(title: "Watermarks & Borders", body: """
                Customize your printed pages with three layers, each independently controlled:

                **Repeating Pattern** — Small motifs tiled across the page (palm trees, waves, compasses, etc.)
                **Full-Page Art** — A single large illustration (beach scene, mountain landscape, world map, etc.)
                **Border** — Decorative frame around the page (simple line, rope, vine, passport stamps, etc.)

                Each layer has its own **opacity slider** so you can make them as subtle or visible as you like. All layers are light enough to print text over clearly.
                """),
                HelpSection(title: "Print Settings", body: """
                PackIt sets zero margins and disables system headers/footers for full creative control. The print dialog still lets you choose your printer, paper size, and number of copies.

                Configure watermarks and borders in **Settings** (gear icon at the bottom of the sidebar, or ⌘,).
                """),
            ]

        case .exporting:
            return [
                HelpSection(title: "Exporting Trips", body: """
                **PackIt File (.packitlist)** — Native format containing the full trip data. Share with other PackIt users via AirDrop, email, or a shared folder. Double-clicking a .packitlist file opens it in PackIt.

                **HTML** — A self-contained web page with checkboxes, styled with the PackIt teal theme. Great for sharing with anyone or printing from a browser.

                **CSV** — Spreadsheet-compatible format with columns for Category, Item, Priority, Packed, and Notes. Open in Excel, Numbers, or Google Sheets.
                """),
                HelpSection(title: "Exporting Templates", body: """
                Templates can also be exported and shared. Right-click a template and choose **Export...**, or use the **Export** button in the template detail toolbar.

                **PackIt Template (.packittemplate)** — Native format for sharing templates with other PackIt users. Double-clicking a .packittemplate file imports it into PackIt.

                **HTML** — A printable checklist version of the template with category headers and checkboxes.

                **CSV** — Spreadsheet format with columns for Category, Item, Priority, Notes, and Tags.
                """, tips: [
                    "Share your best templates with friends and family so they can use them as a starting point",
                    "Export as HTML for a quick printable checklist without needing the app",
                ]),
                HelpSection(title: "Sharing", body: """
                To share with someone who has PackIt, export as **.packitlist** (trips) or **.packittemplate** (templates) and send via AirDrop, email, or shared folder. They can double-click to import.

                For someone without PackIt, use **HTML** (opens in any browser) or **CSV** (for spreadsheet editing).
                """),
            ]

        case .reminders:
            return [
                HelpSection(title: "Automatic Reminders", body: """
                PackIt schedules reminders through macOS notifications:

                **Departure Reminder** — Fires the day before your departure date
                **Item Due Date Reminders** — For high-priority and critical items with due dates

                Reminders are automatically created and updated whenever you create or modify a trip. Completing or archiving a trip cancels all its reminders.
                """),
                HelpSection(title: "Notification Permission", body: """
                PackIt requests notification permission on first launch. If you denied it, re-enable in:

                **System Settings → Notifications → PackIt**
                """),
            ]

        case .statistics:
            return [
                HelpSection(title: "Statistics Dashboard", body: """
                Click **Statistics** in the sidebar to see insights about your trips and packing habits. The dashboard shows data from all your trips — the more trips you take, the more useful the insights become.
                """),
                HelpSection(title: "Overview Cards", body: """
                At-a-glance numbers including:

                **Total Trips** — All trips across all statuses
                **Items Packed** — Total items checked off across all trips
                **Completion Rate** — Average packing progress of completed/archived trips
                **Templates** — How many templates you've built
                **Avg Items/Trip** — Average number of items per trip
                **Ad-Hoc Items** — Total items added during trips (not from templates)
                """),
                HelpSection(title: "Insights", body: """
                **Most Packed Items** — Items that appear across the most trips, ranked by frequency. Useful for seeing your packing essentials.

                **Top Categories** — Which categories contain the most items across all trips.

                **Frequently Added Ad-Hoc** — Items you keep adding during trips that aren't in any template. If an item shows up here, consider adding it to a template so you don't forget it next time.
                """, tips: [
                    "The ad-hoc insights section only shows items added in 2 or more trips — one-offs are filtered out",
                ]),
                HelpSection(title: "Trip Timeline", body: """
                A chronological view of all your trips showing name, departure date, status, item count, and packing progress. Great for reviewing your travel history.
                """),
            ]

        case .settings:
            return [
                HelpSection(title: "Accessing Settings", body: """
                Open Settings via the **gear icon** at the bottom of the sidebar, or from the **PackIt menu → Settings** (⌘,).
                """),
                HelpSection(title: "Print Settings", body: """
                The Settings window shows print customization with a live preview:

                **Repeating Pattern** — Toggle on/off, choose style, adjust opacity (2-15%)
                **Full-Page Art** — Toggle on/off, choose style, adjust opacity (2-12%)
                **Border** — Toggle on/off, choose style, adjust opacity (3-20%)

                The preview on the right updates in real-time as you change settings, showing all active layers combined with simulated packing list text.
                """),
            ]

        case .shortcuts:
            return [
                HelpSection(title: "Global", body: """
                **⌘N** — New template
                **⌘⇧N** — New trip
                **⌘K** — Quick search
                **⌘Z** — Undo
                **⌘⇧Z** — Redo
                **⌘,** — Settings
                **⌘?** — Help
                """),
                HelpSection(title: "Trip Detail", body: """
                The trip action bar (top-right) provides quick access to:
                - **Actions menu** — Status changes, merge, export
                - **Print** — Print the packing list
                - **Edit** — Edit trip details
                - **Inspector toggle** — Show/hide TODOs & Notes sidebar
                """),
                HelpSection(title: "Auto-Suggest Fields", body: """
                Tag and item name fields with auto-suggest support these keys:

                **Tab** — Select first suggestion (or advance to next)
                **Shift-Tab** — Move to previous suggestion
                **↓ / Ctrl-J** — Same as Tab (advance)
                **↑ / Ctrl-K** — Same as Shift-Tab (previous)
                **Enter** — Accept the current suggestion
                **Enter** (again) — Submit / commit the value
                **Escape** — Dismiss suggestions
                """),
                HelpSection(title: "Navigation", body: """
                - **Click sidebar items** to switch between sections
                - **Click items in the middle column** to view details
                - **Double-click** a template item to edit it
                - **Arrow keys** work in lists for keyboard navigation
                - **Right-click** items for context menus (edit, delete)
                """),
            ]
        }
    }
}
