import SwiftUI

struct BlinkModifier: ViewModifier {
    @State private var blinking = false
    func body(content: Content) -> some View {
        content.opacity(blinking ? 0 : 1)
            .animation(.easeInOut(duration: 0.5).repeatForever(), value: blinking)
            .onAppear { blinking = true }
    }
}

extension View {
    func blink() -> some View {
        modifier(BlinkModifier())
    }
}
