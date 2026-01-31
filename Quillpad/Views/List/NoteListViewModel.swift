import SwiftUI
import Observation
import Combine

@Observable
@MainActor
class NoteListViewModel {
    var filter: NoteFilter
    var store: NotesStore
    var selectedNoteId: Binding<UUID?>
    var listVersion: UUID = UUID()

    var searchText: String = "" {
        didSet { listVersion = UUID() }
    }
    var deepSearchResults: Set<UUID>? = nil {
        didSet { listVersion = UUID() }
    }

    init(filter: NoteFilter, store: NotesStore, selectedNoteId: Binding<UUID?>) {
        self.filter = filter
        self.store = store
        self.selectedNoteId = selectedNoteId
    }

    var filteredNotes: [Note] {
        let notes = store.notes

        let filtered = notes.filter { note in

            switch filter {
            case .trash:
                if !note.isDeleted { return false }
            case .archived:
                if !note.isArchived || note.isDeleted { return false }
            case .hidden:
                if !note.isHidden || note.isDeleted { return false }
            case .reminders:
                let upcoming = note.reminders.filter { $0 > Date() }
                if upcoming.isEmpty || note.isDeleted { return false }
            case .favorites:
                if !note.isPinned || note.isArchived || note.isDeleted || note.isHidden { return false }
            case .all:
                if note.isArchived || note.isDeleted || note.isHidden { return false }
            case .notebook(let name):
                if note.notebookName != name || note.isArchived || note.isDeleted || note.isHidden { return false }
            case .tag(let tagName):
                if !note.tags.contains(tagName) || note.isArchived || note.isDeleted || note.isHidden { return false }
            }

            if let results = deepSearchResults {
                 if !results.contains(note.id) { return false }
            } else if !searchText.isEmpty {
                 if note.title.localizedCaseInsensitiveContains(searchText) ||
                    note.preview.localizedCaseInsensitiveContains(searchText) {
                     return true
                 }
                 return false
            }

            return true
        }

        return filtered.sorted { n1, n2 in
            switch store.sortOption {
            case .dateUpdatedDesc: return n1.updatedAt > n2.updatedAt
            case .dateUpdatedAsc: return n1.updatedAt < n2.updatedAt
            case .dateCreatedDesc: return n1.createdAt > n2.createdAt
            case .dateCreatedAsc: return n1.createdAt < n2.createdAt
            case .titleAsc: return n1.title < n2.title
            case .titleDesc: return n1.title > n2.title
            }
        }
    }

    var groupedNotes: [(DateCategory, [Note])] {
        let notes = filteredNotes
        let grouped = Dictionary(grouping: notes) { category(for: $0.updatedAt) }
        return DateCategory.allCases.compactMap { category in
            if let ns = grouped[category], !ns.isEmpty {
                return (category, ns)
            }
            return nil
        }
    }

    private func category(for date: Date) -> DateCategory {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return .today }
        if calendar.isDateInYesterday(date) { return .yesterday }

        let now = Date()
        let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if days <= 7 { return .thisWeek }
        if days <= 30 { return .thisMonth }
        return .older
    }

    func performDeepSearch() async {
        if searchText.isEmpty {
            deepSearchResults = nil
        } else {

            try? await Task.sleep(nanoseconds: 300_000_000)
            if !Task.isCancelled {
                let ids = await store.deepSearch(query: searchText)
                deepSearchResults = Set(ids)
            }
        }
    }

    func deleteSelection(ids: Set<UUID>) {
        if let current = selectedNoteId.wrappedValue, ids.contains(current) {
            selectedNoteId.wrappedValue = nil
        }
        let selected = store.notes.filter { ids.contains($0.id) }
        for note in selected {
            store.deleteNote(note)
        }
    }

    func archiveSelection(ids: Set<UUID>) {
        if let current = selectedNoteId.wrappedValue, ids.contains(current) {
            selectedNoteId.wrappedValue = nil
        }
        let selected = store.notes.filter { ids.contains($0.id) }
        for var note in selected {
            note.isArchived = true
            store.saveNote(note)
        }
    }
}
