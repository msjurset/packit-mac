import Foundation

public enum TripIcon: String, Codable, CaseIterable, Identifiable, Sendable {
    // Existing (preserved raw values for backward compat)
    case suitcase
    case beach
    case mountain
    case city
    case camping
    case tropical
    case snow
    case road
    case cruise
    case fishing
    case hiking
    case resort
    case international
    case family
    case adventure
    case food

    // New — general & purpose
    case backpack
    case map
    case business
    case photo
    case festival
    case concert
    case couple
    case solo
    case pets

    // New — water
    case ocean
    case lake
    case sailing
    case surfing
    case pool

    // New — nature
    case forest
    case desert

    // New — winter
    case skiing
    case snowboard
    case iceSkating

    // New — activity
    case climbing
    case biking
    case running
    case golf

    // New — urban / hospitality
    case landmark
    case hotel
    case coffee

    // New — travel
    case airplane
    case train
    case rv

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .suitcase: "suitcase.fill"
        case .beach: "beach.umbrella"
        case .mountain: "mountain.2.fill"
        case .city: "building.2.fill"
        case .camping: "tent.fill"
        case .tropical: "leaf.fill"
        case .snow: "snowflake"
        case .road: "car.fill"
        case .cruise: "ferry.fill"
        case .fishing: "fish.fill"
        case .hiking: "figure.hiking"
        case .resort: "wineglass.fill"
        case .international: "globe.americas.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .adventure: "binoculars.fill"
        case .food: "fork.knife"
        case .backpack: "backpack.fill"
        case .map: "map.fill"
        case .business: "briefcase.fill"
        case .photo: "camera.fill"
        case .festival: "party.popper.fill"
        case .concert: "music.note"
        case .couple: "figure.2.arms.open"
        case .solo: "figure.stand"
        case .pets: "pawprint.fill"
        case .ocean: "water.waves"
        case .lake: "drop.fill"
        case .sailing: "sailboat.fill"
        case .surfing: "figure.surfing"
        case .pool: "figure.pool.swim"
        case .forest: "tree.fill"
        case .desert: "sun.haze.fill"
        case .skiing: "figure.skiing.downhill"
        case .snowboard: "figure.snowboarding"
        case .iceSkating: "figure.skating"
        case .climbing: "figure.climbing"
        case .biking: "bicycle"
        case .running: "figure.run"
        case .golf: "figure.golf"
        case .landmark: "building.columns.fill"
        case .hotel: "bed.double.fill"
        case .coffee: "cup.and.saucer.fill"
        case .airplane: "airplane"
        case .train: "train.side.front.car"
        case .rv: "bus.fill"
        }
    }

    public var label: String {
        switch self {
        case .suitcase: "General"
        case .beach: "Beach"
        case .mountain: "Mountain"
        case .city: "City"
        case .camping: "Camping"
        case .tropical: "Tropical"
        case .snow: "Winter"
        case .road: "Road Trip"
        case .cruise: "Cruise"
        case .fishing: "Fishing"
        case .hiking: "Hiking"
        case .resort: "Resort"
        case .international: "International"
        case .family: "Family"
        case .adventure: "Adventure"
        case .food: "Food & Wine"
        case .backpack: "Backpack"
        case .map: "Exploring"
        case .business: "Business"
        case .photo: "Photo Trip"
        case .festival: "Festival"
        case .concert: "Concert"
        case .couple: "Couple"
        case .solo: "Solo"
        case .pets: "With Pets"
        case .ocean: "Ocean"
        case .lake: "Lake"
        case .sailing: "Sailing"
        case .surfing: "Surfing"
        case .pool: "Pool"
        case .forest: "Forest"
        case .desert: "Desert"
        case .skiing: "Skiing"
        case .snowboard: "Snowboard"
        case .iceSkating: "Ice Skating"
        case .climbing: "Climbing"
        case .biking: "Biking"
        case .running: "Running"
        case .golf: "Golf"
        case .landmark: "Landmark"
        case .hotel: "Hotel"
        case .coffee: "Café"
        case .airplane: "Flight"
        case .train: "Train"
        case .rv: "RV"
        }
    }

    public var searchKeywords: [String] {
        switch self {
        case .suitcase: ["general", "trip", "travel"]
        case .beach: ["beach", "ocean", "sea", "sand"]
        case .mountain: ["mountain", "peak", "alps", "summit"]
        case .city: ["city", "urban", "downtown"]
        case .camping: ["camping", "tent", "outdoors"]
        case .tropical: ["tropical", "palm", "island", "jungle"]
        case .snow: ["snow", "winter", "cold"]
        case .road: ["road trip", "drive", "car"]
        case .cruise: ["cruise", "ferry", "ship"]
        case .fishing: ["fishing", "fish"]
        case .hiking: ["hike", "hiking", "trail", "walk"]
        case .resort: ["resort", "spa", "relax"]
        case .international: ["international", "global", "world", "abroad"]
        case .family: ["family", "kids", "children"]
        case .adventure: ["adventure", "exploring", "binoculars"]
        case .food: ["food", "wine", "dining", "restaurant"]
        case .backpack: ["backpack", "backpacking", "hostel"]
        case .map: ["map", "exploring", "navigation"]
        case .business: ["business", "work", "conference"]
        case .photo: ["photo", "photography", "camera"]
        case .festival: ["festival", "party", "carnival"]
        case .concert: ["concert", "music", "show", "tour"]
        case .couple: ["couple", "romantic", "honeymoon", "anniversary"]
        case .solo: ["solo", "retreat", "me time"]
        case .pets: ["pets", "dog", "cat", "animal"]
        case .ocean: ["ocean", "sea", "water", "waves"]
        case .lake: ["lake", "pond", "water"]
        case .sailing: ["sailing", "boat", "yacht"]
        case .surfing: ["surfing", "surf", "waves"]
        case .pool: ["pool", "swimming", "swim"]
        case .forest: ["forest", "trees", "woods", "nature"]
        case .desert: ["desert", "dunes", "sand"]
        case .skiing: ["skiing", "ski", "slopes"]
        case .snowboard: ["snowboard", "boarding"]
        case .iceSkating: ["ice skating", "skate", "rink"]
        case .climbing: ["climbing", "climb", "bouldering"]
        case .biking: ["biking", "cycling", "bike"]
        case .running: ["running", "marathon", "race"]
        case .golf: ["golf", "golfing"]
        case .landmark: ["landmark", "monument", "museum", "historic"]
        case .hotel: ["hotel", "stay", "lodging"]
        case .coffee: ["coffee", "cafe", "café"]
        case .airplane: ["flight", "fly", "airplane", "plane"]
        case .train: ["train", "rail"]
        case .rv: ["rv", "camper", "caravan", "motorhome"]
        }
    }

    public func matches(query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return true }
        if label.lowercased().contains(trimmed) { return true }
        return searchKeywords.contains { $0.contains(trimmed) }
    }
}
