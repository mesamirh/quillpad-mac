import SwiftUI

struct NoteListGridView: View {
    let groupedNotes: [(DateCategory, [Note])]
    let filteredNotes: [Note]
    let sortOption: SortOption
    @Binding var selectedNoteId: UUID?
    let store: NotesStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if sortOption == .dateUpdatedDesc {
                    ForEach(groupedNotes, id: \.0) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.0.rawValue)
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                                ForEach(group.1, id: \.id) { note in
                                    gridItem(note)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                        ForEach(filteredNotes, id: \.id) { note in
                            gridItem(note)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .background(
            Color.clear
                .contentShape(Rectangle())
                .emptyAreaContextMenu {
                    let id = store.addNote()
                    selectedNoteId = id
                }
        )
    }

    private func gridItem(_ note: Note) -> some View {
        NavigationLink(value: note.id) {
            NoteGridItemView(note: note)
        }
        .buttonStyle(.plain)
        .noteContextMenu(note: note, store: store, selectedNoteId: $selectedNoteId)
    }
}
