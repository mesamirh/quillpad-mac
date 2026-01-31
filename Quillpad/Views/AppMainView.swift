import SwiftUI

struct AppMainView: View {
    @Bindable var store: NotesStore
    @Binding var selectedFilter: NoteFilter?
    @Binding var selectedNoteId: UUID?

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store, selectedFilter: $selectedFilter)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } content: {
            if let filter = selectedFilter {
                NoteListView(filter: filter, store: store, selectedNoteId: $selectedNoteId)
                    .navigationSplitViewColumnWidth(min: 300, ideal: 350)
            } else {
                Text("Select a category")
                    .foregroundStyle(.secondary)
            }
        } detail: {
            if let noteId = selectedNoteId,
               let index = store.notes.firstIndex(where: { $0.id == noteId }) {
                NoteEditorView(note: $store.notes[index], store: store)
                    .id(noteId)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity))
            } else {
                ContentUnavailableView("No Note Selected", systemImage: "doc.text", description: Text("Select a note from the list to view or edit its content."))
            }
        }
    }
}
