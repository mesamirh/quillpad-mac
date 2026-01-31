import SwiftUI

struct SidebarView: View {
    var store: NotesStore
    @Binding var selectedFilter: NoteFilter?
    @State private var showNewNotebook = false
    @State private var newNotebookName = ""

    var body: some View {
        List(selection: $selectedFilter) {
            Section("Library") {
                NavigationLink(value: NoteFilter.all) {
                    Label("All Notes", systemImage: "doc.text")
                        .badge(store.counts[.all] ?? 0)
                }
                NavigationLink(value: NoteFilter.favorites) {
                    Label("Favorites", systemImage: "star.fill")
                        .badge(store.counts[.favorites] ?? 0)
                }
                NavigationLink(value: NoteFilter.reminders) {
                    Label("Reminders", systemImage: "bell.fill")
                        .badge(store.counts[.reminders] ?? 0)
                }
                NavigationLink(value: NoteFilter.archived) {
                    Label("Archive", systemImage: "archivebox")
                        .badge(store.counts[.archived] ?? 0)
                }
                NavigationLink(value: NoteFilter.trash) {
                    Label("Trash", systemImage: "trash")
                        .badge(store.counts[.trash] ?? 0)
                }
                NavigationLink(value: NoteFilter.hidden) {
                    Label("Hidden", systemImage: "eye.slash")
                        .badge(store.counts[.hidden] ?? 0)
                }
            }

            Section("Notebooks") {
                ForEach(store.notebooks) { notebook in
                    NavigationLink(value: NoteFilter.notebook(notebook.name)) {
                        Label(notebook.name, systemImage: "folder")
                            .badge(store.counts[.notebook(notebook.name)] ?? 0)
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            store.deleteNotebook(name: notebook.name)
                        }
                    }
                }
            }

            if !store.tags.isEmpty {
                Section("Tags") {
                    ForEach(store.tags) { tag in
                        NavigationLink(value: NoteFilter.tag(tag.name)) {
                            Label(tag.name, systemImage: "tag")
                                .badge(store.counts[.tag(tag.name)] ?? 0)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showNewNotebook = true }) {
                    Label("Add Notebook", systemImage: "folder.badge.plus")
                }
                .help("Create New Notebook")
            }
        }
        .alert("New Notebook", isPresented: $showNewNotebook) {
            TextField("Name", text: $newNotebookName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                if !newNotebookName.isEmpty {
                    store.addNotebook(name: newNotebookName)
                    newNotebookName = ""
                }
            }
        }
    }
}
