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
        let tideData = zip(dates, heights).map { ($0, $1) }
        
        var events: [TideEvent] = []
        for i in 1..<(tideData.count - 1) {
            let prev = tideData[i-1].1
            let curr = tideData[i].1
            let next = tideData[i+1].1
            
            if curr > prev && curr > next {
                events.append(TideEvent(date: tideData[i].0, type: .high, heightMeters: curr))
            } else if curr < prev && curr < next {
                events.append(TideEvent(date: tideData[i].0, type: .low, heightMeters: curr))
            }
        }
        
        #expect(events.count == 2)
        #expect(events[0].type == .high)
        #expect(events[0].heightMeters == 2.0)
        #expect(events[1].type == .low)
        #expect(events[1].heightMeters == -2.0)
    }
}
