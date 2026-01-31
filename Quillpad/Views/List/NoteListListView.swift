import SwiftUI

struct NoteListListView: View {
    let groupedNotes: [(DateCategory, [Note])]
    let filteredNotes: [Note]
    let sortOption: SortOption
    @Binding var multiSelection: Set<UUID>
    @Binding var selectedNoteId: UUID?
    var store: NotesStore

    var body: some View {
        List(selection: $multiSelection) {
            if sortOption == .dateUpdatedDesc {
                ForEach(groupedNotes, id: \.0) { group in
                    Section(header: Text(group.0.rawValue).font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)) {
                        ForEach(group.1, id: \.id) { note in
                            noteRow(note)
                        }
                    }
                }
            } else {
                ForEach(filteredNotes, id: \.id) { note in
                    noteRow(note)
                }
            }
        }
        .listStyle(.inset)
        .background(
            Color.clear
                .contentShape(Rectangle())
                .emptyAreaContextMenu {
                    let id = store.addNote()
                    selectedNoteId = id
                }
        )
    }

    private func noteRow(_ note: Note) -> some View {
        NavigationLink(value: note.id) {
            NoteRowView(note: note)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { 
                if selectedNoteId == note.id { selectedNoteId = nil }
                store.deleteNote(note) 
            }
            label: { Label("Delete", systemImage: "trash") }

            Button {
                if selectedNoteId == note.id { selectedNoteId = nil }
                var n = note
                n.isArchived.toggle()
                store.saveNote(n)
            } label: {
                Label(note.isArchived ? "Unarchive" : "Archive", systemImage: note.isArchived ? "archivebox.fill" : "archivebox")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                var n = note
                n.isPinned.toggle()
                store.saveNote(n)
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash.fill" : "pin.fill")
            }
            .tint(.orange)
        }
        .noteContextMenu(note: note, store: store, selectedNoteId: $selectedNoteId)
    }
}
