import SwiftUI
import LocalAuthentication
import CoreSpotlight

struct ContentView: View {
    @State private var store = NotesStore()
    @State private var selectedFilter: NoteFilter? = .all
    @State private var selectedNoteId: UUID?

    @AppStorage("isBiometricEnabled") private var isBiometricEnabled = false
    @State private var isUnlocked = false
    @State private var showLockError = false

    var body: some View {
        ZStack {
            if isBiometricEnabled && !isUnlocked {
                UnlockView(authenticate: authenticate, showLockError: showLockError)
            } else {
                AppMainView(store: store, selectedFilter: $selectedFilter, selectedNoteId: $selectedNoteId)
            }

            if store.isLoading {
                loadingOverlay
            }
        }
        .animation(.default, value: store.isLoading)
        .onAppear {
            if isBiometricEnabled {
                authenticate()
            } else {
                isUnlocked = true
            }
            store.loadMetadata()
        }
        .onChange(of: isBiometricEnabled) { oldValue, newValue in
            if !newValue { isUnlocked = true }
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            if let idString = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
               let uuid = UUID(uuidString: idString) {
                selectedNoteId = uuid
                selectedFilter = .all
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewNote)) { _ in
            let id = store.addNote()
            selectedNoteId = id
            selectedFilter = .all
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).opacity(0.4)
            ProgressView("Loading Library...")
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }
        .transition(.opacity)
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Quillpad") { success, authenticationError in
                Task { @MainActor in
                    withAnimation {
                        if success {
                            self.isUnlocked = true
                            self.showLockError = false
                        } else {
                            self.showLockError = true
                        }
                    }
                }
            }
        } else {
            self.showLockError = true
        }
    }
}
