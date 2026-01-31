import SwiftUI
import AppKit
import PencilKit
import UserNotifications
import UniformTypeIdentifiers

struct NoteEditorView: View {
    @Binding var note: Note
    var store: NotesStore
    @AppStorage("editorFontSize") private var editorFontSize = 14.0
    @Environment(\.undoManager) var undoManager

    @State var session: NoteEditorSession

    @State private var showAddTag = false
    @State private var newTagName = ""
    @State private var showFileImporter = false

    @State private var showSketchPad = false
    @State var canvasView = SimpleCanvasView()

    @State private var showReminderPicker = false
    @State private var newReminderDate = Date()

    init(note: Binding<Note>, store: NotesStore) {
        self._note = note
        self.store = store
        self._session = State(initialValue: NoteEditorSession(note: note.wrappedValue, store: store))
    }

    var body: some View {
        VStack(spacing: 0) {
            if let colorString = session.note.color {
                Rectangle()
                    .fill(Color(hex: colorString))
                    .frame(height: 4)
            }

            NoteHeaderView(note: $session.note, onSave: { session.saveNow() })

            Divider()

            EditorContentView(
                content: $session.content,
                isPreviewMode: $session.isPreviewMode,
                fontSize: editorFontSize,
                note: session.note
            )
            .onChange(of: session.content) { _, newValue in
                session.handleContentChange(newValue)
            }

            AudioRecordingBarView(audioRecorder: session.audioRecorder, stopRecording: stopRecording)

            AttachmentsBarView(note: $session.note, store: store, playAudio: playAudio)

            Divider()

            NoteFooterView(content: session.content, updatedDate: session.note.updatedAt)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .navigationTitle(session.note.title.isEmpty ? "Untitled Note" : session.note.title)
        .navigationSubtitle(session.note.notebookName ?? "No Notebook")
        .task {
            await session.loadContent()
        }
        .onChange(of: session.localNotebookName) { oldValue, newValue in
            if session.note.notebookName != newValue {
                session.note.notebookName = newValue
                session.saveNow()
            }
        }
        .toolbar {
            NoteToolbarView(
                context: EditorContext(
                    isPreviewMode: session.isPreviewMode,
                    isRecording: session.audioRecorder.isRecording,
                    canUndo: undoManager?.canUndo ?? false,
                    canRedo: undoManager?.canRedo ?? false,
                    note: session.note,
                    notebooks: store.notebooks,
                    allTags: store.tags,
                    currentNotebookName: session.localNotebookName
                ),
                intentHandler: handleIntent
            )
        }
    }

    private func handleIntent(_ intent: ToolbarIntent) {
        switch intent {
        case .undo: undoManager?.undo()
        case .redo: undoManager?.redo()
        case .insertMarkdown(let prefix, let suffix):
            let newText = prefix + "text" + suffix
            if session.content.isEmpty {
                session.content = newText
            } else {
                session.content += "\n" + newText
            }
            session.note.content = session.content
        case .startRecording: startRecording()
        case .togglePreview: session.isPreviewMode.toggle()
        case .save: session.saveNow()
        case .showSketch: showSketchPad = true
        case .showFileImporter: showFileImporter = true
        case .showReminderPicker: showReminderPicker = true
        case .showAddTag: showAddTag = true
        case .togglePinned:
            session.note.isPinned.toggle()
            session.saveNow()
        case .toggleHidden:
            session.note.isHidden.toggle()
            session.saveNow()
        case .toggleArchived:
            session.note.isArchived.toggle()
            session.saveNow()
        case .toggleDeleted:
            session.note.isDeleted.toggle()
            session.saveNow()
        case .setNotebook(let name):
            session.localNotebookName = name
        case .toggleTag(let name):
            toggleTag(name)
        case .setNoteColor(let color):
            session.note.color = color
            session.saveNow()
        }
    }
}
    