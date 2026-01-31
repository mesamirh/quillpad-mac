import SwiftUI

enum ToolbarIntent {
    case undo, redo
    case insertMarkdown(prefix: String, suffix: String = "")
    case startRecording
    case togglePreview
    case save
    case showSketch
    case showFileImporter
    case showReminderPicker
    case showAddTag
    case togglePinned
    case toggleHidden
    case toggleArchived
    case toggleDeleted
    case setNotebook(String?)
    case toggleTag(String)
    case setNoteColor(String?)
}

struct EditorContext {
    let isPreviewMode: Bool
    let isRecording: Bool
    let canUndo: Bool
    let canRedo: Bool
    let note: Note
    let notebooks: [Notebook]
    let allTags: [Tag]
    let currentNotebookName: String?
}

struct NoteToolbarView: ToolbarContent {
    let context: EditorContext
    let intentHandler: (ToolbarIntent) -> Void

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { intentHandler(.undo) }) { 
                Label("Undo", systemImage: "arrow.uturn.backward") 
            }
            .help("Undo")
            .disabled(context.isPreviewMode || !context.canUndo)

            Button(action: { intentHandler(.redo) }) { 
                Label("Redo", systemImage: "arrow.uturn.forward") 
            }
            .help("Redo")
            .disabled(context.isPreviewMode || !context.canRedo)

            Divider()

            Menu {
                Button("Heading 1") { intentHandler(.insertMarkdown(prefix: "# ")) }
                Button("Heading 2") { intentHandler(.insertMarkdown(prefix: "## ")) }
                Button("Heading 3") { intentHandler(.insertMarkdown(prefix: "### ")) }
            } label: {
                Label("Headings", systemImage: "textformat.size")
            }
            .disabled(context.isPreviewMode)

            Button(action: { intentHandler(.insertMarkdown(prefix: "**", suffix: "**")) }) { 
                Label("Bold", systemImage: "bold") 
            }
            .help("Bold")
            .disabled(context.isPreviewMode)
            .keyboardShortcut("b", modifiers: .command)

            Button(action: { intentHandler(.insertMarkdown(prefix: "*", suffix: "*")) }) { 
                Label("Italic", systemImage: "italic") 
            }
            .help("Italic")
            .disabled(context.isPreviewMode)
            .keyboardShortcut("i", modifiers: .command)

            Button(action: { intentHandler(.insertMarkdown(prefix: "- ")) }) { Label("List", systemImage: "list.bullet") }.help("Bulleted List").disabled(context.isPreviewMode)
            Button(action: { intentHandler(.insertMarkdown(prefix: "1. ")) }) { Label("Numbered List", systemImage: "list.number") }.help("Numbered List").disabled(context.isPreviewMode)
            Button(action: { intentHandler(.insertMarkdown(prefix: "- [ ] ")) }) { Label("Task", systemImage: "checkmark.square") }.help("Task List").disabled(context.isPreviewMode)
            Button(action: { intentHandler(.insertMarkdown(prefix: "[", suffix: "](url)")) }) { Label("Link", systemImage: "link") }.help("Insert Link").disabled(context.isPreviewMode)
            Button(action: { intentHandler(.insertMarkdown(prefix: "```\n", suffix: "\n```")) }) { Label("Code", systemImage: "chevron.left.forwardslash.chevron.right") }.help("Code Block").disabled(context.isPreviewMode)

            Divider()

            Button(action: { intentHandler(.startRecording) }) {
                Label("Record Voice", systemImage: "mic")
            }
            .disabled(context.isRecording)

            Button(action: { intentHandler(.showSketch) }) {
                Label("Sketch", systemImage: "scribble")
            }

            Button(action: { intentHandler(.showFileImporter) }) {
                Label("Attach", systemImage: "paperclip")
            }

            Divider()

            Toggle(isOn: Binding(get: { context.isPreviewMode }, set: { _ in intentHandler(.togglePreview) })) {
                Label("Preview", systemImage: "eye")
            }
            .help("Toggle Markdown Preview")

            Button(action: { intentHandler(.save) }) {
                Label("Save", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .help("Save Changes")
            .keyboardShortcut("s", modifiers: .command)

            infoMenu
        }
    }

    private var infoMenu: some View {
        Menu {
            Group {
                Button(action: { intentHandler(.togglePinned) }) {
                    Label(context.note.isPinned ? "Unpin" : "Pin", systemImage: "pin")
                }
                Button(action: { intentHandler(.toggleHidden) }) {
                    Label(context.note.isHidden ? "Unhide" : "Hide", systemImage: "eye.slash")
                }
                Button(action: { intentHandler(.toggleArchived) }) {
                    Label(context.note.isArchived ? "Unarchive" : "Archive", systemImage: "archivebox")
                }
                Button(action: { intentHandler(.toggleDeleted) }) {
                    Label(context.note.isDeleted ? "Restore" : "Delete", systemImage: "trash")
                }
            }
            Divider()
            Group {
                Button("Set Reminder...") { intentHandler(.showReminderPicker) }
                Divider()
                Picker("Notebook", selection: Binding(get: { context.currentNotebookName }, set: { intentHandler(.setNotebook($0)) })) {
                    Text("None").tag(Optional<String>.none)
                    ForEach(context.notebooks) { nb in
                        Text(nb.name).tag(Optional<String>.some(nb.name))
                    }
                }
            }
            Divider()
            Group {
                Menu("Tags") {
                    ForEach(context.allTags) { tag in
                        Button {
                            intentHandler(.toggleTag(tag.name))
                        } label: {
                            if context.note.tags.contains(tag.name) {
                                Label(tag.name, systemImage: "checkmark")
                            } else {
                                Text(tag.name)
                            }
                        }
                    }
                    Divider()
                    Button("Add New Tag...") { intentHandler(.showAddTag) }
                }
                Divider()
                Menu("Color") {
                    Button("None") { intentHandler(.setNoteColor(nil)) }
                    Button("Green") { intentHandler(.setNoteColor("#C5E1A5")) }
                    Button("Pink") { intentHandler(.setNoteColor("#F48FB1")) }
                    Button("Blue") { intentHandler(.setNoteColor("#81D4FA")) }
                    Button("Red") { intentHandler(.setNoteColor("#EF9A9A")) }
                    Button("Orange") { intentHandler(.setNoteColor("#FFAB91")) }
                    Button("Yellow") { intentHandler(.setNoteColor("#FFF59D")) }
                }
            }
        } label: {
            Label("Info", systemImage: "info.circle")
        }
    }
}
