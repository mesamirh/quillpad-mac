import Foundation

enum NoteFilter: Hashable {
    case all
    case favorites
    case archived
    case trash
    case hidden
    case reminders
    case notebook(String)
    case tag(String)

    var title: String {
        switch self {
        case .all: return "All Notes"
        case .favorites: return "Favorites"
        case .archived: return "Archive"
        case .trash: return "Trash"
        case .hidden: return "Hidden Notes"
        case .reminders: return "Reminders"
        case .notebook(let name): return name
        case .tag(let name): return "#\(name)"
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case dateUpdatedDesc = "Date Updated (Newest)"
    case dateUpdatedAsc = "Date Updated (Oldest)"
    case dateCreatedDesc = "Date Created (Newest)"
    case dateCreatedAsc = "Date Created (Oldest)"
    case titleAsc = "Title (A-Z)"
    case titleDesc = "Title (Z-A)"

    var id: String { rawValue }
}

enum LayoutMode: String, CaseIterable, Identifiable {
    case list = "List"
    case grid = "Grid"
    var id: String { rawValue }
}

enum DateCategory: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "Previous 7 Days"
    case thisMonth = "Previous 30 Days"
    case older = "Older"
}
