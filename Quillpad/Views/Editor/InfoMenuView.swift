import SwiftUI

struct InfoMenuView: View {
    @Binding var note: Note
    var store: NotesStore
    @Binding var localNotebookName: String?
    @Binding var showReminderPicker: Bool
    @Binding var showAddTag: Bool

    var body: some View {
        Menu {
            toggleActions
            Divider()
            notebookActions
            Divider()
            tagsAndColorActions
        } label: {
            Label("Info", systemImage: "info.circle")
        }
    }

    private var toggleActions: some View {
        Group {
            Button(action: { updateNote { $0.isPinned.toggle() } }) {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: "pin")
            }

            Button(action: { updateNote { $0.isHidden.toggle() } }) {
                Label(note.isHidden ? "Unhide" : "Hide", systemImage: "eye.slash")
            }

            Button(action: { updateNote { $0.isArchived.toggle() } }) {
                Label(note.isArchived ? "Unarchive" : "Archive", systemImage: "archivebox")
            }

            Button(action: { updateNote { $0.isDeleted.toggle() } }) {
                Label(note.isDeleted ? "Restore" : "Delete", systemImage: "trash")
            }
        }
    }

    private var notebookActions: some View {
        Group {
            Button("Set Reminder...") {
                showReminderPicker = true
            }

            Divider()

            Picker("Notebook", selection: $localNotebookName) {
                Text("None").tag(Optional<String>.none)
                ForEach(store.notebooks) { nb in
                    Text(nb.name).tag(Optional<String>.some(nb.name))
                }
            }
        }
    }

    private var tagsAndColorActions: some View {
        Group {
            Menu("Tags") {
                ForEach(store.tags) { tag in
                    Button {
                        toggleTag(tag.name)
                    } label: {
                        if note.tags.contains(tag.name) {
                            Label(tag.name, systemImage: "checkmark")
                        } else {
                            Text(tag.name)
                        }
                    }
                }
                Divider()
                Button("Add New Tag...") {
                    showAddTag = true
                }
            }

            Divider()

            Menu("Color") {
                Button("None") { setNoteColor(nil) }
                Button("Green") { setNoteColor("#C5E1A5") }
                Button("Pink") { setNoteColor("#F48FB1") }
                Button("Blue") { setNoteColor("#81D4FA") }
                Button("Red") { setNoteColor("#EF9A9A") }
                Button("Orange") { setNoteColor("#FFAB91") }
                Button("Yellow") { setNoteColor("#FFF59D") }
            }
        }
    }

    private func updateNote(_ transform: (inout Note) -> Void) {
        var n = note
        transform(&n)
        store.saveNote(n)
    }

    private func toggleTag(_ name: String) {
        if note.tags.contains(name) {
            note.tags.removeAll { $0 == name }
        } else {
            note.tags.append(name)
        }
        store.saveNote(note)
    }

    private func setNoteColor(_ color: String?) {
        note.color = color
        store.saveNote(note)
    }
}
