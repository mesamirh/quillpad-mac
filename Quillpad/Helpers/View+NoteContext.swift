import SwiftUI

extension View {
    func noteContextMenu(note: Note, store: NotesStore, selectedNoteId: Binding<UUID?>) -> some View {
        self.contextMenu {
            Button("Open") {
                selectedNoteId.wrappedValue = note.id
            }

            Divider()

            Button("Duplicate") {
                store.duplicateNote(note)
            }

            Button(note.isArchived ? "Unarchive" : "Archive") {
                if selectedNoteId.wrappedValue == note.id && !note.isArchived {
                    selectedNoteId.wrappedValue = nil
                }
                var n = note
                n.isArchived.toggle()
                store.saveNote(n)
            }

            Button(note.isPinned ? "Unfavorite" : "Favorite") {
                var n = note
                n.isPinned.toggle()
                store.saveNote(n)
            }

            Divider()

            Button("Move to Trash", role: .destructive) {
                if selectedNoteId.wrappedValue == note.id {
                    selectedNoteId.wrappedValue = nil
                }
                var n = note
                n.isDeleted = true
                store.saveNote(n)
            }

            Button("Delete Permanently", role: .destructive) {
                if selectedNoteId.wrappedValue == note.id {
                    selectedNoteId.wrappedValue = nil
                }
                store.deleteNote(note)
            }
        }
    }

    func emptyAreaContextMenu(onNewNote: @escaping () -> Void) -> some View {
        self.contextMenu {
            Button("New Note") {
                onNewNote()
            }
        }
    }
}
