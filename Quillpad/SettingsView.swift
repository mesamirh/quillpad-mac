import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("defaultNotebook") private var defaultNotebook = "Personal"
    @AppStorage("editorFontSize") private var editorFontSize = 14.0
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("syncFolderBookmark") private var syncFolderBookmark: Data?

    @State private var syncFolderPath: String = "Default (Documents/Quillpad)"

    var body: some View {
        TabView {
            GeneralSettingsView(defaultNotebook: $defaultNotebook)
                .tabItem { Label("General", systemImage: "gear") }

            AppearanceSettingsView(editorFontSize: $editorFontSize, appTheme: $appTheme)
                .tabItem { Label("Appearance", systemImage: "paintpalette") }

            SecuritySettingsView()
                .tabItem { Label("Security", systemImage: "lock.shield") }

            SyncSettingsView(syncFolderBookmark: $syncFolderBookmark, syncFolderPath: $syncFolderPath)
                .tabItem { Label("Sync", systemImage: "arrow.triangle.2.circlepath") }

            BackupSettingsView(syncFolderBookmark: $syncFolderBookmark)
                .tabItem { Label("Backup", systemImage: "externaldrive") }

            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 500, height: 350)
        .onAppear {
            updateSyncPathDisplay()
        }
    }

    private func updateSyncPathDisplay() {
        if let bookmark = syncFolderBookmark {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                syncFolderPath = url.path

                if isStale {
                    let newBookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    syncFolderBookmark = newBookmark
                }
            } catch {
                print("Failed to resolve bookmark in settings: \(error)")
            }
        }
    }
}

struct BackupSettingsView: View {
    @Binding var syncFolderBookmark: Data?
    @State private var statusMessage = ""

    private var rootURL: URL {
        if let bookmark = syncFolderBookmark {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                return url
            }
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Quillpad")
    }

    var body: some View {
        Form {
            Section {
                Text("Create a ZIP backup of your entire library.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Export Backup...") {
                    exportBackup()
                }
            } header: {
                Text("Backup")
            }

            Section {
                Text("Restore from a ZIP file. WARNING: This will overwrite existing files.")
                    .font(.caption)
                    .foregroundStyle(.red)

                Button("Restore from Backup...") {
                    importBackup()
                }
            } header: {
                Text("Restore")
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .padding(.top)
            }
        }
        .padding()
    }

    private func exportBackup() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        panel.nameFieldStringValue = "QuillpadBackup_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).zip"

        panel.begin { response in
            if response == .OK, let destURL = panel.url {
                createZip(at: destURL)
            }
        }
    }

    private func importBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.zip]
        panel.allowsMultipleSelection = false

        panel.begin { response in
            if response == .OK, let srcURL = panel.url {
                restoreZip(from: srcURL)
            }
        }
    }

    private func createZip(at destURL: URL) {
        let destPath = destURL.path
        statusMessage = "Creating backup..."

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", destPath, "."]
        process.currentDirectoryURL = rootURL

        process.terminationHandler = { proc in
            Task { @MainActor in
                if proc.terminationStatus == 0 {
                    statusMessage = "Backup created successfully."
                } else {
                    statusMessage = "Backup failed (Code \(proc.terminationStatus))."
                }
            }
        }

        do {
            try process.run()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    private func restoreZip(from srcURL: URL) {
        let sourcePath = srcURL.path
        let destPath = rootURL.path
        statusMessage = "Restoring library..."

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", sourcePath, "-d", destPath]

        process.terminationHandler = { proc in
            Task { @MainActor in
                if proc.terminationStatus == 0 {
                    statusMessage = "Restore successful."
                } else {
                    statusMessage = "Restore failed (Code \(proc.terminationStatus))."
                }
            }
        }

        do {
            try process.run()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
}

struct GeneralSettingsView: View {
    @Binding var defaultNotebook: String

    var body: some View {
        Form {
            TextField("Default Notebook Name", text: $defaultNotebook)
                .help("The name of the notebook (folder) where new notes are saved by default.")
        }
        .padding()
    }
}

struct AppearanceSettingsView: View {
    @Binding var editorFontSize: Double
    @Binding var appTheme: String

    var body: some View {
        Form {
            Picker("Theme", selection: $appTheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.inline)

            Divider()

            Slider(value: $editorFontSize, in: 10...30, step: 1) {
                Text("Editor Font Size: \(Int(editorFontSize)) pt")
            }
        }
        .padding()
    }
}

struct SecuritySettingsView: View {
    @AppStorage("isBiometricEnabled") private var isBiometricEnabled = false

    var body: some View {
        Form {
            Section {
                Toggle("Require Biometrics to Unlock", isOn: $isBiometricEnabled)
                    .toggleStyle(.switch)

                Text("When enabled, Quillpad will require Touch ID, Face ID, or your system password to open.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("App Lock")
            }
        }
        .padding()
    }
}

struct SyncSettingsView: View {
    @Binding var syncFolderBookmark: Data?
    @Binding var syncFolderPath: String

    var body: some View {
        Form {
            Section {
                Text("Quillpad stores notes as Markdown files. Select a folder to sync with your Android device (e.g., via Nextcloud, Syncthing, or iCloud).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                HStack {
                    Image(systemName: "folder")
                    Text(syncFolderPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Change...") {
                        selectFolder()
                    }
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))

                Button("Show in Finder") {
                    if let url = getSyncURL() {
                        NSWorkspace.shared.open(url)
                    }
                }
                .disabled(getSyncURL() == nil)
            } header: {
                Text("Storage Location")
            }
        }
        .padding()
    }

    private func getSyncURL() -> URL? {
        if let bookmark = syncFolderBookmark {
            var isStale = false
            return try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        }

        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Quillpad")
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Sync Folder"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    syncFolderBookmark = bookmark
                    syncFolderPath = url.path
                } catch {
                    print("Failed to create bookmark: \(error)")
                }
            }
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            VStack(spacing: 4) {
                Text("Quillpad")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("A native, privacy-focused note-taking app compatible with Quillpad for Android.")
                .multilineTextAlignment(.center)
                .font(.body)
                .padding(.horizontal)

            Link("Visit Website", destination: URL(string: "https://github.com/quillpad/quillpad")!)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
