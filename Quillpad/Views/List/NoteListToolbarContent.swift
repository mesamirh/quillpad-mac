import SwiftUI

struct NoteListToolbarContent: ToolbarContent {
    @Binding var multiSelection: Set<UUID>
    var store: NotesStore
    var filter: NoteFilter
    @Binding var selectedNoteId: UUID?
    let deleteSelection: () -> Void
    let archiveSelection: () -> Void

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            HStack {
                if !multiSelection.isEmpty {
                     Button(role: .destructive, action: deleteSelection) {
                         Label("Delete", systemImage: "trash")
                     }
                     .keyboardShortcut(.delete, modifiers: .command)

                     Button(action: archiveSelection) {
                         Label("Archive", systemImage: "archivebox")
                     }
                }

                Menu {
                    Picker("Sort By", selection: Bindable(store).sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }

                Picker("View", selection: Bindable(store).layoutMode) {
                    Label("List", systemImage: "list.bullet").tag(LayoutMode.list)
                    Label("Grid", systemImage: "square.grid.2x2").tag(LayoutMode.grid)
                }
                .pickerStyle(.segmented)

                Button(action: {
                    var nb: String? = nil
                    if case .notebook(let name) = filter { nb = name }
                    let id = store.addNote(notebookName: nb)
                    selectedNoteId = id
                }) {
                    Label("New Note", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
