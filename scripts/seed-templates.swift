#!/usr/bin/env swift

import Foundation

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

struct TemplateItem: Codable {
    var id: UUID
    var name: String
    var category: String?
    var contextTags: [String]
    var priority: String
    var notes: String?
}

struct PackingTemplate: Codable {
    var id: UUID
    var name: String
    var items: [TemplateItem]
    var contextTags: [String]
    var createdAt: Date
    var updatedAt: Date
}

struct ContextTag: Codable {
    var id: UUID
    var name: String
    var color: String?
}

func item(_ name: String, cat: String, tags: [String] = [], priority: String = "medium", notes: String? = nil) -> TemplateItem {
    TemplateItem(id: UUID(), name: name, category: cat, contextTags: tags, priority: priority, notes: notes)
}

let now = Date()
let home = FileManager.default.homeDirectoryForCurrentUser
let dir = home.appendingPathComponent(".packit/templates")
let fm = FileManager.default

// Ensure directories exist
for path in [".packit", ".packit/templates", ".packit/trips"] {
    let url = home.appendingPathComponent(path)
    if !fm.fileExists(atPath: url.path) {
        try! fm.createDirectory(at: url, withIntermediateDirectories: true)
    }
}

// Check for existing templates
if let existing = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
   existing.contains(where: { $0.pathExtension == "json" }) {
    print("Templates already exist in ~/.packit/templates/")
    print("To re-seed, remove existing templates first: rm ~/.packit/templates/*.json")
    Foundation.exit(0)
}

// --- Templates ---

let essentials = PackingTemplate(
    id: UUID(), name: "Travel Essentials", items: [
        item("Passport", cat: "Documents", tags: ["international"], priority: "critical"),
        item("Driver's license", cat: "Documents", priority: "critical"),
        item("Credit cards", cat: "Documents", priority: "critical"),
        item("Travel insurance docs", cat: "Documents", tags: ["international"]),
        item("Boarding passes", cat: "Documents", tags: ["flying"], priority: "high"),
        item("Hotel confirmation", cat: "Documents", priority: "high"),
        item("Phone charger", cat: "Electronics", priority: "critical"),
        item("Laptop + charger", cat: "Electronics", tags: ["work", "long-trip"]),
        item("Power bank", cat: "Electronics", priority: "high"),
        item("Headphones", cat: "Electronics"),
        item("Universal power adapter", cat: "Electronics", tags: ["international"], priority: "high"),
        item("Medications", cat: "Health", priority: "critical", notes: "Prescription and OTC"),
        item("First aid kit", cat: "Health"),
        item("Sunglasses", cat: "Accessories"),
        item("Wallet", cat: "Accessories", priority: "critical"),
        item("Keys", cat: "Accessories", priority: "critical"),
        item("Reusable water bottle", cat: "Accessories"),
        item("Snacks", cat: "Food", tags: ["road-trip", "flying"]),
        item("Cash / local currency", cat: "Documents", tags: ["international"]),
    ],
    contextTags: ["international", "domestic", "flying", "road-trip"],
    createdAt: now, updatedAt: now
)

let clothing = PackingTemplate(
    id: UUID(), name: "Clothing", items: [
        item("Underwear (per day + 2)", cat: "Basics", priority: "high"),
        item("Socks (per day + 2)", cat: "Basics", priority: "high"),
        item("T-shirts / tops", cat: "Basics"),
        item("Pants / shorts", cat: "Basics"),
        item("Pajamas", cat: "Basics"),
        item("Light jacket", cat: "Layers"),
        item("Rain jacket", cat: "Layers", tags: ["rainy", "hiking"]),
        item("Heavy coat", cat: "Layers", tags: ["winter"], priority: "high"),
        item("Gloves", cat: "Layers", tags: ["winter"]),
        item("Beanie / warm hat", cat: "Layers", tags: ["winter"]),
        item("Scarf", cat: "Layers", tags: ["winter"]),
        item("Swimsuit", cat: "Activity Wear", tags: ["beach", "resort"]),
        item("Cover-up / sarong", cat: "Activity Wear", tags: ["beach", "resort"]),
        item("Hiking boots", cat: "Footwear", tags: ["hiking"]),
        item("Comfortable walking shoes", cat: "Footwear", priority: "high"),
        item("Sandals / flip-flops", cat: "Footwear", tags: ["beach", "resort"]),
        item("Dress shoes", cat: "Footwear", tags: ["formal", "work"]),
        item("Dress / nice outfit", cat: "Formal", tags: ["formal", "dinner"]),
        item("Belt", cat: "Accessories"),
        item("Hat / sun hat", cat: "Accessories", tags: ["beach", "summer", "hiking"]),
    ],
    contextTags: ["beach", "winter", "hiking", "formal", "resort", "summer"],
    createdAt: now, updatedAt: now
)

let toiletries = PackingTemplate(
    id: UUID(), name: "Toiletries", items: [
        item("Toothbrush", cat: "Dental", priority: "high"),
        item("Toothpaste", cat: "Dental", priority: "high"),
        item("Floss", cat: "Dental"),
        item("Shampoo", cat: "Hair"),
        item("Conditioner", cat: "Hair"),
        item("Hair brush / comb", cat: "Hair"),
        item("Hair ties", cat: "Hair"),
        item("Deodorant", cat: "Body", priority: "high"),
        item("Body wash / soap", cat: "Body"),
        item("Razor", cat: "Body"),
        item("Sunscreen", cat: "Skin", tags: ["beach", "summer", "hiking"], priority: "high", notes: "SPF 50+"),
        item("Moisturizer", cat: "Skin"),
        item("Lip balm with SPF", cat: "Skin", tags: ["beach", "summer", "winter"]),
        item("Bug spray", cat: "Skin", tags: ["camping", "hiking"]),
        item("Contact lenses + solution", cat: "Vision", notes: "If applicable"),
        item("Makeup bag", cat: "Cosmetics"),
        item("Nail clippers", cat: "Grooming"),
        item("Tissues / travel wipes", cat: "Misc"),
    ],
    contextTags: ["beach", "summer", "camping", "hiking"],
    createdAt: now, updatedAt: now
)

let beach = PackingTemplate(
    id: UUID(), name: "Beach Vacation", items: [
        item("Beach towels", cat: "Beach Gear", priority: "high"),
        item("Cooler / insulated bag", cat: "Beach Gear"),
        item("Beach umbrella / shade tent", cat: "Beach Gear"),
        item("Beach chairs", cat: "Beach Gear"),
        item("Snorkel + mask", cat: "Water Sports"),
        item("Boogie board", cat: "Water Sports"),
        item("Floaties / pool toys", cat: "Water Sports"),
        item("Waterproof phone case", cat: "Electronics", priority: "high"),
        item("Bluetooth speaker", cat: "Electronics"),
        item("Books / Kindle", cat: "Entertainment"),
        item("Beach bag / tote", cat: "Bags"),
        item("Aloe vera gel", cat: "Skin Care", priority: "high", notes: "For sunburn"),
        item("After-sun lotion", cat: "Skin Care"),
        item("Water shoes", cat: "Footwear"),
        item("Dry bag", cat: "Bags", notes: "For valuables on the beach"),
    ],
    contextTags: ["beach", "resort", "tropical"],
    createdAt: now, updatedAt: now
)

let fishing = PackingTemplate(
    id: UUID(), name: "Fishing Trip", items: [
        item("Fishing rod + reel", cat: "Fishing Gear", priority: "critical"),
        item("Tackle box", cat: "Fishing Gear", priority: "critical"),
        item("Extra line + leaders", cat: "Fishing Gear", priority: "high"),
        item("Lures / bait", cat: "Fishing Gear", priority: "high"),
        item("Fishing license", cat: "Documents", priority: "critical", notes: "Check state requirements"),
        item("Net", cat: "Fishing Gear"),
        item("Pliers / multi-tool", cat: "Tools", priority: "high"),
        item("Fillet knife", cat: "Tools"),
        item("Cooler with ice", cat: "Storage", priority: "high", notes: "For the catch"),
        item("Zip-lock bags", cat: "Storage"),
        item("Waders", cat: "Clothing", tags: ["river", "fly-fishing"]),
        item("Wading boots", cat: "Footwear", tags: ["river", "fly-fishing"]),
        item("Polarized sunglasses", cat: "Accessories", priority: "high", notes: "Reduces water glare"),
        item("Wide-brim hat", cat: "Accessories"),
        item("Sunscreen", cat: "Skin", priority: "high"),
        item("Bug spray", cat: "Skin", priority: "high"),
        item("Rain gear", cat: "Clothing"),
        item("Gloves (sun protection)", cat: "Clothing"),
        item("Camp chair", cat: "Comfort"),
        item("Binoculars", cat: "Accessories"),
    ],
    contextTags: ["fishing", "river", "fly-fishing", "lake", "ocean"],
    createdAt: now, updatedAt: now
)

let camping = PackingTemplate(
    id: UUID(), name: "Camping", items: [
        item("Tent + stakes + rainfly", cat: "Shelter", priority: "critical"),
        item("Sleeping bag", cat: "Shelter", priority: "critical"),
        item("Sleeping pad / air mattress", cat: "Shelter", priority: "high"),
        item("Pillow", cat: "Shelter"),
        item("Headlamp + extra batteries", cat: "Lighting", priority: "critical"),
        item("Lantern", cat: "Lighting"),
        item("Camp stove + fuel", cat: "Cooking", priority: "high"),
        item("Pots / pans", cat: "Cooking"),
        item("Utensils / plates / cups", cat: "Cooking"),
        item("Cooler with food", cat: "Food", priority: "high"),
        item("Water filter / purification", cat: "Water", tags: ["backcountry"]),
        item("Fire starter / matches", cat: "Fire", priority: "high"),
        item("Firewood or axe", cat: "Fire"),
        item("Camp chairs", cat: "Comfort"),
        item("Multi-tool / knife", cat: "Tools", priority: "high"),
        item("Rope / paracord", cat: "Tools"),
        item("Trash bags", cat: "Cleanup", notes: "Leave no trace"),
        item("Bear canister", cat: "Safety", tags: ["backcountry"], notes: "Required in some areas"),
        item("Map + compass", cat: "Navigation", tags: ["backcountry"]),
        item("Whistle", cat: "Safety"),
        item("Tarp", cat: "Shelter"),
    ],
    contextTags: ["camping", "backcountry", "car-camping"],
    createdAt: now, updatedAt: now
)

// Write templates
let templates = [essentials, clothing, toiletries, beach, fishing, camping]
for template in templates {
    let data = try! encoder.encode(template)
    let file = dir.appendingPathComponent("\(template.id.uuidString).json")
    try! data.write(to: file)
    print("Created: \(template.name) (\(template.items.count) items)")
}

// Write context tags
let tagNames = [
    "international", "domestic", "flying", "road-trip",
    "beach", "resort", "tropical", "summer", "winter",
    "hiking", "camping", "backcountry", "car-camping",
    "fishing", "river", "fly-fishing", "lake", "ocean",
    "formal", "work", "dinner", "long-trip", "rainy",
]
let tags = tagNames.map { ContextTag(id: UUID(), name: $0, color: nil) }
let tagData = try! encoder.encode(tags)
let tagsFile = home.appendingPathComponent(".packit/tags.json")
try! tagData.write(to: tagsFile)
print("\nCreated \(tags.count) context tags")
print("Seed complete!")
