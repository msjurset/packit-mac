import SwiftUI

struct HelpView: View {
    @State private var selectedTopic: HelpTopic? = .gettingStarted

    var body: some View {
        NavigationSplitView {
            List(HelpTopic.allCases, selection: $selectedTopic) { topic in
                Label(topic.title, systemImage: topic.icon)
                    .tag(topic)
            }
            .listStyle(.sidebar)
            .navigationTitle("Help")
        } detail: {
            if let topic = selectedTopic {
                ScrollView {
                    Text(topic.content)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationTitle(topic.title)
            } else {
                ContentUnavailableView("Select a Topic", systemImage: "questionmark.circle")
            }
        }
    }
}

enum HelpTopic: String, CaseIterable, Identifiable {
    case gettingStarted
    case templates
    case trips
    case contextTags
    case packingChecklist
    case merging
    case exporting
    case reminders
    case shortcuts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gettingStarted: return "Getting Started"
        case .templates: return "Templates"
        case .trips: return "Trips"
        case .contextTags: return "Context Tags"
        case .packingChecklist: return "Packing Checklist"
        case .merging: return "Merging Items"
        case .exporting: return "Exporting & Sharing"
        case .reminders: return "Reminders"
        case .shortcuts: return "Keyboard Shortcuts"
        }
    }

    var icon: String {
        switch self {
        case .gettingStarted: return "star"
        case .templates: return "doc.on.doc"
        case .trips: return "suitcase"
        case .contextTags: return "tag"
        case .packingChecklist: return "checklist"
        case .merging: return "arrow.up.doc"
        case .exporting: return "square.and.arrow.up"
        case .reminders: return "bell"
        case .shortcuts: return "keyboard"
        }
    }

    var content: String {
        switch self {
        case .gettingStarted:
            return """
            Welcome to PackIt!

            PackIt helps you create and manage packing lists for your trips. Here's how to get started:

            1. Create a Template: Templates are reusable packing lists. Start by creating one with common items you always pack.

            2. Add Context Tags: Tag your templates and items with contexts like "beach", "winter", or "international". This lets you mix and match when creating a trip.

            3. Create a Trip: When you're ready to pack, create a new trip. Select templates and optionally filter by context tags to build your packing list.

            4. Pack! Check off items as you pack them. Add ad-hoc items, TODOs, and notes as needed.

            5. After the Trip: Merge any new items you added back into your templates for next time.
            """

        case .templates:
            return """
            Templates are reusable packing list blueprints.

            Creating a Template:
            - Click the + button or use the menu to create a new template
            - Give it a descriptive name (e.g., "Beach Vacation", "Business Trip")
            - Assign context tags to categorize it

            Managing Items:
            - Add items with names, categories, priorities, and notes
            - Assign context tags to individual items for fine-grained filtering
            - Items are grouped by category in the template view

            Tips:
            - Create broad templates (e.g., "Toiletries", "Electronics") and combine them when creating trips
            - Use categories to organize items within a template
            """

        case .trips:
            return """
            Trips are instances of your packing lists for actual travel.

            Creating a Trip:
            - Set departure and optional return dates
            - Select one or more templates to seed your packing list
            - Optionally filter by context tags to include only relevant items
            - Items are deduplicated across templates automatically

            Trip Status:
            - Planning: You're building and organizing the list
            - Active: The trip is happening, time to pack!
            - Completed: Trip is done
            - Archived: Stored for reference

            You can change status from the trip detail view's action menu.
            """

        case .contextTags:
            return """
            Context tags help you create flexible, composable packing lists.

            How They Work:
            - Tags are applied to both templates and individual items
            - When creating a trip, select tags to filter which items are included
            - Items with no tags are always included
            - Items matching any selected tag are included

            Examples:
            - "beach" — sunscreen, swimsuit, snorkel
            - "winter" — heavy coat, gloves, hand warmers
            - "international" — passport, adapter, foreign currency
            - "fishing" — rod, tackle box, waders

            Manage tags from the Tags section in the sidebar.
            """

        case .packingChecklist:
            return """
            The packing checklist is where you track your packing progress.

            Color Coding:
            - Green checkmark: Item is packed
            - Red highlight: High-priority item that is overdue
            - Purple "new" badge: Ad-hoc item added during the trip
            - Priority dots indicate item importance

            Features:
            - Click the circle to toggle packed status
            - Items are grouped by category
            - Progress bar shows overall completion
            - Overdue high-priority items are highlighted at the top
            """

        case .merging:
            return """
            After a trip, you can merge ad-hoc items back into your templates.

            When you add items during a trip that weren't in the original template, they're marked as "ad-hoc". After the trip, you can promote these back to a template so they're included next time.

            How to Merge:
            1. Open the trip detail view
            2. Click the action menu (ellipsis)
            3. Select "Merge to Template..."
            4. Choose which ad-hoc items to merge
            5. Select the target template
            6. Click Merge

            Items that already exist in the template (by name) are skipped.
            """

        case .exporting:
            return """
            Export and share your packing lists in multiple formats.

            Formats:
            - .packitlist: Native format. Share with other PackIt users via AirDrop, email, etc. Double-clicking opens in PackIt.
            - HTML: Self-contained web page with checkboxes. Great for printing or sharing with anyone.
            - CSV: Spreadsheet-compatible format for further editing.

            Sharing with Others:
            - Export as .packitlist and send via AirDrop or email
            - The recipient can double-click the file to import it into their copy of PackIt
            """

        case .reminders:
            return """
            PackIt automatically schedules reminders to help you stay on track.

            Departure Reminder:
            - A notification is scheduled for the day before your departure date
            - This fires for trips in Planning or Active status

            Item Due Date Reminders:
            - High-priority and critical items with due dates get reminders
            - The reminder fires on the due date

            How It Works:
            - Reminders are synced automatically when you create or update a trip
            - Completing or archiving a trip cancels its reminders
            - The trip detail view shows how many reminders are scheduled
            - PackIt requests notification permission on first launch

            Note: If you denied notification permission, you can re-enable it in System Settings > Notifications > PackIt.
            """

        case .shortcuts:
            return """
            Keyboard Shortcuts:

            General:
            - ⌘N — New template
            - ⌘K — Quick search
            - ⌘? — Help

            Navigation:
            - Use arrow keys in the sidebar to navigate
            - Enter to select an item
            """
        }
    }
}
