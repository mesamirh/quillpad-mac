import Foundation

struct Note: Identifiable, Hashable {
    let id: UUID
    var title: String
    var content: String? 
    var preview: String 
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    var isDeleted: Bool
    var isPinned: Bool
    var color: String?
    var notebookName: String?
    var tags: [String]
    var attachments: [String]
    var reminders: [Date]
    var fileURL: URL?
    var isLoaded: Bool = false
    var isHidden: Bool = false
}
