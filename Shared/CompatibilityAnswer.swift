import Foundation

enum CompatibilityAnswer: String, Codable, Sendable, CaseIterable, Identifiable {
    case personal
    case workOrSchool
    case unsure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .personal:
            "This is my personal iPhone"
        case .workOrSchool:
            "Work or school manages this iPhone"
        case .unsure:
            "I'm not sure"
        }
    }

    var blocksExactAppRouting: Bool {
        switch self {
        case .personal:
            false
        case .workOrSchool, .unsure:
            true
        }
    }
}
