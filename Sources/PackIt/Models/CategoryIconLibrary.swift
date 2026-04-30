import SwiftUI
import PackItKit

/// Curated SF Symbols suitable for item categories, with searchable keywords.
enum CategoryIconLibrary {
    struct Entry: Identifiable, Hashable {
        let symbol: String
        let label: String
        let keywords: [String]
        var id: String { symbol }
    }

    static let entries: [Entry] = [
        // Travel & docs
        .init(symbol: "doc.text.fill",          label: "Documents",   keywords: ["document", "papers", "passport", "id"]),
        .init(symbol: "person.text.rectangle.fill", label: "Passport", keywords: ["passport", "travel", "id"]),
        .init(symbol: "creditcard.fill",        label: "Cards",       keywords: ["card", "wallet", "credit"]),
        .init(symbol: "wallet.pass.fill",       label: "Wallet",      keywords: ["wallet", "cash"]),
        .init(symbol: "key.fill",               label: "Keys",        keywords: ["key", "keys", "lock"]),
        .init(symbol: "map.fill",               label: "Map",         keywords: ["map", "navigation"]),
        .init(symbol: "airplane",               label: "Flight",      keywords: ["airplane", "flight", "travel"]),
        .init(symbol: "ferry.fill",             label: "Cruise",      keywords: ["cruise", "ferry", "ship", "boat"]),
        .init(symbol: "car.fill",               label: "Car",         keywords: ["car", "drive", "vehicle"]),
        .init(symbol: "bus.fill",               label: "Bus / RV",    keywords: ["rv", "bus", "camper"]),
        .init(symbol: "bicycle",                label: "Bike",        keywords: ["bike", "bicycle", "cycling"]),

        // Bags & containers
        .init(symbol: "suitcase.fill",          label: "Suitcase",    keywords: ["suitcase", "luggage", "travel"]),
        .init(symbol: "backpack.fill",          label: "Backpack",    keywords: ["backpack", "bag", "carry-on"]),
        .init(symbol: "bag.fill",               label: "Bag",         keywords: ["bag", "tote", "purse"]),
        .init(symbol: "archivebox.fill",        label: "Storage",     keywords: ["box", "storage", "container"]),
        .init(symbol: "shippingbox.fill",       label: "Box",         keywords: ["box", "package", "container"]),

        // Clothing
        .init(symbol: "tshirt.fill",            label: "T-shirt",     keywords: ["shirt", "tshirt", "tops", "basics"]),
        .init(symbol: "figure.dress.line.vertical.figure", label: "Formalwear", keywords: ["formal", "tie", "suit", "dress"]),
        .init(symbol: "shoe.fill",              label: "Shoes",       keywords: ["shoe", "footwear", "boot"]),
        .init(symbol: "shoeprints.fill",        label: "Footwear",    keywords: ["footwear", "shoes"]),
        .init(symbol: "cloud.sun.fill",         label: "Layers",      keywords: ["layer", "jacket", "sweater"]),

        // Toiletries
        .init(symbol: "bathtub.fill",           label: "Bath",        keywords: ["bath", "bathroom", "tub", "soak", "toiletries"]),
        .init(symbol: "shower.fill",            label: "Shower",      keywords: ["shower", "bath", "bathroom", "wash"]),
        .init(symbol: "shower.handheld.fill",   label: "Hand shower", keywords: ["shower", "handheld", "bath"]),
        .init(symbol: "toilet.fill",            label: "Toilet",      keywords: ["toilet", "bathroom", "wc"]),
        .init(symbol: "sink.fill",              label: "Sink",        keywords: ["sink", "bathroom", "kitchen", "wash"]),
        .init(symbol: "drop.fill",              label: "Liquids",     keywords: ["liquid", "shampoo", "lotion", "water", "toiletries"]),
        .init(symbol: "mouth.fill",             label: "Dental",      keywords: ["dental", "teeth", "mouth", "toothbrush"]),
        .init(symbol: "comb.fill",              label: "Hair",        keywords: ["hair", "comb", "brush"]),
        .init(symbol: "scissors",               label: "Grooming",    keywords: ["groom", "razor", "scissors", "clipper"]),
        .init(symbol: "eye.fill",               label: "Vision",      keywords: ["eye", "vision", "glasses"]),
        .init(symbol: "eyeglasses",             label: "Glasses",     keywords: ["glasses", "eyewear"]),
        .init(symbol: "paintbrush.fill",        label: "Cosmetics",   keywords: ["makeup", "cosmetic", "paint"]),
        .init(symbol: "sparkles",               label: "Accessories", keywords: ["sparkle", "shine", "accessor"]),
        .init(symbol: "leaf.fill",              label: "Skin care",   keywords: ["skin", "leaf", "natural", "lotion"]),
        .init(symbol: "sun.max.fill",           label: "Sun",         keywords: ["sun", "sunscreen", "spf"]),
        .init(symbol: "cross.case.fill",        label: "Health",      keywords: ["health", "medical", "first aid"]),
        .init(symbol: "pills.fill",             label: "Medication",  keywords: ["pill", "medication", "drug", "rx"]),
        .init(symbol: "bandage.fill",           label: "First aid",   keywords: ["bandage", "first aid", "injury"]),

        // Body
        .init(symbol: "figure.arms.open",       label: "Body",        keywords: ["body", "person", "arms"]),
        .init(symbol: "figure.run",             label: "Activity",    keywords: ["activity", "run", "workout", "exercise"]),
        .init(symbol: "dumbbell.fill",          label: "Workout",     keywords: ["workout", "gym", "weights"]),

        // Food / kitchen
        .init(symbol: "fork.knife",             label: "Food",        keywords: ["food", "meal", "eat"]),
        .init(symbol: "frying.pan.fill",        label: "Cooking",     keywords: ["cook", "pan", "kitchen"]),
        .init(symbol: "cup.and.saucer.fill",    label: "Coffee",      keywords: ["coffee", "tea", "cup", "mug"]),
        .init(symbol: "wineglass.fill",         label: "Wine",        keywords: ["wine", "drink", "alcohol"]),
        .init(symbol: "carrot.fill",            label: "Produce",     keywords: ["produce", "veggie", "carrot", "food"]),
        .init(symbol: "birthday.cake.fill",     label: "Treats",      keywords: ["cake", "treat", "dessert", "baked", "bakery", "pastry", "bread"]),

        // Camping
        .init(symbol: "tent.fill",              label: "Tent",        keywords: ["tent", "camp", "shelter"]),
        .init(symbol: "flame.fill",             label: "Fire",        keywords: ["fire", "flame", "heat"]),
        .init(symbol: "flashlight.on.fill",     label: "Lighting",    keywords: ["light", "flashlight", "lantern"]),
        .init(symbol: "lightbulb.fill",         label: "Lights",      keywords: ["light", "bulb"]),
        .init(symbol: "binoculars.fill",        label: "Binoculars",  keywords: ["binocular", "view", "spot"]),
        .init(symbol: "fish.fill",              label: "Fishing",     keywords: ["fishing", "fish", "tackle"]),
        .init(symbol: "figure.fishing",         label: "Angler",      keywords: ["rod", "fishing", "angler"]),
        .init(symbol: "leaf",                   label: "Outdoor",     keywords: ["outdoor", "nature", "leaf"]),

        // Beach / water
        .init(symbol: "beach.umbrella.fill",    label: "Beach",       keywords: ["beach", "umbrella", "sand"]),
        .init(symbol: "water.waves",            label: "Water",       keywords: ["water", "ocean", "wave"]),
        .init(symbol: "figure.water.fitness",   label: "Swimming",    keywords: ["swim", "water", "fitness"]),
        .init(symbol: "sailboat.fill",          label: "Sailing",     keywords: ["sail", "boat", "sailing"]),

        // Tech / electronics
        .init(symbol: "bolt.fill",              label: "Electronics", keywords: ["electronic", "power", "bolt"]),
        .init(symbol: "laptopcomputer",         label: "Computer",    keywords: ["computer", "laptop", "mac"]),
        .init(symbol: "iphone",                 label: "Phone",       keywords: ["phone", "iphone", "mobile"]),
        .init(symbol: "headphones",             label: "Audio",       keywords: ["headphone", "audio", "music"]),
        .init(symbol: "camera.fill",            label: "Camera",      keywords: ["camera", "photo"]),
        .init(symbol: "powerplug.fill",         label: "Power",       keywords: ["plug", "power", "charger"]),
        .init(symbol: "battery.100",            label: "Battery",     keywords: ["battery", "power"]),

        // Tools / repair
        .init(symbol: "wrench.and.screwdriver.fill", label: "Tools",  keywords: ["tool", "wrench", "repair"]),
        .init(symbol: "hammer.fill",            label: "Hammer",      keywords: ["hammer", "tool"]),
        .init(symbol: "shield.checkered",       label: "Safety",      keywords: ["safety", "shield", "protect"]),

        // Furniture / comfort
        .init(symbol: "chair.lounge.fill",      label: "Comfort",     keywords: ["chair", "lounge", "comfort"]),
        .init(symbol: "bed.double.fill",        label: "Sleep",       keywords: ["bed", "sleep", "rest"]),
        .init(symbol: "moon.zzz.fill",          label: "Bedding",     keywords: ["pillow", "sleep", "rest", "bedding"]),

        // Pets
        .init(symbol: "pawprint.fill",          label: "Pets",        keywords: ["pet", "paw", "dog", "cat"]),

        // Books / leisure / kids
        .init(symbol: "book.fill",              label: "Reading",     keywords: ["book", "read", "entertainment"]),
        .init(symbol: "gamecontroller.fill",    label: "Games",       keywords: ["game", "play"]),
        .init(symbol: "music.note",             label: "Music",       keywords: ["music", "note", "song"]),
        .init(symbol: "balloon.fill",           label: "Kids",        keywords: ["kid", "balloon", "child"]),

        // Cleanup
        .init(symbol: "leaf.arrow.triangle.circlepath", label: "Cleanup", keywords: ["clean", "recycle", "tidy"]),
        .init(symbol: "trash.fill",             label: "Trash",       keywords: ["trash", "garbage", "bin"]),

        // Sports
        .init(symbol: "tennis.racket",          label: "Tennis",      keywords: ["tennis", "racket"]),
        .init(symbol: "basketball.fill",        label: "Basketball",  keywords: ["basketball", "ball", "hoops"]),
        .init(symbol: "soccerball",             label: "Soccer",      keywords: ["soccer", "football", "ball"]),
        .init(symbol: "football.fill",          label: "Football",    keywords: ["football", "rugby", "ball"]),
        .init(symbol: "baseball.fill",          label: "Baseball",    keywords: ["baseball", "softball", "ball"]),
        .init(symbol: "volleyball.fill",        label: "Volleyball",  keywords: ["volleyball", "ball"]),
        .init(symbol: "skateboard.fill",        label: "Skateboard",  keywords: ["skate", "skateboard"]),
        .init(symbol: "figure.golf",            label: "Golf",        keywords: ["golf", "golfing"]),
        .init(symbol: "figure.skiing.downhill", label: "Skiing",      keywords: ["ski", "skiing", "snow"]),
        .init(symbol: "figure.snowboarding",    label: "Snowboard",   keywords: ["snowboard", "boarding", "snow"]),
        .init(symbol: "figure.surfing",         label: "Surfing",     keywords: ["surf", "surfing", "wave"]),
        .init(symbol: "figure.climbing",        label: "Climbing",    keywords: ["climb", "rock", "bouldering"]),
        .init(symbol: "figure.bowling",         label: "Bowling",     keywords: ["bowling", "pins"]),
        .init(symbol: "figure.boxing",          label: "Boxing",      keywords: ["boxing", "fight"]),
        .init(symbol: "figure.archery",         label: "Archery",     keywords: ["archery", "bow", "arrow"]),
        .init(symbol: "figure.skating",         label: "Skating",     keywords: ["skate", "ice"]),

        // Weather
        .init(symbol: "snowflake",              label: "Snow",        keywords: ["snow", "winter", "cold"]),
        .init(symbol: "cloud.fill",             label: "Clouds",      keywords: ["cloud", "weather", "overcast"]),
        .init(symbol: "cloud.rain.fill",        label: "Rain",        keywords: ["rain", "weather", "wet"]),
        .init(symbol: "cloud.snow.fill",        label: "Snowy",       keywords: ["snow", "weather", "winter"]),
        .init(symbol: "sun.dust.fill",          label: "Hot",         keywords: ["sun", "hot", "desert", "heat"]),
        .init(symbol: "moon.fill",              label: "Night",       keywords: ["moon", "night", "sleep"]),
        .init(symbol: "thermometer.medium",     label: "Temperature", keywords: ["thermometer", "temp", "weather"]),
        .init(symbol: "umbrella.fill",          label: "Umbrella",    keywords: ["umbrella", "rain"]),
        .init(symbol: "wind",                   label: "Wind",        keywords: ["wind", "weather", "breeze"]),

        // Office / paper
        .init(symbol: "envelope.fill",          label: "Mail",        keywords: ["mail", "envelope", "letter"]),
        .init(symbol: "paperplane.fill",        label: "Send",        keywords: ["paperplane", "send", "share"]),
        .init(symbol: "paperclip",              label: "Clip",        keywords: ["paperclip", "attach", "office"]),
        .init(symbol: "pencil",                 label: "Pencil",      keywords: ["pencil", "write", "edit"]),
        .init(symbol: "books.vertical.fill",    label: "Books",       keywords: ["books", "library", "read"]),
        .init(symbol: "folder.fill",            label: "Folder",      keywords: ["folder", "files"]),
        .init(symbol: "calendar",               label: "Calendar",    keywords: ["calendar", "date", "schedule"]),
        .init(symbol: "clock.fill",             label: "Clock",       keywords: ["clock", "time"]),
        .init(symbol: "alarm.fill",             label: "Alarm",       keywords: ["alarm", "wake"]),
        .init(symbol: "timer",                  label: "Timer",       keywords: ["timer", "stopwatch"]),
        .init(symbol: "hourglass",              label: "Hourglass",   keywords: ["hourglass", "wait", "time"]),
        .init(symbol: "graduationcap.fill",     label: "School",      keywords: ["school", "graduate", "education"]),

        // Health (additional)
        .init(symbol: "heart.fill",             label: "Heart",       keywords: ["heart", "love", "wellness"]),
        .init(symbol: "stethoscope",            label: "Doctor",      keywords: ["doctor", "medical", "appointment"]),
        .init(symbol: "syringe.fill",           label: "Vaccine",     keywords: ["vaccine", "shot", "syringe"]),

        // Music
        .init(symbol: "music.note.list",        label: "Playlist",    keywords: ["playlist", "music", "queue"]),
        .init(symbol: "mic.fill",               label: "Microphone",  keywords: ["mic", "microphone", "podcast"]),
        .init(symbol: "guitars.fill",           label: "Guitar",      keywords: ["guitar", "instrument"]),
        .init(symbol: "pianokeys",              label: "Piano",       keywords: ["piano", "keys", "instrument"]),
        .init(symbol: "speaker.wave.3.fill",    label: "Speaker",     keywords: ["speaker", "audio", "sound"]),

        // Tools (additional)
        .init(symbol: "screwdriver.fill",       label: "Screwdriver", keywords: ["screwdriver", "tool"]),
        .init(symbol: "wrench.adjustable.fill", label: "Wrench",      keywords: ["wrench", "spanner", "tool"]),
        .init(symbol: "ruler",                  label: "Ruler",       keywords: ["ruler", "measure"]),
        .init(symbol: "gearshape.fill",         label: "Settings",    keywords: ["gear", "settings", "config"]),

        // Vehicles (additional)
        .init(symbol: "scooter",                label: "Scooter",     keywords: ["scooter", "moped"]),
        .init(symbol: "motorcycle",             label: "Motorcycle",  keywords: ["motorcycle", "bike"]),
        .init(symbol: "train.side.front.car",   label: "Train",       keywords: ["train", "rail"]),
        .init(symbol: "tram.fill",              label: "Tram",        keywords: ["tram", "trolley", "transit"]),
        .init(symbol: "truck.box.fill",         label: "Truck",       keywords: ["truck", "moving", "haul"]),

        // Pets (additional)
        .init(symbol: "dog.fill",               label: "Dog",         keywords: ["dog", "pet", "puppy"]),
        .init(symbol: "cat.fill",               label: "Cat",         keywords: ["cat", "pet", "kitten"]),
        .init(symbol: "bird.fill",              label: "Bird",        keywords: ["bird", "pet"]),
        .init(symbol: "tortoise.fill",          label: "Tortoise",    keywords: ["tortoise", "turtle", "reptile"]),

        // Food / kitchen (additional)
        .init(symbol: "mug.fill",               label: "Mug",         keywords: ["mug", "drink", "tea"]),
        .init(symbol: "popcorn.fill",           label: "Snacks",      keywords: ["popcorn", "snack"]),
        .init(symbol: "oven.fill",              label: "Oven",        keywords: ["oven", "kitchen", "bake", "baked", "bakery"]),
        .init(symbol: "refrigerator.fill",      label: "Fridge",      keywords: ["fridge", "refrigerator", "kitchen"]),
        .init(symbol: "takeoutbag.and.cup.and.straw.fill", label: "Takeout", keywords: ["takeout", "fast food", "to go"]),

        // Communication
        .init(symbol: "phone.fill",             label: "Phone call",  keywords: ["phone", "call"]),
        .init(symbol: "message.fill",           label: "Message",     keywords: ["message", "text", "chat"]),
        .init(symbol: "video.fill",             label: "Video",       keywords: ["video", "call"]),

        // Tech (additional)
        .init(symbol: "tv.fill",                label: "TV",          keywords: ["tv", "television"]),
        .init(symbol: "wifi",                   label: "Wi-Fi",       keywords: ["wifi", "network"]),
        .init(symbol: "photo.fill",             label: "Photo",       keywords: ["photo", "picture", "image"]),
        .init(symbol: "applewatch",             label: "Watch",       keywords: ["watch", "wearable"]),

        // Misc / fun
        .init(symbol: "gift.fill",              label: "Gift",        keywords: ["gift", "present"]),
        .init(symbol: "cart.fill",              label: "Cart",        keywords: ["cart", "shopping", "groceries"]),
        .init(symbol: "house.fill",             label: "Home",        keywords: ["house", "home"]),
        .init(symbol: "building.fill",          label: "Building",    keywords: ["building", "office"]),
        .init(symbol: "building.2.fill",        label: "City",        keywords: ["city", "buildings", "urban"]),
        .init(symbol: "trophy.fill",            label: "Trophy",      keywords: ["trophy", "award", "win"]),
        .init(symbol: "star.fill",              label: "Star",        keywords: ["star", "favorite"]),
        .init(symbol: "crown.fill",             label: "Crown",       keywords: ["crown", "premium", "royalty"]),
        .init(symbol: "flag.fill",              label: "Flag",        keywords: ["flag", "milestone"]),
        .init(symbol: "party.popper.fill",      label: "Party",       keywords: ["party", "celebration", "festival"]),
        .init(symbol: "balloon.2.fill",         label: "Balloons",    keywords: ["balloons", "party", "kids"]),

        // Generic
        .init(symbol: "square.grid.2x2.fill",   label: "Generic",     keywords: ["generic", "default", "grid"]),
        .init(symbol: "tag.fill",               label: "Tag",         keywords: ["tag", "label"]),
        .init(symbol: "ellipsis.circle.fill",   label: "Misc",        keywords: ["misc", "other"]),
    ]

    static func search(_ query: String) -> [Entry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return entries }
        return entries.filter { entry in
            entry.symbol.lowercased().contains(q) ||
            entry.label.lowercased().contains(q) ||
            entry.keywords.contains { $0.contains(q) }
        }
    }
}

extension CategoryColor {
    var color: Color {
        switch self {
        case .blue: .blue
        case .teal: Color.packitTeal
        case .cyan: .cyan
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .brown: .brown
        case .gray: .gray
        }
    }

    var label: String {
        switch self {
        case .blue: "Blue"
        case .teal: "Teal"
        case .cyan: "Cyan"
        case .indigo: "Indigo"
        case .purple: "Purple"
        case .pink: "Pink"
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green: "Green"
        case .mint: "Mint"
        case .brown: "Brown"
        case .gray: "Gray"
        }
    }
}
