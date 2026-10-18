import XCTest
import SwiftUI
import AppKit
import PackItKit
@testable import PackIt

private struct DocCallout: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let subtitle: String
    let targetRect: CGRect
    let badgeCenter: CGPoint
    let color: Color

    var estimatedBadgeRect: CGRect {
        let width = CGFloat(max(title.count, subtitle.count)) * 6.8 + 56
        let height: CGFloat = 44
        return CGRect(
            x: badgeCenter.x - width / 2,
            y: badgeCenter.y - height / 2,
            width: width,
            height: height
        )
    }
}

private struct AnnotatedScreenshotCanvas<Content: View>: View {
    let content: Content
    let size: CGSize
    let callouts: [DocCallout]

    var body: some View {
        ZStack(alignment: .topLeading) {
            content
                .frame(width: size.width, height: size.height)
                .clipped()

            // Highlight target rectangles (border only — zero interior shading)
            ForEach(callouts) { callout in
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.65), lineWidth: 4.0)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(callout.color, lineWidth: 2.2)
                    )
                    .frame(width: callout.targetRect.width, height: callout.targetRect.height)
                    .position(x: callout.targetRect.midX, y: callout.targetRect.midY)
            }

            // Connector lines + arrowheads
            Canvas { context, _ in
                for callout in callouts {
                    let start = connectorStart(from: callout.badgeCenter, to: callout.targetRect)
                    let end = closestPoint(on: callout.targetRect, from: callout.badgeCenter)

                    var linePath = Path()
                    linePath.move(to: start)
                    linePath.addLine(to: end)

                    context.stroke(
                        linePath,
                        with: .color(.black.opacity(0.65)),
                        style: StrokeStyle(lineWidth: 4.0, lineCap: .round)
                    )
                    context.stroke(
                        linePath,
                        with: .color(callout.color),
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                    )

                    let angle = atan2(end.y - start.y, end.x - start.x)
                    let arrowLength: CGFloat = 9
                    let arrowAngle: CGFloat = .pi / 6
                    var arrow = Path()
                    arrow.move(to: end)
                    arrow.addLine(to: CGPoint(
                        x: end.x - arrowLength * cos(angle - arrowAngle),
                        y: end.y - arrowLength * sin(angle - arrowAngle)
                    ))
                    arrow.addLine(to: CGPoint(
                        x: end.x - arrowLength * cos(angle + arrowAngle),
                        y: end.y - arrowLength * sin(angle + arrowAngle)
                    ))
                    arrow.closeSubpath()
                    context.fill(arrow, with: .color(callout.color))
                }
            }
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)

            // Numbered callout badge cards
            ForEach(callouts) { callout in
                HStack(spacing: 8) {
                    Text("\(callout.number)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(callout.color))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(callout.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                        Text(callout.subtitle)
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(red: 0.09, green: 0.10, blue: 0.14).opacity(0.96))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(callout.color, lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 4)
                .position(callout.badgeCenter)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func closestPoint(on rect: CGRect, from point: CGPoint) -> CGPoint {
        let cx = min(max(point.x, rect.minX), rect.maxX)
        let cy = min(max(point.y, rect.minY), rect.maxY)
        return CGPoint(x: cx, y: cy)
    }

    private func connectorStart(from badge: CGPoint, to rect: CGRect) -> CGPoint {
        let target = closestPoint(on: rect, from: badge)
        let dx = target.x - badge.x
        let dy = target.y - badge.y
        let dist = hypot(dx, dy)
        guard dist > 28 else { return badge }
        return CGPoint(x: badge.x + (dx / dist) * 20, y: badge.y + (dy / dist) * 18)
    }
}

@MainActor
final class PackItDocsScreenshotTests: XCTestCase {

    private func assertNoCalloutOverlaps(callouts: [DocCallout], size: CGSize, path: String) {
        let canvasBounds = CGRect(origin: .zero, size: size)
        for i in 0..<callouts.count {
            let badgeA = callouts[i].estimatedBadgeRect
            XCTAssertTrue(
                canvasBounds.contains(badgeA),
                "[\(path)] Callout #\(callouts[i].number) ('\(callouts[i].title)') badge \(badgeA) clips outside canvas \(canvasBounds)"
            )
            for j in 0..<callouts.count {
                let targetB = callouts[j].targetRect
                XCTAssertFalse(
                    badgeA.intersects(targetB),
                    "[\(path)] Callout #\(callouts[i].number) ('\(callouts[i].title)') badge \(badgeA) overlaps targetRect #\(callouts[j].number) \(targetB)"
                )
                if j > i {
                    let badgeB = callouts[j].estimatedBadgeRect
                    XCTAssertFalse(
                        badgeA.intersects(badgeB),
                        "[\(path)] Callout #\(callouts[i].number) ('\(callouts[i].title)') badge \(badgeA) overlaps Callout #\(callouts[j].number) ('\(callouts[j].title)') badge \(badgeB)"
                    )
                    XCTAssertFalse(
                        callouts[i].targetRect.intersects(targetB),
                        "[\(path)] TargetRect #\(callouts[i].number) ('\(callouts[i].title)') \(callouts[i].targetRect) overlaps TargetRect #\(callouts[j].number) ('\(callouts[j].title)') \(targetB)"
                    )
                }
            }
        }
    }

    private func renderAnnotatedScreenshot<V: View>(
        _ view: V,
        callouts: [DocCallout],
        size: CGSize,
        to relativePath: String
    ) throws {
        assertNoCalloutOverlaps(callouts: callouts, size: size, path: relativePath)

        let canvas = AnnotatedScreenshotCanvas(content: view, size: size, callouts: callouts)
            .environment(\.colorScheme, .dark)

        let hostingView = NSHostingView(rootView: canvas)
        hostingView.appearance = NSAppearance(named: .darkAqua)
        hostingView.frame = CGRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)
        window.colorSpace = .sRGB
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        window.display()
        hostingView.layoutSubtreeIfNeeded()

        RunLoop.main.run(until: Date().addingTimeInterval(0.35))
        hostingView.layoutSubtreeIfNeeded()
        window.display()

        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            XCTFail("Failed to create bitmapImageRep for \(relativePath)")
            return
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)

        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            XCTFail("Failed to encode PNG for \(relativePath)")
            return
        }

        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let outputURL = repoRoot.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try pngData.write(to: outputURL)
        window.orderOut(nil)

        if !callouts.isEmpty && relativePath.hasSuffix(".png") {
            try renderAnnotatedScreenshot(view, callouts: [], size: size, to: String(relativePath.dropLast(4)) + "_clean.png")
        }
    }

    private func makeSyntheticStore() -> (PackItStore, TripInstance, PackingTemplate) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("packit-docs-\(UUID().uuidString)")
        let store = PackItStore(persistence: Persistence(baseURL: tempDir), notifications: nil)

        store.tags = [
            ContextTag(name: "alpine"),
            ContextTag(name: "international"),
            ContextTag(name: "photography"),
            ContextTag(name: "camping"),
            ContextTag(name: "cold-weather"),
            ContextTag(name: "remote-work")
        ]

        let cameraKitID = UUID()
        let baseEssentialsID = UUID()
        let alpineTemplateID = UUID()

        let baseEssentials = PackingTemplate(
            id: baseEssentialsID,
            name: "International Travel Core",
            items: [
                TemplateItem(name: "Passport & Global Entry Card", category: "Documents", owner: "Alex", contextTags: ["international"], priority: .critical),
                TemplateItem(name: "Universal GaN 100W Adapter", category: "Electronics", owner: "Alex", contextTags: ["international"], priority: .high),
                TemplateItem(name: "Noise-Cancelling Headphones", category: "Electronics", owner: "Alex", priority: .medium),
                TemplateItem(name: "AirTag Luggage Trackers", category: "Electronics", owner: "Shared", priority: .high, quantity: 3),
                TemplateItem(name: "First Aid & Electrolyte Kit", category: "Medical", owner: "Shared", priority: .high)
            ],
            contextTags: ["international", "remote-work"]
        )

        let cameraKit = PackingTemplate(
            id: cameraKitID,
            name: "Mirrorless Field Kit",
            items: [
                TemplateItem(name: "Mirrorless Body + 24-70mm f/2.8", category: "Camera Gear", owner: "Alex", contextTags: ["photography"], priority: .critical),
                TemplateItem(name: "CFexpress Type B Cards (256GB)", category: "Camera Gear", owner: "Alex", contextTags: ["photography"], priority: .high, quantity: 2),
                TemplateItem(name: "Carbon Travel Tripod", category: "Camera Gear", owner: "Alex", contextTags: ["photography", "alpine"], priority: .medium),
                TemplateItem(name: "ND Graduated Filter Set", category: "Camera Gear", owner: "Alex", contextTags: ["photography"], priority: .low)
            ],
            contextTags: ["photography"]
        )

        let alpineTemplate = PackingTemplate(
            id: alpineTemplateID,
            name: "Dolomites Alpine Expedition",
            items: [
                TemplateItem(name: "Gore-Tex Pro Hardshell Jacket", category: "Outerwear", owner: "Alex", contextTags: ["alpine", "cold-weather"], priority: .critical, notes: "Check DWR coating before departure"),
                TemplateItem(name: "Merino Base Layer Set (250g)", category: "Clothing", owner: "Alex", contextTags: ["alpine", "cold-weather"], priority: .high, quantity: 3),
                TemplateItem(name: "Approach Boots (Vibram Sole)", category: "Footwear", owner: "Alex", contextTags: ["alpine"], priority: .critical),
                TemplateItem(name: "Collapsible Trekking Poles", category: "Alpine Gear", owner: "Sam", contextTags: ["alpine"], priority: .high, quantity: 2),
                TemplateItem(name: "Garmin inReach Mini 2 Satellite SOS", category: "Navigation", owner: "Shared", contextTags: ["alpine"], priority: .critical),
                TemplateItem(name: "Headlamp 450 Lumens (USB-C)", category: "Alpine Gear", owner: "Sam", contextTags: ["alpine", "camping"], priority: .high),
                TemplateItem(name: "Insulated Hydro Flask 32oz", category: "Hydration", owner: "Shared", contextTags: ["alpine"], priority: .medium, quantity: 2),
                TemplateItem(name: "Packable Down Midlayer", category: "Outerwear", owner: "Sam", contextTags: ["alpine", "cold-weather"], priority: .high)
            ],
            prepTasks: [
                PrepTaskTemplate(name: "Verify Rifugio hut reservations & vouchers", category: "Logistics", timing: .weeksBefore, contextTags: ["alpine"]),
                PrepTaskTemplate(name: "Activate Garmin inReach satellite subscription", category: "Safety", timing: .weekBefore, contextTags: ["alpine"]),
                PrepTaskTemplate(name: "Download offline GPX topographic maps", category: "Navigation", timing: .daysBefore, contextTags: ["alpine"]),
                PrepTaskTemplate(name: "Weigh carry-on & check trekking pole rules", category: "Airport", timing: .dayOf, contextTags: ["international"]),
                PrepTaskTemplate(name: "Backup RAW photos & air out boots", category: "Post-Trip", timing: .onReturn, contextTags: ["photography"])
            ],
            procedures: [
                ProcedureTemplate(
                    name: "Home Departure Lockup",
                    phase: .beforeDeparture,
                    steps: [
                        ProcedureStepTemplate(text: "Set smart thermostat to Eco Hold (58°F)", sortOrder: 1),
                        ProcedureStepTemplate(text: "Shut off main water supply valve", sortOrder: 2),
                        ProcedureStepTemplate(text: "Verify passport wallet & boarding passes", sortOrder: 3)
                    ]
                ),
                ProcedureTemplate(
                    name: "Trailhead & Basecamp Setup",
                    phase: .onArrival,
                    steps: [
                        ProcedureStepTemplate(text: "Test Garmin inReach satellite check-in message", sortOrder: 1),
                        ProcedureStepTemplate(text: "Calibrate barometric altimeter at trailhead", sortOrder: 2),
                        ProcedureStepTemplate(text: "Stage rain covers and emergency bivy in top lid", sortOrder: 3)
                    ]
                ),
                ProcedureTemplate(
                    name: "Hut Checkout Sweep",
                    phase: .beforeLeaving,
                    steps: [
                        ProcedureStepTemplate(text: "Check wall outlets for USB-C chargers and adapters", sortOrder: 1),
                        ProcedureStepTemplate(text: "Refill hydration bladders with treated water", sortOrder: 2)
                    ]
                )
            ],
            referenceLinks: [
                ReferenceLink(label: "Alta Via 1 Rifugio Booking Portal", url: "https://example.com/rifugio-booking", category: "Reservations"),
                ReferenceLink(label: "Südtirol Mountain Weather Bulletin", url: "https://example.com/weather-bulletin", category: "Weather")
            ],
            linkedTemplateIDs: [baseEssentialsID, cameraKitID],
            contextTags: ["alpine", "international", "photography", "cold-weather"]
        )

        store.templates = [alpineTemplate, baseEssentials, cameraKit]

        let depDate = Calendar.current.date(byAdding: .day, value: 4, to: .now)!
        let retDate = Calendar.current.date(byAdding: .day, value: 9, to: .now)!

        var mealPlan = MealPlan.generate(departure: depDate, returnDate: retDate)
        mealPlan.prepNotes = "Pre-pack 5x freeze-dried mountain pouches, espresso capsules, and electrolyte chews in bear canister."
        if mealPlan.days.count >= 4 {
            mealPlan.days[0].setSlot(.breakfast, items: ["Cortado & Brioche"], icons: ["cup.and.saucer.fill"])
            mealPlan.days[0].setSlot(.lunch, items: ["Speck & Fontina Panini"], icons: ["takeoutbag.and.cup.and.straw.fill"])
            mealPlan.days[0].setSlot(.dinner, items: ["Canederli at Rifugio Lagazuoi"], icons: ["fork.knife"])
            mealPlan.days[0].setSlot(.snacks, items: ["Trail Mix", "Dark Chocolate"], icons: ["carrot.fill"])

            mealPlan.days[1].setSlot(.breakfast, items: ["Alpine Birchermüesli"], icons: ["sunrise.fill"])
            mealPlan.days[1].setSlot(.lunch, items: ["Polenta & Mushroom Ragù"], icons: ["flame.fill"])
            mealPlan.days[1].setSlot(.dinner, items: ["Rifugio Half-Board Tasting"], icons: ["wineglass.fill"])
            mealPlan.days[1].setSlot(.snacks, items: ["Electrolyte Chews", "Clif Bar"], icons: ["bolt.fill"])

            mealPlan.days[2].setSlot(.breakfast, items: ["Oatmeal & Espresso"], icons: ["cup.and.saucer.fill"])
            mealPlan.days[2].setSlot(.lunch, items: ["Cured Bresaola & Rye"], icons: ["leaf.fill"])
            mealPlan.days[2].setSlot(.dinner, items: ["Casunziei Beet Ravioli"], icons: ["fork.knife"])
            mealPlan.days[2].setSlot(.snacks, items: ["Dried Apricots & Almonds"], icons: ["carrot.fill"])

            mealPlan.days[3].setSlot(.breakfast, items: ["Strudel & Cappuccino"], icons: ["sunrise.fill"])
            mealPlan.days[3].setSlot(.lunch, items: ["Summit Ridges Picnic"], icons: ["mountain.2.fill"])
            mealPlan.days[3].setSlot(.dinner, items: ["Cortina Trattoria Celebration"], icons: ["sparkles"])
        }

        let activeTrip = TripInstance(
            name: "Dolomites Alta Via Traverse",
            icon: .mountain,
            destination: TripDestination(name: "Cortina d'Ampezzo", latitude: 46.5405, longitude: 12.1357, country: "Italy", admin1: "Veneto"),
            sourceTemplateIDs: [alpineTemplateID, baseEssentialsID, cameraKitID],
            departureDate: depDate,
            returnDate: retDate,
            items: [
                TripItem(name: "Passport & Global Entry Card", category: "Documents", owner: "Alex", priority: .critical, isPacked: true),
                TripItem(name: "Rifugio Voucher Printouts", category: "Documents", owner: "Shared", priority: .high, isPacked: true, isAdHoc: true),
                TripItem(name: "Gore-Tex Pro Hardshell Jacket", category: "Outerwear", owner: "Alex", priority: .critical, isPacked: true, notes: "DWR refreshed"),
                TripItem(name: "Packable Down Midlayer", category: "Outerwear", owner: "Sam", priority: .high, isPacked: false),
                TripItem(name: "Merino Base Layer Set (250g)", category: "Clothing", owner: "Alex", priority: .high, isPacked: true, quantity: 3),
                TripItem(name: "Approach Boots (Vibram Sole)", category: "Footwear", owner: "Alex", priority: .critical, isPacked: true),
                TripItem(name: "Garmin inReach Mini 2 Satellite SOS", category: "Navigation", owner: "Shared", priority: .critical, isPacked: false),
                TripItem(name: "Collapsible Trekking Poles", category: "Alpine Gear", owner: "Sam", priority: .high, isPacked: false, quantity: 2),
                TripItem(name: "Headlamp 450 Lumens (USB-C)", category: "Alpine Gear", owner: "Sam", priority: .high, isPacked: true),
                TripItem(name: "Mirrorless Body + 24-70mm f/2.8", category: "Camera Gear", owner: "Alex", priority: .critical, isPacked: true),
                TripItem(name: "CFexpress Type B Cards (256GB)", category: "Camera Gear", owner: "Alex", priority: .high, isPacked: true, quantity: 2),
                TripItem(name: "Carbon Travel Tripod", category: "Camera Gear", owner: "Alex", priority: .medium, isPacked: false),
                TripItem(name: "Via Ferrata Lanyard & Helmet", category: "Alpine Gear", owner: "Alex", priority: .high, isPacked: false, isAdHoc: true)
            ],
            prepTasks: [
                PrepTask(name: "Verify Rifugio hut reservations & vouchers", category: "Logistics", timing: .weeksBefore, dueDate: Calendar.current.date(byAdding: .day, value: -10, to: depDate)!, isComplete: true),
                PrepTask(name: "Activate Garmin inReach satellite subscription", category: "Safety", timing: .weekBefore, dueDate: Calendar.current.date(byAdding: .day, value: -3, to: depDate)!, isComplete: true),
                PrepTask(name: "Download offline GPX topographic maps", category: "Navigation", timing: .daysBefore, dueDate: Calendar.current.date(byAdding: .day, value: -1, to: depDate)!, isComplete: false),
                PrepTask(name: "Weigh carry-on & check trekking pole rules", category: "Airport", timing: .dayOf, dueDate: depDate, isComplete: false),
                PrepTask(name: "Backup RAW photos & air out boots", category: "Post-Trip", timing: .onReturn, dueDate: retDate, isComplete: false)
            ],
            todos: [
                TripTodo(text: "Pick up Euro cash at ATM before shuttle", isComplete: true, priority: .high),
                TripTodo(text: "Confirm Passo Falzarego cable car hours", isComplete: false, priority: .medium),
                TripTodo(text: "Buy extra blister plasters in Cortina", isComplete: false, priority: .low)
            ],
            procedures: alpineTemplate.procedures.map { proc in
                var p = Procedure(from: proc)
                if p.steps.count >= 2 {
                    p.steps[0].isComplete = true
                    p.steps[1].isComplete = true
                }
                return p
            },
            mealPlan: mealPlan,
            referenceLinks: alpineTemplate.referenceLinks,
            members: ["Alex", "Sam"],
            travelMode: .plane,
            scratchNotes: "### Trail & Hut Notes\n- **Rifugio Lagazuoi**: Check-in before 17:30\n- **Emergency Frequency**: 112 Alpine Rescue\n- Keep camera batteries in interior jacket pocket overnight.",
            status: .active,
            isPinned: true
        )

        let secondActiveTrip = TripInstance(
            name: "Big Sur Coastal Camp",
            icon: .camping,
            destination: TripDestination(name: "Big Sur", latitude: 36.2704, longitude: -121.8081, country: "United States", admin1: "California"),
            sourceTemplateIDs: [cameraKitID],
            departureDate: Calendar.current.date(byAdding: .day, value: 18, to: .now)!,
            returnDate: Calendar.current.date(byAdding: .day, value: 21, to: .now)!,
            items: [
                TripItem(name: "4-Season Dome Tent", category: "Shelter", owner: "Shared", priority: .critical, isPacked: true),
                TripItem(name: "Jetboil Flash Stove + Fuel", category: "Camp Kitchen", owner: "Alex", priority: .high, isPacked: true),
                TripItem(name: "Mirrorless Body + 24-70mm f/2.8", category: "Camera Gear", owner: "Alex", priority: .critical, isPacked: false)
            ],
            members: ["Alex", "Sam"],
            travelMode: .car,
            status: .active
        )

        let completedTrip = TripInstance(
            name: "Kyoto Autumn Foliage",
            icon: .international,
            destination: TripDestination(name: "Kyoto", latitude: 35.0116, longitude: 135.7681, country: "Japan"),
            sourceTemplateIDs: [baseEssentialsID, cameraKitID],
            departureDate: Calendar.current.date(byAdding: .day, value: -40, to: .now)!,
            returnDate: Calendar.current.date(byAdding: .day, value: -30, to: .now)!,
            items: [
                TripItem(name: "Passport & Global Entry Card", category: "Documents", owner: "Alex", priority: .critical, isPacked: true),
                TripItem(name: "Universal GaN 100W Adapter", category: "Electronics", owner: "Alex", priority: .high, isPacked: true),
                TripItem(name: "Mirrorless Body + 24-70mm f/2.8", category: "Camera Gear", owner: "Alex", priority: .critical, isPacked: true),
                TripItem(name: "JR Pass Exchange Voucher", category: "Documents", owner: "Alex", priority: .critical, isPacked: true, isAdHoc: true)
            ],
            status: .completed
        )

        store.trips = [activeTrip, secondActiveTrip, completedTrip]
        store.selectedTripID = activeTrip.id
        store.selectedTemplateID = alpineTemplate.id
        store.rebuildCaches()

        return (store, activeTrip, alpineTemplate)
    }

    func testGenerateDocumentationScreenshots() throws {
        let size = CGSize(width: 1440, height: 900)
        let (store, activeTrip, alpineTemplate) = makeSyntheticStore()

        // 1. Trip Packing Workbench
        let workbenchView = HStack(spacing: 0) {
            SidebarView(selection: .constant(.tripsActive))
                .frame(width: 210)
            Divider()
            TripListView(
                trips: store.activeTrips,
                status: .active,
                title: "Active Trips",
                showNewTripSheet: .constant(false),
                onCollapse: {},
                onExpand: {}
            )
            .frame(width: 245)
            Divider()
            TripDetailView(trip: activeTrip, showSystemInspector: false)
                .frame(width: 715)
            Divider()
            TripInspectorView(trip: activeTrip, activeSheet: .constant(nil), pendingReminders: 2)
                .frame(width: 270)
        }
        .environment(store)
        .background(Color(NSColor.windowBackgroundColor))

        let workbenchCallouts: [DocCallout] = [
            DocCallout(
                number: 1,
                title: "Pinned & Status Sidebar",
                subtitle: "Jump to pinned or active trips",
                targetRect: CGRect(x: 10, y: 40, width: 190, height: 220),
                badgeCenter: CGPoint(x: 165, y: 315),
                color: .cyan
            ),
            DocCallout(
                number: 2,
                title: "Progress Ring & Mode Tabs",
                subtitle: "Switch Packing, Meals & Procedures",
                targetRect: CGRect(x: 470, y: 12, width: 690, height: 86),
                badgeCenter: CGPoint(x: 315, y: 410),
                color: .orange
            ),
            DocCallout(
                number: 3,
                title: "6-Tier Prep Timeline",
                subtitle: "Countdown tasks from 2wks to Return",
                targetRect: CGRect(x: 470, y: 150, width: 225, height: 340),
                badgeCenter: CGPoint(x: 315, y: 500),
                color: .purple
            ),
            DocCallout(
                number: 4,
                title: "Categorized Packing Grid",
                subtitle: "Priority dots, owners & Ad-Hoc badges",
                targetRect: CGRect(x: 705, y: 150, width: 455, height: 630),
                badgeCenter: CGPoint(x: 930, y: 835),
                color: .green
            ),
            DocCallout(
                number: 5,
                title: "TODOs & Markdown Notes",
                subtitle: "Trip errands and field notes",
                targetRect: CGRect(x: 1180, y: 16, width: 250, height: 615),
                badgeCenter: CGPoint(x: 1300, y: 690),
                color: .pink
            )
        ]

        try renderAnnotatedScreenshot(
            workbenchView,
            callouts: workbenchCallouts,
            size: size,
            to: "docs/assets/trip_packing_workbench.png"
        )

        // 2. Templates & Composite Reuse
        let templatesView = HStack(spacing: 0) {
            SidebarView(selection: .constant(.templates))
                .frame(width: 210)
            Divider()
            TemplateListView(showNewTemplateSheet: .constant(false))
                .frame(width: 270)
            Divider()
            TemplateDetailView(template: alpineTemplate)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(store)
        .background(Color(NSColor.windowBackgroundColor))

        let templatesCallouts: [DocCallout] = [
            DocCallout(
                number: 1,
                title: "Reusable Template Library",
                subtitle: "Modular lists with item counts",
                targetRect: CGRect(x: 220, y: 40, width: 250, height: 220),
                badgeCenter: CGPoint(x: 335, y: 320),
                color: .cyan
            ),
            DocCallout(
                number: 2,
                title: "Context Tags & Metadata",
                subtitle: "Tag templates for smart filtering",
                targetRect: CGRect(x: 500, y: 16, width: 915, height: 110),
                badgeCenter: CGPoint(x: 335, y: 410),
                color: .orange
            ),
            DocCallout(
                number: 3,
                title: "Composite Linked Templates",
                subtitle: "Auto-include Core & Camera kits",
                targetRect: CGRect(x: 500, y: 138, width: 520, height: 64),
                badgeCenter: CGPoint(x: 1210, y: 170),
                color: .purple
            ),
            DocCallout(
                number: 4,
                title: "Template Prep & Procedures",
                subtitle: "Reusable pre-trip tasks & workflows",
                targetRect: CGRect(x: 500, y: 215, width: 915, height: 640),
                badgeCenter: CGPoint(x: 335, y: 500),
                color: .green
            )
        ]

        try renderAnnotatedScreenshot(
            templatesView,
            callouts: templatesCallouts,
            size: size,
            to: "docs/assets/templates_and_composites.png"
        )

        // 3. Meal Planning & Phase Procedures
        let mealsAndProceduresView = HStack(spacing: 0) {
            SidebarView(selection: .constant(.tripsActive))
                .frame(width: 210)
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Label("Day-by-Day Meal Plan — \(activeTrip.name)", systemImage: "fork.knife")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                Divider()
                MealPlanView(trip: activeTrip)
            }
            .frame(width: 710)
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Label("Phase Procedures", systemImage: "checklist.checked")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                Divider()
                ProcedureChecklistView(trip: activeTrip)
            }
            .frame(width: 520)
        }
        .environment(store)
        .background(Color(NSColor.windowBackgroundColor))

        let mealsCallouts: [DocCallout] = [
            DocCallout(
                number: 1,
                title: "Provisioning & Prep Notes",
                subtitle: "Camp kitchen notes and ration summary",
                targetRect: CGRect(x: 226, y: 54, width: 678, height: 75),
                badgeCenter: CGPoint(x: 740, y: 26),
                color: .orange
            ),
            DocCallout(
                number: 2,
                title: "Day × Meal Planning Grid",
                subtitle: "Breakfast, Lunch, Dinner, Snacks & Drinks",
                targetRect: CGRect(x: 226, y: 138, width: 678, height: 480),
                badgeCenter: CGPoint(x: 565, y: 735),
                color: .cyan
            ),
            DocCallout(
                number: 3,
                title: "4-Phase Step-by-Step Procedures",
                subtitle: "Ordered checklists for Departure & Arrival",
                targetRect: CGRect(x: 936, y: 54, width: 488, height: 615),
                badgeCenter: CGPoint(x: 1180, y: 735),
                color: .green
            )
        ]

        try renderAnnotatedScreenshot(
            mealsAndProceduresView,
            callouts: mealsCallouts,
            size: size,
            to: "docs/assets/meals_and_procedures.png"
        )

        // 4. Packing Statistics Dashboard
        let statsView = HStack(spacing: 0) {
            SidebarView(selection: .constant(.statistics))
                .frame(width: 210)
            Divider()
            StatisticsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(store)
        .background(Color(NSColor.windowBackgroundColor))

        let statsCallouts: [DocCallout] = [
            DocCallout(
                number: 1,
                title: "Lifetime Packing KPIs",
                subtitle: "Total trips, items packed, and completion rate",
                targetRect: CGRect(x: 226, y: 58, width: 1190, height: 95),
                badgeCenter: CGPoint(x: 820, y: 28),
                color: .cyan
            ),
            DocCallout(
                number: 2,
                title: "Most Packed & Ad-Hoc Insights",
                subtitle: "Spot frequent ad-hoc items to promote",
                targetRect: CGRect(x: 226, y: 170, width: 585, height: 490),
                badgeCenter: CGPoint(x: 520, y: 720),
                color: .orange
            ),
            DocCallout(
                number: 3,
                title: "Category & Template Analytics",
                subtitle: "Distribution across gear categories",
                targetRect: CGRect(x: 825, y: 170, width: 590, height: 490),
                badgeCenter: CGPoint(x: 1120, y: 720),
                color: .purple
            )
        ]

        try renderAnnotatedScreenshot(
            statsView,
            callouts: statsCallouts,
            size: size,
            to: "docs/assets/packing_statistics.png"
        )
    }
}
