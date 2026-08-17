import SwiftUI
import PackItKit

/// Curated SF Symbols and Emojis suitable for meal plan slots, with searchable keywords.
enum FoodIconLibrary {
    struct Entry: Identifiable, Hashable {
        let symbol: String
        let label: String
        let keywords: [String]
        var id: String { symbol }
    }

    static let entries: [Entry] = [
        // MARK: - Main Dishes & Global Cuisine
        .init(symbol: "fork.knife",             label: "Dining",      keywords: ["eat", "dining", "utensils"]),
        .init(symbol: "fork.knife.circle.fill", label: "Meal",        keywords: ["food", "meal"]),
        .init(symbol: "takeoutbag.and.cup.and.straw.fill", label: "Takeout", keywords: ["takeout", "fast food", "bag"]),
        .init(symbol: "frying.pan.fill",        label: "Cooking",     keywords: ["cook", "pan", "kitchen"]),
        .init(symbol: "🍕",                      label: "Pizza",       keywords: ["pizza", "italian", "slice", "cheese"]),
        .init(symbol: "🍔",                      label: "Burger",      keywords: ["burger", "hamburger", "beef", "sandwich"]),
        .init(symbol: "🥪",                      label: "Sandwich",    keywords: ["sandwich", "lunch", "sub", "hoagie"]),
        .init(symbol: "🌭",                      label: "Hot Dog",     keywords: ["hotdog", "frank", "sausage"]),
        .init(symbol: "🥩",                      label: "Steak",       keywords: ["steak", "beef", "meat", "grill"]),
        .init(symbol: "🍗",                      label: "Poultry",     keywords: ["chicken", "turkey", "poultry", "drumstick"]),
        .init(symbol: "🥓",                      label: "Bacon",       keywords: ["bacon", "pork", "breakfast"]),
        .init(symbol: "🍖",                      label: "Ribs",        keywords: ["ribs", "meat", "bbq"]),
        .init(symbol: "🍖",                      label: "Meat on Bone", keywords: ["meat", "protein"]),
        .init(symbol: "🥘",                      label: "Paella",      keywords: ["paella", "skillet", "pan", "stew"]),
        .init(symbol: "🍲",                      label: "Stew",        keywords: ["stew", "soup", "pot"]),
        .init(symbol: "🥣",                      label: "Bowl",        keywords: ["bowl", "soup", "cereal"]),
        .init(symbol: "🥗",                      label: "Salad Bowl",  keywords: ["salad", "healthy", "greens", "bowl"]),
        .init(symbol: "🍝",                      label: "Pasta",       keywords: ["pasta", "spaghetti", "noodles", "italian"]),
        .init(symbol: "🍛",                      label: "Curry",       keywords: ["curry", "rice", "indian", "asian"]),
        
        // MARK: - Mexican & Latin (Requested)
        .init(symbol: "🌮",                      label: "Taco",        keywords: ["taco", "mexican", "shell", "wrap", "nachos", "chips"]),
        .init(symbol: "🌯",                      label: "Burrito",     keywords: ["burrito", "wrap", "mexican"]),
        .init(symbol: "🫔",                      label: "Tamale",      keywords: ["tamale", "latin", "corn"]),
        .init(symbol: "🫓",                      label: "Tortilla",    keywords: ["tortilla", "chips", "nachos", "flatbread"]),
        .init(symbol: "🥑",                      label: "Guacamole",   keywords: ["guacamole", "avocado", "dip"]),
        .init(symbol: "🍅",                      label: "Salsa",       keywords: ["salsa", "tomato", "dip", "sauce"]),
        .init(symbol: "🌶️",                      label: "Spicy",       keywords: ["spicy", "chili", "hot", "salsa"]),
        .init(symbol: "🥣",                      label: "Queso",       keywords: ["queso", "cheese", "dip", "nachos"]),
        
        // MARK: - Asian Specialties
        .init(symbol: "🍣",                      label: "Sushi",       keywords: ["sushi", "japanese", "fish", "roll"]),
        .init(symbol: "🍜",                      label: "Ramen",       keywords: ["ramen", "noodles", "soup", "asian"]),
        .init(symbol: "🍱",                      label: "Bento",       keywords: ["bento", "box", "japanese", "lunch"]),
        .init(symbol: "🥟",                      label: "Dumpling",    keywords: ["dumpling", "potsticker", "asian", "dim sum"]),
        .init(symbol: "🍤",                      label: "Tempura",     keywords: ["shrimp", "tempura", "fried", "asian"]),
        .init(symbol: "🍙",                      label: "Onigiri",     keywords: ["rice", "ball", "asian"]),
        .init(symbol: "🍚",                      label: "Rice",        keywords: ["rice", "steamed", "asian"]),
        .init(symbol: "🍢",                      label: "Oden",        keywords: ["skewers", "fishcake", "asian"]),
        .init(symbol: "🍡",                      label: "Dango",       keywords: ["dango", "sweet", "skewers", "asian"]),
        .init(symbol: "🥠",                      label: "Fortune Cookie", keywords: ["cookie", "fortune", "asian"]),
        
        // MARK: - Snacks & Sides (Requested)
        .init(symbol: "🍟",                      label: "Fries",       keywords: ["fries", "chips", "potato", "side"]),
        .init(symbol: "🍿",                      label: "Popcorn",     keywords: ["popcorn", "snack", "movie"]),
        .init(symbol: "🥨",                      label: "Pretzel",     keywords: ["pretzel", "snack", "salty"]),
        .init(symbol: "🥜",                      label: "Nuts",        keywords: ["nut", "peanut", "snack", "trail mix"]),
        .init(symbol: "🌰",                      label: "Chestnut",    keywords: ["chestnut", "nut"]),
        .init(symbol: "🧀",                      label: "Cheese",      keywords: ["cheese", "dairy", "snack", "nachos", "queso"]),
        .init(symbol: "🥔",                      label: "Potato",      keywords: ["potato", "chips", "spud"]),
        .init(symbol: "🍘",                      label: "Rice Cracker", keywords: ["cracker", "chips", "snack"]),
        .init(symbol: "🍠",                      label: "Roasted Potato", keywords: ["yam", "potato", "side"]),
        .init(symbol: "🥚",                      label: "Boiled Egg",  keywords: ["egg", "boiled", "snack", "protein"]),
        .init(symbol: "🧂",                      label: "Salt",        keywords: ["salt", "seasoning", "spice"]),
        .init(symbol: "🍯",                      label: "Honey",       keywords: ["honey", "sweet", "syrup"]),
        
        // MARK: - Breakfast & Bakery
        .init(symbol: "cup.and.saucer.fill",    label: "Coffee",      keywords: ["coffee", "tea", "hot drink", "mug"]),
        .init(symbol: "clock.fill",             label: "Early",       keywords: ["morning", "breakfast", "time"]),
        .init(symbol: "sun.max.fill",           label: "Breakfast",   keywords: ["morning", "sun", "breakfast"]),
        .init(symbol: "cloud.sun.fill",         label: "Brunch",      keywords: ["brunch", "morning"]),
        .init(symbol: "🍳",                      label: "Eggs",        keywords: ["egg", "fried", "breakfast"]),
        .init(symbol: "🥞",                      label: "Pancakes",    keywords: ["pancakes", "waffle", "breakfast", "syrup"]),
        .init(symbol: "🧇",                      label: "Waffle",      keywords: ["waffle", "breakfast"]),
        .init(symbol: "🥯",                      label: "Bagel",       keywords: ["bagel", "bread", "breakfast"]),
        .init(symbol: "🥐",                      label: "Croissant",   keywords: ["croissant", "pastry", "bread", "breakfast"]),
        .init(symbol: "🍞",                      label: "Bread",       keywords: ["bread", "toast", "bakery"]),
        .init(symbol: "🥖",                      label: "Baguette",    keywords: ["baguette", "bread", "french"]),
        .init(symbol: "🧈",                      label: "Butter",      keywords: ["butter", "spread", "dairy"]),
        
        // MARK: - Produce & Healthy
        .init(symbol: "carrot.fill",            label: "Produce",     keywords: ["carrot", "vegetable", "veggie"]),
        .init(symbol: "leaf.fill",              label: "Salad",       keywords: ["salad", "lettuce", "leaf", "veggie"]),
        .init(symbol: "🍎",                      label: "Red Apple",   keywords: ["apple", "fruit", "healthy"]),
        .init(symbol: "🍏",                      label: "Green Apple", keywords: ["apple", "fruit", "healthy"]),
        .init(symbol: "🍐",                      label: "Pear",        keywords: ["pear", "fruit"]),
        .init(symbol: "🍊",                      label: "Orange",      keywords: ["orange", "citrus", "fruit"]),
        .init(symbol: "🍋",                      label: "Lemon",       keywords: ["lemon", "citrus"]),
        .init(symbol: "🍌",                      label: "Banana",      keywords: ["banana", "fruit", "healthy"]),
        .init(symbol: "🍉",                      label: "Watermelon",  keywords: ["watermelon", "fruit", "summer"]),
        .init(symbol: "🍇",                      label: "Grapes",      keywords: ["grapes", "fruit", "wine"]),
        .init(symbol: "🍓",                      label: "Strawberry",  keywords: ["strawberry", "fruit", "sweet"]),
        .init(symbol: "🫐",                      label: "Blueberries", keywords: ["berry", "blueberry", "fruit"]),
        .init(symbol: "🍈",                      label: "Melon",       keywords: ["melon", "cantaloupe"]),
        .init(symbol: "🍒",                      label: "Cherries",    keywords: ["cherry", "fruit"]),
        .init(symbol: "🍑",                      label: "Peach",       keywords: ["peach", "fruit"]),
        .init(symbol: "🥭",                      label: "Mango",       keywords: ["mango", "fruit"]),
        .init(symbol: "🍍",                      label: "Pineapple",   keywords: ["pineapple", "fruit", "tropical"]),
        .init(symbol: "🥥",                      label: "Coconut",     keywords: ["coconut", "tropical"]),
        .init(symbol: "🥝",                      label: "Kiwi",        keywords: ["kiwi", "fruit"]),
        .init(symbol: "🍅",                      label: "Tomato",      keywords: ["tomato", "vegetable", "salsa"]),
        .init(symbol: "🍆",                      label: "Eggplant",    keywords: ["eggplant", "aubergine"]),
        .init(symbol: "🥑",                      label: "Avocado",     keywords: ["avocado", "healthy", "guacamole"]),
        .init(symbol: "🥦",                      label: "Broccoli",    keywords: ["broccoli", "vegetable", "veggie"]),
        .init(symbol: "🥬",                      label: "Leafy Green", keywords: ["lettuce", "kale", "spinach", "salad"]),
        .init(symbol: "🥒",                      label: "Cucumber",    keywords: ["cucumber", "pickle"]),
        .init(symbol: "🌶️",                      label: "Hot Pepper",  keywords: ["chili", "pepper", "spicy"]),
        .init(symbol: "🫑",                      label: "Bell Pepper", keywords: ["pepper", "vegetable"]),
        .init(symbol: "🌽",                      label: "Corn",        keywords: ["corn", "cob", "vegetable"]),
        .init(symbol: "🥕",                      label: "Carrot",      keywords: ["carrot", "vegetable"]),
        .init(symbol: "🫒",                      label: "Olive",       keywords: ["olive", "martini"]),
        .init(symbol: "🧄",                      label: "Garlic",      keywords: ["garlic", "seasoning"]),
        .init(symbol: "🧅",                      label: "Onion",       keywords: ["onion", "seasoning"]),
        .init(symbol: "🍄",                      label: "Mushroom",    keywords: ["mushroom", "fungi"]),
        .init(symbol: "🫘",                      label: "Beans",       keywords: ["beans", "legumes", "protein"]),

        // MARK: - Sweets & Desserts
        .init(symbol: "birthday.cake.fill",     label: "Cake",        keywords: ["cake", "treat", "dessert", "birthday"]),
        .init(symbol: "🍦",                      label: "Soft Serve",  keywords: ["ice cream", "cold", "treat", "dessert"]),
        .init(symbol: "🍧",                      label: "Shaved Ice",  keywords: ["shaved ice", "treat"]),
        .init(symbol: "🍨",                      label: "Ice Cream",   keywords: ["ice cream", "dessert"]),
        .init(symbol: "🍩",                      label: "Donut",       keywords: ["donut", "sweet", "pastry"]),
        .init(symbol: "🍪",                      label: "Cookie",      keywords: ["cookie", "biscuit", "sweet"]),
        .init(symbol: "🎂",                      label: "Birthday Cake", keywords: ["cake", "birthday"]),
        .init(symbol: "🍰",                      label: "Shortcake",   keywords: ["cake", "slice", "dessert"]),
        .init(symbol: "🧁",                      label: "Cupcake",     keywords: ["cupcake", "muffin", "sweet"]),
        .init(symbol: "🥧",                      label: "Pie",         keywords: ["pie", "pastry", "dessert"]),
        .init(symbol: "🍫",                      label: "Chocolate",   keywords: ["chocolate", "candy", "sweet"]),
        .init(symbol: "🍬",                      label: "Candy",       keywords: ["candy", "sweet"]),
        .init(symbol: "🍭",                      label: "Lollipop",    keywords: ["lollipop", "candy"]),
        .init(symbol: "🍮",                      label: "Custard",     keywords: ["pudding", "custard", "flan"]),

        // MARK: - Drinks & Beverages
        .init(symbol: "mug.fill",               label: "Beer",        keywords: ["beer", "mug", "drink", "pub"]),
        .init(symbol: "wineglass.fill",         label: "Wine",        keywords: ["wine", "glass", "drink", "bar"]),
        .init(symbol: "bottle.fill",            label: "Drink",       keywords: ["bottle", "soda", "drink"]),
        .init(symbol: "☕️",                      label: "Hot Coffee",  keywords: ["coffee", "tea", "espresso"]),
        .init(symbol: "🍵",                      label: "Tea",         keywords: ["tea", "matcha", "green tea"]),
        .init(symbol: "🍶",                      label: "Sake",        keywords: ["sake", "japanese", "drink"]),
        .init(symbol: "🍺",                      label: "Beer Mug",    keywords: ["beer", "drink"]),
        .init(symbol: "🍻",                      label: "Clinking Beers", keywords: ["beers", "cheers", "drink"]),
        .init(symbol: "🥂",                      label: "Champagne",   keywords: ["champagne", "toast", "celebration"]),
        .init(symbol: "🍷",                      label: "Red Wine",    keywords: ["wine", "drink"]),
        .init(symbol: "🥃",                      label: "Whiskey",     keywords: ["whiskey", "liquor", "drink"]),
        .init(symbol: "🍸",                      label: "Martini",     keywords: ["cocktail", "martini", "drink"]),
        .init(symbol: "🍹",                      label: "Tropical Drink", keywords: ["cocktail", "tropical", "drink"]),
        .init(symbol: "🧉",                      label: "Mate",        keywords: ["mate", "tea", "drink"]),
        .init(symbol: "🍾",                      label: "Bubbly",      keywords: ["champagne", "sparkling", "bottle"]),
        .init(symbol: "🥤",                      label: "Soft Drink",  keywords: ["soda", "cola", "drink"]),
        .init(symbol: "🧃",                      label: "Juice Box",   keywords: ["juice", "drink", "kids"]),
        .init(symbol: "🥛",                      label: "Milk",        keywords: ["milk", "dairy", "drink"]),
        .init(symbol: "🧊",                      label: "Ice",         keywords: ["ice", "cold", "cube"]),

        // MARK: - Adventure & Logistics
        .init(symbol: "flame.fill",             label: "BBQ",         keywords: ["grill", "bbq", "fire", "cookout"]),
        .init(symbol: "tent.fill",              label: "Camping",     keywords: ["camp", "tent", "outdoor"]),
        .init(symbol: "beach.umbrella.fill",    label: "Beach",       keywords: ["beach", "picnic", "sand"]),
        .init(symbol: "sailboat.fill",          label: "Boating",     keywords: ["boat", "sailing", "lake"]),
        .init(symbol: "cart.fill",              label: "Groceries",   keywords: ["cart", "shopping", "groceries", "store"]),
        .init(symbol: "archivebox.fill",        label: "Storage",     keywords: ["box", "storage", "pantry", "leftovers"]),
        .init(symbol: "shippingbox.fill",       label: "Delivery",    keywords: ["delivery", "box", "shipping"]),
        .init(symbol: "trash.fill",             label: "Cleanup",     keywords: ["trash", "waste", "cleanup"]),
        .init(symbol: "house.fill",             label: "Home",        keywords: ["home", "staying in"]),
        .init(symbol: "building.2.fill",        label: "Restaurant",  keywords: ["city", "dining", "out"]),
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
