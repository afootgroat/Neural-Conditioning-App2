import SwiftUI

/// Soft confirmation before resting a pathway — set down, not delete.
struct RestConfirmSheet: View {
    var pathwayName: String
    var onKeep: () -> Void
    var onRest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Circle()
                .fill(Color(hex: 0x8B7BFF).opacity(0.14))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(hex: 0x8B7BFF))
                }
                .shadow(color: Color(hex: 0x8B7BFF).opacity(0.25), radius: 12)
                .padding(.bottom, 16)

            Text("Rest “\(pathwayName)”?")
                .font(.voice(24, weight: .medium))
                .foregroundStyle(Ink.textPrimary)
                .padding(.bottom, 8)

            Text("It’ll wait quietly with the others. You can wake it anytime — nothing is lost.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Ink.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 22)

            HStack(spacing: 10) {
                Button(action: onKeep) {
                    Text("Keep")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Ink.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background {
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                                .overlay(Capsule().stroke(Ink.hairline, lineWidth: 1))
                        }
                }
                .buttonStyle(PressableStyle(scale: 0.97))

                Button(action: onRest) {
                    Text("Rest")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Ink.base)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background {
                            Capsule()
                                .fill(Color(hex: 0x8B7BFF).opacity(0.92))
                        }
                }
                .buttonStyle(PressableStyle(scale: 0.97))
            }
        }
        .padding(28)
        .padding(.bottom, 4)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Ink.raised.opacity(0.72))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
    }
}
