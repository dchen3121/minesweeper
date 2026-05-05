import SwiftUI

struct HeaderView: View {
    let remainingMines: Int
    let elapsedSeconds: Int
    let smileyFace: String
    let onReset: () -> Void

    var body: some View {
        HStack {
            CounterDisplay(value: remainingMines)
            Spacer()
            SmileyButton(face: smileyFace, action: onReset)
            Spacer()
            CounterDisplay(value: elapsedSeconds)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct CounterDisplay: View {
    let value: Int

    var body: some View {
        Text(formatted)
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundStyle(.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var formatted: String {
        let clamped = max(-99, min(value, 999))
        if clamped < 0 {
            return String(format: "-%02d", abs(clamped))
        }
        return String(format: "%03d", clamped)
    }
}

private struct SmileyButton: View {
    let face: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(face)
                .font(.system(size: 34))
                .scaleEffect(isPressed ? 0.85 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}
