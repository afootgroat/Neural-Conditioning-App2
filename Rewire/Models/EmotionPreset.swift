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
            "Soft shoulders, open breath.",
        ]),
        EmotionPreset(name: "Compassion", hue: .dawn, mantras: [
            "They are carrying something too.",
            "Soft heart, steady hands.",
            "I can be kind before I am right.",
        ]),
        EmotionPreset(name: "Curiosity", hue: .glacier, mantras: [
            "Interesting — what is really happening here?",
            "What else could this mean?",
            "What would a more useful perspective be?",
        ]),
        EmotionPreset(name: "Gratitude", hue: .honey, mantras: [
            "Even this is part of a good life.",
            "One small mercy is enough to start.",
            "Thank you, anyway.",
        ]),
        EmotionPreset(name: "Patience", hue: .moss, mantras: [
            "I can wait one more breath.",
            "Nothing needs to happen yet.",
            "Slow is still forward.",
        ]),
        EmotionPreset(name: "Confidence", hue: .ember, mantras: [
            "I act from the center, not the edge.",
            "My ground does not move.",
            "I choose my next move.",
        ]),
        EmotionPreset(name: "Playfulness", hue: .orchid, mantras: [
            "This is a strange little game.",
            "A little lightness won't break me.",
            "I can smile at the absurdity.",
        ]),
        EmotionPreset(name: "Acceptance", hue: .iris, mantras: [
            "Letting it be frees my next move.",
            "I don't argue with what already is.",
            "Resistance is optional.",
        ]),
    ]

    static func named(_ name: String) -> EmotionPreset? {
        all.first { $0.name == name }
    }
}
