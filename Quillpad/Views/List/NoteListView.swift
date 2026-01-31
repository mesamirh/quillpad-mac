import SwiftUI

struct NoteListView: View {
    @State private var viewModel: NoteListViewModel
    @Binding var selectedNoteId: UUID?

    @State var multiSelection = Set<UUID>()

    init(filter: NoteFilter, store: NotesStore, selectedNoteId: Binding<UUID?>) {
        self._viewModel = State(initialValue: NoteListViewModel(filter: filter, store: store, selectedNoteId: selectedNoteId))
        self._selectedNoteId = selectedNoteId
    }

    var body: some View {
        Group {
            if viewModel.store.layoutMode == .list {
                NoteListListView(
                    groupedNotes: viewModel.groupedNotes,
                    filteredNotes: viewModel.filteredNotes,
                    sortOption: viewModel.store.sortOption,
                    multiSelection: $multiSelection,
                    selectedNoteId: $selectedNoteId,
                    store: viewModel.store
                )
            } else {
                NoteListGridView(
                    groupedNotes: viewModel.groupedNotes,
                    filteredNotes: viewModel.filteredNotes,
                    sortOption: viewModel.store.sortOption,
                    selectedNoteId: $selectedNoteId,
                    store: viewModel.store
                )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.listVersion)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.store.layoutMode)
        .searchable(text: $viewModel.searchText, placement: .toolbar, prompt: "Search notes...")
        .task(id: viewModel.searchText) {
            await viewModel.performDeepSearch()
        }
        .navigationTitle(viewModel.filter.title)
        .toolbar {
            NoteListToolbarContent(
                multiSelection: $multiSelection,
                store: viewModel.store,
                filter: viewModel.filter,
                selectedNoteId: $selectedNoteId,
                deleteSelection: { 
                    viewModel.deleteSelection(ids: multiSelection)
                    multiSelection.removeAll()
                },
                archiveSelection: {
                    viewModel.archiveSelection(ids: multiSelection)
                    multiSelection.removeAll()
                }
            )
        }
        .background(
            Button("") {
                if let id = selectedNoteId {
                    viewModel.deleteSelection(ids: [id])
                } else if !multiSelection.isEmpty {
                    viewModel.deleteSelection(ids: multiSelection)
                    multiSelection.removeAll()
                }
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .opacity(0)
            .allowsHitTesting(false)
        )
    }
}
