import SwiftUI
import Observation
import UniformTypeIdentifiers

@Observable
@MainActor
class NoteEditorSession {
    var note: Note
    var content: String = ""
    var isPreviewMode: Bool = false
    var localNotebookName: String?

    let store: NotesStore
    let audioRecorder = AudioRecorder()

    private var saveTask: Task<Void, Never>?

    init(note: Note, store: NotesStore) {
        self.note = note
        self.store = store
        self.content = note.content ?? ""
        self.localNotebookName = note.notebookName
    }

    func loadContent() async {
        if !note.isLoaded {
            await store.loadContent(for: note.id)
            if let updatedNote = store.notes.first(where: { $0.id == note.id }) {
                self.note = updatedNote
                self.content = updatedNote.content ?? ""
            }
        }
    }

    func handleContentChange(_ newValue: String) {
        if note.content != newValue {
            note.content = newValue
            queueSave()
        }
    }

    func queueSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                saveNow()
            }
        }
    }

    func saveNow() {
        store.saveNote(note)
    }
}
