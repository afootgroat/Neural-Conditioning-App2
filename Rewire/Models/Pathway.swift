import SwiftUI

// MARK: - Rep stage (the four beats of one rep)

/// One rep = TRIGGER → NOTICE → ACCEPT → CHOOSE. Completing CHOOSE fires the rep.
enum RepStage: Int, CaseIterable, Codable {
    case trigger, notice, accept, choose

    var title: String {
        switch self {
        case .trigger: "Trigger"
        case .notice:  "Notice"
        case .accept:  "Accept"
        case .choose:  "Choose"
        }
    }

    /// Fixed semantic hue — a rep is a journey from heat to cool.
    var color: Color {
        switch self {
        case .trigger: Color(hex: 0xFF5C39) // ember
        case .notice:  Color(hex: 0xFFC24B) // gold
        case .accept:  Color(hex: 0x3EDDC5) // teal
        case .choose:  Color(hex: 0x8B7BFF) // violet
        }
    }

    var next: RepStage {
        RepStage(rawValue: (rawValue + 1) % RepStage.allCases.count)!
    }

    /// Short instruction shown under the stage name while training.
    var hint: String {
        switch self {
        case .trigger: "Summon the moment"
        case .notice:  "See it happening"
        case .accept:  "Let it be here"
        case .choose:  "Take the new path"
        }
    }
}

// MARK: - Maturity

/// A pathway matures through five named stages as lifetime reps accumulate.
enum MaturityStage: Int, CaseIterable, Codable, Comparable {
    case disruption, foundation, strengthening, stabilizing, enlightenment

    static func < (lhs: MaturityStage, rhs: MaturityStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .disruption:    "Disruption"
        case .foundation:    "Foundation"
        case .strengthening: "Strengthening"
        case .stabilizing:   "Stabilizing"
        case .enlightenment: "Enlightenment"
        }
    }

    /// Lifetime reps required to *enter* this stage.
    var threshold: Int {
        switch self {
        case .disruption:    0
        case .foundation:    50
        case .strengthening: 150
        case .stabilizing:   400
        case .enlightenment: 1000
        }
    }

    /// One quiet line describing what this stage means.
    var meaning: String {
        switch self {
        case .disruption:    "The pattern is seen."
        case .foundation:    "A new groove begins."
        case .strengthening: "The groove deepens."
        case .stabilizing:   "The new path is default."
        case .enlightenment: "The old pattern is a memory."
        }
    }

    var next: MaturityStage? {
        MaturityStage(rawValue: rawValue + 1)
    }

    static func stage(forLifetimeReps reps: Int) -> MaturityStage {
        allCases.last(where: { reps >= $0.threshold }) ?? .disruption
    }
}

// MARK: - Identity hue

/// Eight curated identity hues. Stored by name so the palette can be tuned
/// later without breaking persisted data.
enum PathwayHue: String, CaseIterable, Codable {
    case dawn, ember, honey, moss, tide, glacier, iris, orchid

    var color: Color {
        switch self {
        case .dawn:    Color(hex: 0xFF8E72)
        case .ember:   Color(hex: 0xFF5C39)
        case .honey:   Color(hex: 0xFFC24B)
        case .moss:    Color(hex: 0x9BD77A)
        case .tide:    Color(hex: 0x3EDDC5)
        case .glacier: Color(hex: 0x6FB8FF)
        case .iris:    Color(hex: 0x8B7BFF)
        case .orchid:  Color(hex: 0xD98BF5)
        }
    }
}

// MARK: - Pathway

struct Pathway: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()

    // Blueprint
    var name: String = ""
    var stimulus: String = ""
    var oldFeelings: String = ""
    var oldThoughts: String = ""
    var oldBehavior: String = ""
    var emotionName: String = ""
    var mantra: String = ""
    var hue: PathwayHue = .iris

    // Life
    var createdAt: Date = .now
    var archivedAt: Date? = nil

    // Training
    var lifetimeReps: Int = 0
    /// Calendar-day rep counts, keyed by DayKey ("2026-07-15").
    var repLog: [String: Int] = [:]

    // MARK: Derived

    var isArchived: Bool { archivedAt != nil }

    var maturity: MaturityStage { .stage(forLifetimeReps: lifetimeReps) }

    var todayReps: Int { repLog[DayKey.today] ?? 0 }

    var practicedToday: Bool { todayReps > 0 }

    /// 0…1 progress from the current maturity stage toward the next.
    /// Enlightenment holds at 1.
    var progressToNextStage: Double {
        guard let next = maturity.next else { return 1 }
        let floor = maturity.threshold
        let span = Double(next.threshold - floor)
        return min(1, Double(lifetimeReps - floor) / span)
    }

    var repsToNextStage: Int? {
        maturity.next.map { max(0, $0.threshold - lifetimeReps) }
    }

    mutating func logRep(on day: String = DayKey.today) {
        lifetimeReps += 1
        repLog[day, default: 0] += 1
    }
}

// MARK: - Day keys

enum DayKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static var today: String { key(for: .now) }

    static func key(for date: Date) -> String { formatter.string(from: date) }
}
