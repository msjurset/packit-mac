import Testing
import Foundation
@testable import PackIt

@Suite("Tide Calculations")
struct TideTests {
    @Test("identify peaks and troughs")
    func identifyExtrema() {
        // Mock hourly heights: sine wave-like
        let heights: [Double] = [0, 1, 2, 1, 0, -1, -2, -1, 0]
        let dates = (0..<heights.count).map { Date(timeIntervalSince1970: TimeInterval($0 * 3600)) }
        let points = zip(dates, heights).map { (date: $0, heightMeters: $1) }
        
        let events = TideEvent.processExtrema(points: points)
        
        #expect(events.count == 2)
        #expect(events[0].type == .high)
        #expect(events[0].heightMeters == 2.0)
        #expect(events[1].type == .low)
        #expect(events[1].heightMeters == -2.0)
    }

    @Test("handles fewer than 3 points without crashing")
    func boundaryConditions() {
        let now = Date()
        
        // 0 points
        let emptyEvents = TideEvent.processExtrema(points: [])
        #expect(emptyEvents.isEmpty)
        
        // 1 point
        let singleEvents = TideEvent.processExtrema(points: [(date: now, heightMeters: 1.0)])
        #expect(singleEvents.isEmpty)
        
        // 2 points
        let doubleEvents = TideEvent.processExtrema(points: [
            (date: now, heightMeters: 1.0),
            (date: now.addingTimeInterval(3600), heightMeters: 2.0)
        ])
        #expect(doubleEvents.isEmpty)
    }
}
