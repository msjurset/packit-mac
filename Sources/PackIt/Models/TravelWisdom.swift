import Foundation

enum WisdomType: String, Codable {
    case tip
    case quote
}

struct TravelWisdom: Identifiable {
    let id = UUID()
    let type: WisdomType
    let text: String
    let attribution: String?

    static let all: [TravelWisdom] = tips + quotes

    // MARK: - Tips

    static let tips: [TravelWisdom] = [
        // Packing strategy
        TravelWisdom(type: .tip, text: "Roll knits, fold wovens. Rolling stretchy fabrics saves space; structured fabrics like dress shirts wrinkle less when folded with tissue paper between layers.", attribution: nil),
        TravelWisdom(type: .tip, text: "Pack a pillowcase separately. It doubles as a laundry bag, a pillow cover for questionable hotel pillows, and an emergency tote.", attribution: nil),
        TravelWisdom(type: .tip, text: "Put dryer sheets between clothing layers. They keep everything smelling fresh and reduce static cling in dry climates.", attribution: nil),
        TravelWisdom(type: .tip, text: "Wear your bulkiest items on the plane. Boots, heavy jacket, and jeans on your body means more room in your bag for everything else.", attribution: nil),
        TravelWisdom(type: .tip, text: "Pack a power strip, not just adapters. One outlet in a hotel room becomes five, and your travel companions will love you.", attribution: nil),
        TravelWisdom(type: .tip, text: "Stuff socks inside shoes to save space and help shoes keep their shape in transit.", attribution: nil),
        TravelWisdom(type: .tip, text: "Keep a change of clothes in your carry-on. If checked luggage gets lost, you'll still have clean underwear and a fresh shirt for day one.", attribution: nil),
        TravelWisdom(type: .tip, text: "Photograph your packed suitcase contents before closing it. If your bag is lost, you'll have an exact inventory for the airline claim.", attribution: nil),
        TravelWisdom(type: .tip, text: "Pack an empty water bottle. Fill it after security. Staying hydrated on flights reduces jet lag more than any supplement.", attribution: nil),
        TravelWisdom(type: .tip, text: "Bring a doorstop. It's the cheapest, lightest hotel room security device you'll ever own.", attribution: nil),

        // Organization
        TravelWisdom(type: .tip, text: "Use packing cubes by outfit, not by item type. Monday's cube has Monday's complete outfit — no rummaging at 6 AM.", attribution: nil),
        TravelWisdom(type: .tip, text: "Pack a gallon zip-lock bag in your carry-on for wet swimsuits, leaky toiletries, or dirty shoes on the return trip.", attribution: nil),
        TravelWisdom(type: .tip, text: "Put a brightly colored ribbon or tape on your black suitcase. You'll spot it instantly on the carousel instead of grabbing a stranger's identical bag.", attribution: nil),
        TravelWisdom(type: .tip, text: "Keep all chargers and cables in one dedicated pouch. The ten minutes you spend organizing before a trip saves hours of searching during it.", attribution: nil),
        TravelWisdom(type: .tip, text: "Pack a spare set of zip-lock bags in various sizes. They solve more travel problems than almost any single-purpose gadget.", attribution: nil),

        // Clothing
        TravelWisdom(type: .tip, text: "Choose a color palette for your trip wardrobe. Three coordinating colors means every top works with every bottom, cutting your clothing count in half.", attribution: nil),
        TravelWisdom(type: .tip, text: "Merino wool is the traveler's secret weapon. It regulates temperature, resists odor for days, and dries overnight after a sink wash.", attribution: nil),
        TravelWisdom(type: .tip, text: "A sarong is the most versatile item you can pack: beach towel, blanket, pillow cover, privacy curtain, picnic blanket, skirt, or sun shade.", attribution: nil),
        TravelWisdom(type: .tip, text: "Pack one outfit you'd be comfortable in at an unexpectedly nice restaurant. The best travel memories often involve spontaneous dinner plans.", attribution: nil),
        TravelWisdom(type: .tip, text: "Bring one more pair of socks than you think you need, and one fewer shirt. You can always rinse a shirt, but wet socks ruin a hiking day.", attribution: nil),

        // Health & comfort
        TravelWisdom(type: .tip, text: "Pack medications in their original pharmacy bottles. In some countries, unlabeled pills can cause problems at customs.", attribution: nil),
        TravelWisdom(type: .tip, text: "Bring a collapsible tote bag. It weighs nothing packed flat but becomes essential for farmers markets, beach days, or overflow shopping.", attribution: nil),
        TravelWisdom(type: .tip, text: "Carry a photocopy of your passport's ID page separate from the passport itself. If the original is lost or stolen, the copy dramatically speeds up replacement at an embassy.", attribution: nil),
        TravelWisdom(type: .tip, text: "A carabiner clipped to your bag gives you a hands-free way to carry an extra shopping bag, water bottle, or shoes.", attribution: nil),
        TravelWisdom(type: .tip, text: "Pack earplugs and an eye mask even if you never use them at home. Hotel hallways at 2 AM and street-facing windows will test your optimism.", attribution: nil),

        // Tech & safety
        TravelWisdom(type: .tip, text: "Email yourself a scan of all important documents: passport, insurance cards, prescriptions, itinerary. Accessible from any device, anywhere.", attribution: nil),
        TravelWisdom(type: .tip, text: "Download offline maps and translation packs before you leave. Your phone's most useful features shouldn't depend on cell signal.", attribution: nil),
        TravelWisdom(type: .tip, text: "Pack a small flashlight or headlamp even for city trips. Power outages happen, and phone flashlights drain your battery when you need it most.", attribution: nil),
        TravelWisdom(type: .tip, text: "Bring a pen in your carry-on. You'll need it for customs forms, and the person next to you who forgot theirs will think you're a genius.", attribution: nil),
        TravelWisdom(type: .tip, text: "Put a luggage tag inside your bag, not just outside. External tags get torn off; the internal one is your backup.", attribution: nil),

        // Return trip
        TravelWisdom(type: .tip, text: "Leave a little room in your bag on the way out. Souvenirs, gifts, and that perfect olive oil you found always need a ride home.", attribution: nil),
        TravelWisdom(type: .tip, text: "Pack a fabric tote bag for the return trip. If your suitcase is overweight at check-in, move the heavy items to the tote as a personal item.", attribution: nil),
        TravelWisdom(type: .tip, text: "Take a photo of your hotel room before checking out. That charger behind the nightstand has ended more vacations than lost passports.", attribution: nil),

        // Mindset
        TravelWisdom(type: .tip, text: "If you're debating whether to pack something, leave it. Anything you can buy at your destination for under $20 isn't worth the space or worry.", attribution: nil),
        TravelWisdom(type: .tip, text: "Pack your bag, then remove three items. You'll never miss them, and you'll appreciate the lighter load every time you lift your bag.", attribution: nil),
        TravelWisdom(type: .tip, text: "The night before departure, lay everything out and take a photo. If you realize you forgot something at the airport, you can check the photo instead of panicking.", attribution: nil),
    ]

    // MARK: - Quotes

    static let quotes: [TravelWisdom] = [
        TravelWisdom(type: .quote, text: "The world is a book, and those who do not travel read only one page.", attribution: "Saint Augustine"),
        TravelWisdom(type: .quote, text: "Not all those who wander are lost.", attribution: "J.R.R. Tolkien"),
        TravelWisdom(type: .quote, text: "Travel is fatal to prejudice, bigotry, and narrow-mindedness.", attribution: "Mark Twain"),
        TravelWisdom(type: .quote, text: "A journey of a thousand miles begins with a single step.", attribution: "Lao Tzu"),
        TravelWisdom(type: .quote, text: "The real voyage of discovery consists not in seeking new landscapes, but in having new eyes.", attribution: "Marcel Proust"),
        TravelWisdom(type: .quote, text: "Once a year, go someplace you've never been before.", attribution: "Dalai Lama"),
        TravelWisdom(type: .quote, text: "Travel makes one modest. You see what a tiny place you occupy in the world.", attribution: "Gustave Flaubert"),
        TravelWisdom(type: .quote, text: "I haven't been everywhere, but it's on my list.", attribution: "Susan Sontag"),
        TravelWisdom(type: .quote, text: "To travel is to discover that everyone is wrong about other countries.", attribution: "Aldous Huxley"),
        TravelWisdom(type: .quote, text: "Man cannot discover new oceans unless he has the courage to lose sight of the shore.", attribution: "Andre Gide"),
        TravelWisdom(type: .quote, text: "Life is either a daring adventure or nothing at all.", attribution: "Helen Keller"),
        TravelWisdom(type: .quote, text: "We travel not to escape life, but for life not to escape us.", attribution: "Anonymous"),
        TravelWisdom(type: .quote, text: "The journey not the arrival matters.", attribution: "T.S. Eliot"),
        TravelWisdom(type: .quote, text: "Traveling — it leaves you speechless, then turns you into a storyteller.", attribution: "Ibn Battuta"),
        TravelWisdom(type: .quote, text: "Take only memories, leave only footprints.", attribution: "Chief Seattle"),
        TravelWisdom(type: .quote, text: "Adventure is worthwhile in itself.", attribution: "Amelia Earhart"),
        TravelWisdom(type: .quote, text: "The gladdest moment in human life is a departure into unknown lands.", attribution: "Sir Richard Burton"),
        TravelWisdom(type: .quote, text: "Travel far enough, you meet yourself.", attribution: "David Mitchell"),
        TravelWisdom(type: .quote, text: "A good traveler has no fixed plans and is not intent on arriving.", attribution: "Lao Tzu"),
        TravelWisdom(type: .quote, text: "One's destination is never a place, but a new way of seeing things.", attribution: "Henry Miller"),
        TravelWisdom(type: .quote, text: "Jobs fill your pocket, but adventures fill your soul.", attribution: "Jaime Lyn"),
        TravelWisdom(type: .quote, text: "To move, to breathe, to fly, to float, to roam the roads of lands remote.", attribution: "John Keats"),
        TravelWisdom(type: .quote, text: "Wherever you go, go with all your heart.", attribution: "Confucius"),
        TravelWisdom(type: .quote, text: "Travel is the only thing you buy that makes you richer.", attribution: "Anonymous"),
        TravelWisdom(type: .quote, text: "Blessed are the curious, for they shall have adventures.", attribution: "Lovelle Drachman"),
        TravelWisdom(type: .quote, text: "Paris is always a good idea.", attribution: "Audrey Hepburn"),
        TravelWisdom(type: .quote, text: "Collect moments, not things.", attribution: "Anonymous"),
        TravelWisdom(type: .quote, text: "Oh the places you'll go.", attribution: "Dr. Seuss"),
        TravelWisdom(type: .quote, text: "The mountains are calling and I must go.", attribution: "John Muir"),
        TravelWisdom(type: .quote, text: "If we were meant to stay in one place, we'd have roots instead of feet.", attribution: "Rachel Wolchin"),
    ]
}
