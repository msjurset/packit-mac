#!/usr/bin/env swift

import Foundation

// MARK: - Codable Models (matching app models)

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
    var quantity: Int
}

struct PrepTaskTemplate: Codable {
    var id: UUID
    var name: String
    var category: String?
    var timing: String
    var contextTags: [String]
    var notes: String?
}

struct PackingTemplate: Codable {
    var id: UUID
    var name: String
    var items: [TemplateItem]
    var prepTasks: [PrepTaskTemplate]
    var linkedTemplateIDs: [UUID]
    var contextTags: [String]
    var createdAt: Date
    var updatedAt: Date
}

struct ContextTag: Codable {
    var id: UUID
    var name: String
    var color: String?
}

func item(_ name: String, cat: String? = nil, tags: [String] = [], priority: String = "medium", notes: String? = nil, qty: Int = 1) -> TemplateItem {
    TemplateItem(id: UUID(), name: name, category: cat, contextTags: tags, priority: priority, notes: notes, quantity: qty)
}

func prep(_ name: String, cat: String? = nil, timing: String = "daysBefore", tags: [String] = [], notes: String? = nil) -> PrepTaskTemplate {
    PrepTaskTemplate(id: UUID(), name: name, category: cat, timing: timing, contextTags: tags, notes: notes)
}

func template(_ name: String, items: [TemplateItem], prepTasks: [PrepTaskTemplate] = [], linked: [UUID] = [], tags: [String] = []) -> PackingTemplate {
    PackingTemplate(id: UUID(), name: name, items: items, prepTasks: prepTasks, linkedTemplateIDs: linked, contextTags: tags, createdAt: .now, updatedAt: .now)
}

// MARK: - Build Templates

// 1. Kitchen
let kitchen = template("Kitchen", items: [
    item("Soap", cat: "Cleaning"), item("Wash bin", cat: "Cleaning"),
    item("Wash cloth, sponge, kitchen towels, dish towels", cat: "Cleaning"),
    item("Cleaner, disinfectant, windex", cat: "Cleaning"),
    item("Table cloth and table clips", cat: "Cleaning"),
    item("Lighter, flint", cat: "Fire & Cooking"), item("Fire starters", cat: "Fire & Cooking"),
    item("Dishes, cups, tupperware, silverware", cat: "Dining"),
    item("Spatula, turner, fork, large knife, large spoon, tongs", cat: "Utensils"),
    item("Bar supplies: wine opener, shaker, shot glasses, stir sticks, napkins", cat: "Bar"),
    item("Cutting board", cat: "Utensils"), item("Tray", cat: "Utensils"),
    item("Cast iron pan, pot, carrier, washer, fire stand, fire glove", cat: "Fire & Cooking"),
    item("Kettle", cat: "Fire & Cooking"), item("Ice maker", cat: "Appliances"),
    item("Crock pot", cat: "Appliances", notes: "Optional"),
    item("Coffee maker, frother", cat: "Appliances"),
    item("Mugs, water glasses, coozies", cat: "Dining"),
    item("Paper/plastic plates, cups, utensils, straws", cat: "Dining"),
    item("Garbage pop-up bin, bags, grease bags", cat: "Cleaning"),
    item("Zip locks", cat: "Storage"),
    item("Tin foil, plastic wrap, parchment, napkins, paper towels", cat: "Storage"),
    item("Spice rack", cat: "Pantry", notes: "salt, pepper, onion, garlic, rosemary, unicorn, cinnamon, red pepper"),
    item("Wine/bottle carrier", cat: "Bar"),
    item("Can opener", cat: "Utensils"), item("Cook pot set", cat: "Fire & Cooking"),
    item("Extra water jug", cat: "Hydration"),
    item("Cooler", cat: "Storage", notes: "Bev cooler and food/produce bin"),
    item("Grill cover", cat: "Fire & Cooking"),
    item("Propane tanks", cat: "Fire & Cooking", priority: "high"),
    item("Egg and bread containers", cat: "Storage"),
    item("Peeler, zester, grater", cat: "Utensils"),
    item("Measuring cups dry and liquid", cat: "Utensils"),
    item("Popcorn maker", cat: "Appliances"), item("Pot holders", cat: "Fire & Cooking"),
    item("Thermos", cat: "Hydration"), item("Meat thermometer", cat: "Fire & Cooking"),
], tags: ["camping", "rv"])

// 2. Pantry
let pantry = template("Pantry & Groceries", items: [
    item("Spices", cat: "Staples", notes: "salt, pepper, onion, garlic, unicorn, cinnamon, rosemary"),
    item("Bread, buns, bagels, tortillas/wraps", cat: "Bakery"),
    item("Oil, spray oil", cat: "Staples"), item("Sugar, brown sugar", cat: "Staples"),
    item("Honey", cat: "Staples"), item("Rice", cat: "Staples"),
    item("Oatmeal", cat: "Staples"),
    item("Crackers, soda crackers", cat: "Snacks"), item("Chips, tortillas", cat: "Snacks"),
    item("Granola, gorp, nuts", cat: "Snacks"), item("Eggs", cat: "Dairy & Protein"),
    item("Mustard, ketchup, BBQ, ranch, hot sauce", cat: "Condiments"),
    item("Cream cheese", cat: "Dairy & Protein"), item("Hummus packs", cat: "Snacks"),
    item("Butter, spray butter", cat: "Dairy & Protein"),
    item("Peanut butter", cat: "Staples"), item("Mac and cheese", cat: "Staples"),
    item("Popcorn, oil, salt", cat: "Snacks"),
    item("Protein bars", cat: "Snacks"), item("Milk, creamer, shelf-stable milk", cat: "Dairy & Protein"),
    item("Salsa", cat: "Condiments"), item("Lemons, limes, orange", cat: "Produce"),
    item("Ginger chews and gum", cat: "Snacks"),
    item("Tuna or chicken pouches", cat: "Dairy & Protein"), item("Jelly", cat: "Condiments"),
], tags: ["camping", "rv"])

// 3. Dog's Stuff
let cosmo = template("Dog's Stuff", items: [
    item("Bed, pillow, blankets, rug", cat: "Bedding"),
    item("Hammock and/or kennel", cat: "Containment"),
    item("Tie out, hook up", cat: "Containment"),
    item("Jacket, shoes, scarves", cat: "Clothing"),
    item("Towel, shower, paw washer", cat: "Grooming"),
    item("Leash, gentle leader", cat: "Walking", priority: "high"),
    item("Poop bags and hook", cat: "Walking", priority: "high"),
    item("Stuffed animal, water toy, treat ball, floaty", cat: "Toys"),
    item("Pills, heartworm, tick meds", cat: "Medical", priority: "critical", notes: "ear wipes, bennadryl, anti nausea, diarrhea, anxiety"),
    item("Food, treats, bone, frozen toys", cat: "Food", priority: "high", notes: "PB, 4 days, bring canned chicken/salmon, boil rice bag"),
    item("Water dish, food dish, hiking bowls, squeeze water bottle", cat: "Food"),
    item("Vet info, destination vet info", cat: "Documents"),
    item("Brush, nail clipper, shampoo", cat: "Grooming"),
    item("Life jacket", cat: "Water", notes: "Depends on trip"),
], prepTasks: [
    prep("Double check dog food/treats, meds, vaccines, wash dog and blankets", cat: "Pets", timing: "weeksBefore"),
], tags: ["pets"])

// 4. Camp/Living
let campLiving = template("Camp & Living", items: [
    item("Side tent", cat: "Shelter"), item("Poles and awning, ropes", cat: "Shelter"),
    item("Ropes, gear line, carabiners", cat: "Gear"), item("Twinkle lights, lanterns", cat: "Lighting"),
    item("Chairs", cat: "Furniture"), item("Table(s)", cat: "Furniture"),
    item("Camp rug(s) and floor", cat: "Furniture"), item("Step stool", cat: "Furniture"),
    item("Candles, bug spray", cat: "Comfort"),
    item("Electronic chargers and cords, battery packs", cat: "Electronics"),
    item("Portable speaker", cat: "Electronics"),
    item("Fire stand, fire glove, starters, stoker, marshmallow sticks", cat: "Fire"),
    item("Fire extinguisher", cat: "Safety", priority: "high"),
    item("Flashlight, headlamps", cat: "Lighting"),
    item("Dust pan and brush, car duster, small windex", cat: "Cleaning"),
    item("Hammocks, hook ups", cat: "Comfort"),
    item("Hatchet, axe, knife, mallet", cat: "Tools"),
    item("Stakes", cat: "Shelter"), item("Padlock for campground food bins", cat: "Safety"),
    item("Stove wind guard", cat: "Fire"),
], tags: ["camping"])

// 5. Bed/Bath
let bedBath = template("Bed & Bath", items: [
    item("Sheets, comforter, throw blankets, pillows, wedges, throw pillow", cat: "Bedding"),
    item("Toilet, bags", cat: "Bathroom"), item("Bathroom kit: toilet paper, wipes", cat: "Bathroom"),
    item("Shower floor mat", cat: "Bathroom"),
    item("Hanging organizer", cat: "Bathroom"), item("Towels", cat: "Bath"),
    item("Shower shoes", cat: "Bath"), item("Mirror", cat: "Bath"),
    item("Hair towels", cat: "Bath"),
    item("Laundry kit: basket/bag, soap, tide stick, freshener spray, dryer sheets", cat: "Laundry"),
], tags: ["camping", "rv"])

// 6. RV/Auto
let rvAuto = template("RV & Auto", items: [
    item("Jumper cables", cat: "Emergency"), item("Tools, jack, hitch, chains, leather gloves", cat: "Tools"),
    item("Map(s)", cat: "Navigation"), item("Dramamine, ear plugs, wipes, extra masks", cat: "Travel Comfort"),
    item("Travel pillow", cat: "Travel Comfort"), item("Window shade", cat: "Travel Comfort"),
    item("Toll money", cat: "Documents"), item("Surge protector", cat: "Electrical"),
    item("Water hose and pressure valve", cat: "Water System"),
    item("Sanitize and fill water tanks", cat: "Water System"),
    item("Leveling blocks/chucks", cat: "Setup"),
    item("Extension cords", cat: "Electrical"),
    item("Battery", cat: "Electrical"),
    item("TV antenna and cable hook ups, cords, Google TV", cat: "Entertainment"),
    item("Wifi booster", cat: "Electronics"),
    item("Duct tape, RV tape, gorilla glue", cat: "Repair"),
    item("Propane", cat: "Fuel"), item("Air pump", cat: "Tools"),
    item("Padlocks, keys", cat: "Security"), item("Camper keys", cat: "Security", priority: "critical"),
    item("Extra fuses", cat: "Electrical"), item("Cell phone chargers", cat: "Electronics"),
    item("Extra bungees, zip ties, straps", cat: "Gear"),
    item("Clipboard, paper, pen", cat: "Misc"),
    item("Mini humidifier", cat: "Comfort"),
    item("Dryer sheets in camper", cat: "Pest Control", notes: "For mice deterrent"),
], tags: ["rv", "road-trip"])

// 7. Activities/Sport Items
let activities = template("Activities & Sports", items: [
    // Leisure/Electronics
    item("Books & audio for road trip", cat: "Leisure"), item("Movies/downloads", cat: "Leisure"),
    item("Board games, cards, camp game", cat: "Leisure"),
    item("Polaroid, binoculars", cat: "Leisure"), item("Floats/noodle", cat: "Water"),
    item("Dot to dot, coloring, water colors", cat: "Leisure"), item("Journal", cat: "Leisure"),
    item("Google TV", cat: "Electronics"),
    // Hiking
    item("Hiking poles", cat: "Hiking", tags: ["hiking"]),
    item("Backpacks or hipsack", cat: "Hiking", tags: ["hiking"]),
    item("First aid", cat: "Hiking", tags: ["hiking"]),
    item("Pads/towels", cat: "Hiking", tags: ["hiking"]),
    item("Boots, sandals, socks, hats, poncho", cat: "Hiking", tags: ["hiking"]),
    item("Pocket knife", cat: "Hiking", tags: ["hiking"]),
    item("Bear spray & bell", cat: "Hiking", tags: ["hiking", "backcountry"], priority: "high"),
    item("Sun hat", cat: "Hiking", tags: ["hiking"]),
    // Fishing
    item("Poles/rods/reels", cat: "Fishing", tags: ["fishing"]),
    item("Bait and tackle, line", cat: "Fishing", tags: ["fishing"]),
    item("Pliers, nail clipper", cat: "Fishing", tags: ["fishing"]),
    item("Kayaks", cat: "Fishing", tags: ["fishing", "water"]),
    item("Paddles", cat: "Fishing", tags: ["fishing", "water"]),
    item("Life jackets", cat: "Fishing", tags: ["fishing", "water"], priority: "high"),
    item("Paddle cords", cat: "Fishing", tags: ["fishing", "water"]),
    // Beach
    item("Beach umbrella", cat: "Beach", tags: ["beach"]),
    item("Cart", cat: "Beach", tags: ["beach"]),
    item("Beach fishing tackle, rod holders", cat: "Beach", tags: ["beach", "fishing"]),
    item("Garbage bags", cat: "Beach", tags: ["beach"]),
    item("Extra foldable cooler, kayak bag", cat: "Beach", tags: ["beach"]),
    item("Beach chairs or large mat/towel", cat: "Beach", tags: ["beach"]),
    item("Beach towels", cat: "Beach", tags: ["beach"]),
    item("Dry sack and cooler, water jug/bottle", cat: "Beach", tags: ["beach"]),
    item("Sun hat, neck gator, hand gators, boat shoes, hair ties", cat: "Beach", tags: ["beach"]),
], tags: ["camping", "rv"])

// 8. Clothes - Alice
let clothesAlice = template("Clothes - Alice", items: [
    item("PJs", cat: "Sleepwear"), item("Underwear, bras, socks", cat: "Undergarments"),
    item("Tank tops", cat: "Tops", notes: "1 dress, 3 day, 3-4 exercise"),
    item("T-shirts (short, long)", cat: "Tops", notes: "2 exercise, 4-5 day, 1 cozy"),
    item("Sweatshirts, sweaters", cat: "Layers"), item("Sweat pants, hiking pants, capris", cat: "Bottoms"),
    item("Dress, jumpsuits", cat: "Dressy"), item("Skirts, skorts", cat: "Bottoms"),
    item("Shorts", cat: "Bottoms"),
    item("Jackets, rainwear, poncho", cat: "Outerwear"),
    item("Scarf/gator, gloves, cold and hot weather hats", cat: "Accessories"),
    item("Rash guards, gators", cat: "Active"),
    item("Swim suits, cover ups", cat: "Swim"),
    item("Sandals and water sandals, shower shoes", cat: "Footwear"),
    item("Boots/hiking shoes", cat: "Footwear"), item("Slippers/socks", cat: "Footwear"),
    item("Belt", cat: "Accessories"),
    item("Headbands and pony holders", cat: "Accessories"),
    item("Purse (cross over, large), extra tote", cat: "Bags"),
    item("Jewelry", cat: "Accessories"),
])

// 9. Clothes - Bob
let clothesBob = template("Clothes - Bob", items: [
    item("PJs", cat: "Sleepwear"), item("Underwear, socks", cat: "Undergarments"),
    item("Tank tops", cat: "Tops"), item("T-shirts (short, long)", cat: "Tops"),
    item("Sweatshirts, sweaters", cat: "Layers"), item("Sweat pants, hiking pants", cat: "Bottoms"),
    item("Shorts", cat: "Bottoms"), item("Jackets, rainwear", cat: "Outerwear"),
    item("Scarf, gloves, cold and hot weather hats", cat: "Accessories"),
    item("Rash guards, gators", cat: "Active"), item("Swim suits", cat: "Swim"),
    item("Sandals and water sandals", cat: "Footwear"),
    item("Boots/hiking shoes", cat: "Footwear"), item("Slippers/socks", cat: "Footwear"),
    item("Belt", cat: "Accessories"),
])

// 10. Toiletries - Alice
let toiletriesAlice = template("Toiletries - Alice", items: [
    item("Toothpaste, brush, floss(ers)", cat: "Dental"), item("Face wash", cat: "Face"),
    item("Make up remover", cat: "Face"),
    item("Wash cloths, hair towels, loofa, face brush", cat: "Bath"),
    item("Shampoo, conditioner(s)", cat: "Hair"), item("Razor, creams", cat: "Body"),
    item("Body soap", cat: "Body"), item("Pumice", cat: "Body"),
    item("Body lotion", cat: "Body"), item("Deodorant", cat: "Body"),
    item("Q tips, cotton swabs", cat: "Body"), item("Body spray", cat: "Body"),
    item("Foot lotion (honey)", cat: "Body"),
    item("Curl cream, gel, volume", cat: "Hair"), item("Hairspray", cat: "Hair"),
    item("Comb", cat: "Hair"), item("Hair dryer, diffuser", cat: "Hair"),
    item("Mirror", cat: "Face"),
    item("Manicure kit: clippers, file, brush, remover, cotton, clear, 2 colors", cat: "Nails"),
    item("Eye cream, serum", cat: "Face"), item("Eye patch treatment", cat: "Face"),
    item("Face lotion, serum", cat: "Face"), item("Exfoliation", cat: "Face"),
    item("Face brush", cat: "Face"),
    item("Concealer and contour", cat: "Makeup"), item("Base primer", cat: "Makeup"),
    item("Sunscreen", cat: "Sun", priority: "high"), item("Foundation", cat: "Makeup"),
    item("Powder", cat: "Makeup"), item("Highlighter, blush, bronzer", cat: "Makeup"),
    item("Face brushes", cat: "Makeup"), item("Eye brushes", cat: "Makeup"),
    item("Sponges", cat: "Makeup"),
    item("Eye shadow, liner, mascara, eye brow shadow", cat: "Makeup"),
    item("Chapstick, lip gloss", cat: "Makeup"), item("Setting spray, ALOE", cat: "Makeup"),
    item("Burt bees acne", cat: "Face"),
    item("Sunglasses and reading glasses, cleaners", cat: "Eyewear", priority: "high"),
])

// 11. Toiletries - Bob
let toiletriesBob = template("Toiletries - Bob", items: [
    item("Medications", cat: "Medical"), item("Deodorant", cat: "Body"),
    item("Lotion", cat: "Body"), item("Nail clipper", cat: "Body"),
    item("Face wash", cat: "Face"), item("Lip balm", cat: "Body"),
    item("Body wash", cat: "Body"), item("Allergy meds", cat: "Medical"),
    item("Toothpaste, floss, brush", cat: "Dental"),
    item("Razors, trimmer", cat: "Body"), item("Vitamins", cat: "Medical"),
])

// 12. First Aid & NQR Kit
let firstAid = template("First Aid & NQR Kit", items: [
    item("Aleve, Tylenol", cat: "Pain"), item("Imodium, Pepto", cat: "Digestive"),
    item("Claratin, Benadryl", cat: "Allergy"),
    item("Vitamins: Mag, D+K, B complex, probiotic, C, turmeric", cat: "Vitamins"),
    item("Dramamine", cat: "Motion"), item("Ginger", cat: "Motion"),
    item("Thermometer", cat: "Tools"), item("Ice pack", cat: "Tools"),
    item("Cooling strips", cat: "Tools"),
    item("Muscle spray, cream", cat: "Pain"),
    item("Massage hook, head scraper, tension bands, massage tool", cat: "Wellness"),
    item("Aroma therapy oil, lotion, spray", cat: "Wellness"),
    item("Alcohol wipes, rubbing alcohol", cat: "First Aid"),
    item("Band aids and wrap", cat: "First Aid"),
    item("Cold meds", cat: "Cold & Flu"),
    item("A's prescriptions and vitamins", cat: "Prescription"),
    item("B's vitamins", cat: "Prescription"),
    item("Bug bite relief", cat: "Outdoor"), item("Sunburn", cat: "Outdoor"),
    item("Ear plugs", cat: "Sleep"), item("Sleep mask", cat: "Sleep"),
    item("Breathe right strips", cat: "Sleep"),
    item("Hydrogen peroxide", cat: "First Aid"),
    item("PPE: masks, gloves, sanitizer, wipes", cat: "Safety"),
    item("Hot/cold water bottle or pads", cat: "Pain"),
])

// 13. Prep Tasks Template (shared across RV trips)
let rvPrepTasks = template("RV Trip Prep Tasks", items: [], prepTasks: [
    prep("Wash car, oil change, fill gas, check tires, vacuum, remove extras", cat: "Vehicle", timing: "weeksBefore"),
    prep("Order meds and pickup", cat: "Medical", timing: "weeksBefore"),
    prep("Haircut/color, pedicure, dentist/dr appt", cat: "Personal", timing: "weeksBefore"),
    prep("Grocery/meal plan, check inventory", cat: "Supplies", timing: "weeksBefore", notes: "coffee, paper items, toiletries, sun lotion, water, alcohol, batteries, ppe"),
    prep("Schedule landscaping", cat: "Home", timing: "weeksBefore"),
    prep("Plan routes, confirm reservations and pet policies, check 10-day weather", cat: "Travel", timing: "weekBefore"),
    prep("Stop mail", cat: "Home", timing: "weekBefore"),
    prep("Pay bills (gas, electric, utilities)", cat: "Financial", timing: "weekBefore"),
    prep("Out-of-Office email/notifications, vacation work dates", cat: "Work", timing: "weekBefore"),
    prep("Straighten up house, make bed, dishes, wash clothes", cat: "Home", timing: "daysBefore"),
    prep("Double check sprinklers", cat: "Home", timing: "daysBefore"),
    prep("Water indoor and outdoor plants, group containers, hummingbird/bird food", cat: "Home", timing: "daysBefore"),
    prep("Charge electronics", cat: "Supplies", timing: "daysBefore"),
    prep("Fill RV water and double check", cat: "RV", timing: "daysBefore"),
    prep("Empty fridge, garbage", cat: "Home", timing: "daysBefore"),
    prep("Set lights/porch", cat: "Home", timing: "daysBefore"),
    prep("Vaccine card, passport", cat: "Documents", timing: "daysBefore"),
    prep("Set travel info on bank account", cat: "Financial", timing: "daysBefore"),
    prep("Make extra ice for travel days", cat: "Supplies", timing: "dayOf"),
    prep("ATM - get cash", cat: "Financial", timing: "dayOf"),
    prep("Fishing/hunting licenses", cat: "Documents", timing: "weekBefore"),
    prep("Park passes and Nat'l America the Beautiful pass", cat: "Documents", timing: "weekBefore"),
    prep("Turn off RV electronics and hook up tail lights", cat: "RV", timing: "dayOf"),
    prep("Double check RV hitch and chains", cat: "RV", timing: "dayOf"),
    prep("Check car and RV tire levels", cat: "Vehicle", timing: "dayOf"),
    prep("Insert sponges in cowbell vents", cat: "RV", timing: "dayOf", notes: "TAKE OUT when camping"),
], tags: ["rv", "camping", "road-trip"])

// Build composite templates
let summerRV = PackingTemplate(
    id: UUID(), name: "Summer RV Roadtrip",
    items: [], prepTasks: [],
    linkedTemplateIDs: [kitchen.id, pantry.id, cosmo.id, campLiving.id, bedBath.id, rvAuto.id, activities.id, clothesAlice.id, clothesBob.id, toiletriesAlice.id, toiletriesBob.id, firstAid.id, rvPrepTasks.id],
    contextTags: ["rv", "camping", "road-trip", "summer"],
    createdAt: .now, updatedAt: .now
)

let allTemplates = [kitchen, pantry, cosmo, campLiving, bedBath, rvAuto, activities, clothesAlice, clothesBob, toiletriesAlice, toiletriesBob, firstAid, rvPrepTasks, summerRV]

// MARK: - Tags

let tagNames = ["camping", "rv", "road-trip", "summer", "hiking", "fishing", "beach", "backcountry", "water", "pets"]
let tags = tagNames.map { ContextTag(id: UUID(), name: $0, color: nil) }

// MARK: - Save

let baseDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".packit")
let templatesDir = baseDir.appendingPathComponent("templates")
let tagsURL = baseDir.appendingPathComponent("tags.json")

try FileManager.default.createDirectory(at: templatesDir, withIntermediateDirectories: true)

for tmpl in allTemplates {
    let data = try encoder.encode(tmpl)
    let url = templatesDir.appendingPathComponent("\(tmpl.id.uuidString).json")
    try data.write(to: url)
    let itemCount = tmpl.items.count
    let prepCount = tmpl.prepTasks.count
    let linkedCount = tmpl.linkedTemplateIDs.count
    var desc = "\(itemCount) items"
    if prepCount > 0 { desc += ", \(prepCount) prep tasks" }
    if linkedCount > 0 { desc += ", links \(linkedCount) templates" }
    print("  Created: \(tmpl.name) (\(desc))")
}

// Merge tags with existing
var existingTags: [ContextTag] = []
if let data = try? Data(contentsOf: tagsURL) {
    existingTags = (try? JSONDecoder().decode([ContextTag].self, from: data)) ?? []
}
let existingNames = Set(existingTags.map { $0.name.lowercased() })
let newTags = tags.filter { !existingNames.contains($0.name.lowercased()) }
let mergedTags = existingTags + newTags
try encoder.encode(mergedTags).write(to: tagsURL)

print("")
print("Seeded \(allTemplates.count) templates (\(allTemplates.reduce(0) { $0 + $1.items.count }) total items, \(allTemplates.reduce(0) { $0 + $1.prepTasks.count }) prep tasks)")
print("Added \(newTags.count) new tags (total: \(mergedTags.count))")
print("Composite 'Summer RV Roadtrip' links \(summerRV.linkedTemplateIDs.count) templates")
