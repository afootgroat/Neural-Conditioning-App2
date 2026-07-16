import Foundation

/// Curated preferred-emotion presets for the wizard. Each carries an identity
/// hue and a few mantra suggestions written in the app's quiet voice.
struct EmotionPreset: Identifiable, Equatable {
    var name: String
    var hue: PathwayHue
    var mantras: [String]

    var id: String { name }

    static let all: [EmotionPreset] = [
        EmotionPreset(name: "Calm", hue: .tide, mantras: [
            "This moment is not an emergency.",
            "I can slow everything down.",
            "Still water runs beneath this.",
        ]),
        EmotionPreset(name: "Compassion", hue: .dawn, mantras: [
            "They are carrying something too.",
            "Soft heart, steady hands.",
            "I can be kind before I am right.",
        ]),
        EmotionPreset(name: "Curiosity", hue: .glacier, mantras: [
            "Interesting — what is really happening here?",
            "What else could this mean?",
            "I wonder what I'll do next.",
        ]),
        EmotionPreset(name: "Gratitude", hue: .honey, mantras: [
            "Even this is part of a good life.",
            "I have more than this moment is taking.",
            "Thank you, anyway.",
        ]),
        EmotionPreset(name: "Patience", hue: .moss, mantras: [
            "There is time inside this moment.",
            "Nothing needs to happen yet.",
            "I move at my own weather.",
        ]),
        EmotionPreset(name: "Confidence", hue: .ember, mantras: [
            "I have handled harder than this.",
            "My ground does not move.",
            "I choose my next move.",
        ]),
        EmotionPreset(name: "Playfulness", hue: .orchid, mantras: [
            "This is a strange little game.",
            "Lightly, lightly.",
            "I can hold this loosely.",
        ]),
        EmotionPreset(name: "Acceptance", hue: .iris, mantras: [
            "It is allowed to be like this.",
            "I don't argue with what already is.",
            "Here is where I begin.",
        ]),
    ]

    static func named(_ name: String) -> EmotionPreset? {
        all.first { $0.name == name }
    }
}
