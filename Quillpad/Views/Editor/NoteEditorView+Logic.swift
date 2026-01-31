import SwiftUI
import AppKit
import PencilKit
import UserNotifications

extension NoteEditorView {
    func saveSketch() {
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: 1.0)
        guard let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data),
              let pngData = bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else { return }

        let filename = "Sketch-\(UUID().uuidString).png"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        try? pngData.write(to: tempURL)
        importAttachment(from: tempURL)

        let md = "\n![Sketch](\(filename))\n"
        session.content += md
        session.note.content = session.content
        session.saveNow()

        canvasView.clear()
    }

    func toggleTag(_ name: String) {
        if session.note.tags.contains(name) {
            session.note.tags.removeAll { $0 == name }
        } else {
            session.note.tags.append(name)
        }
        session.saveNow()
    }

    func addReminder(date: Date) {
        session.note.reminders.append(date)
        session.saveNow()

        let content = UNMutableNotificationContent()
        content.title = session.note.title
        content.body = session.note.preview
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func importAttachment(from url: URL) {
        guard let noteURL = session.note.fileURL else { return }
        let destFolder = noteURL.deletingLastPathComponent()
        let destURL = destFolder.appendingPathComponent(url.lastPathComponent)

        do {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                try FileManager.default.copyItem(at: url, to: destURL)
            } else {
                 try FileManager.default.copyItem(at: url, to: destURL)
            }

            session.note.attachments.append(url.lastPathComponent)
            session.saveNow()
        } catch {
            print("Failed to import: \(error)")
        }
    }

    func startRecording() {
        guard let url = session.note.fileURL else { return }
        let filename = "Recording_\(Date().formatted(date: .numeric, time: .standard).replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: "/", with: "-")).m4a"
        let fileURL = url.deletingLastPathComponent().appendingPathComponent(filename)
        session.audioRecorder.startRecording(to: fileURL) { success in 
            if success {
                 session.note.attachments.append(filename)
                 session.saveNow()
            }
        }
    }

    func stopRecording() {
        session.audioRecorder.stopRecording()
    }

    func playAudio(_ filename: String) {
        guard let url = session.note.fileURL else { return }
        let fileURL = url.deletingLastPathComponent().appendingPathComponent(filename)
        session.audioRecorder.play(url: fileURL)
    }
}
