import SwiftUI

struct UnlockView: View {
    let authenticate: () -> Void
    let showLockError: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text("Quillpad is Locked")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Authentication is required to access your notes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(action: authenticate) {
                Label("Unlock with Touch ID", systemImage: "touchid")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if showLockError {
                 Text("Authentication Failed. Please try again.")
                     .foregroundColor(.red)
                     .font(.caption)
                     .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}
