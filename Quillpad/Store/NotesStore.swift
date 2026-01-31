import Foundation
import SwiftUI
import Combine
import CryptoKit
import CoreSpotlight
import UniformTypeIdentifiers
import Observation
import OSLog

@Observable
@MainActor
class NotesStore: NSObject, NSFilePresenter {
    var notes: [Note] = []
    var notebooks: [Notebook] = []
    var tags: [Tag] = []
    var isLoading = false
    var counts: [NoteFilter: Int] = [:]

    var sortOption: SortOption = .dateUpdatedDesc {
        didSet { UserDefaults.standard.set(sortOption.rawValue, forKey: "sortOption") }
    }
    var layoutMode: LayoutMode = .list {
        didSet { UserDefaults.standard.set(layoutMode.rawValue, forKey: "layoutMode") }
    }

    private let logger = Logger(subsystem: "com.quillpad.macos", category: "NotesStore")
    nonisolated let rootURL: URL
    nonisolated private let securityScopedURL: URL?

    nonisolated var presentedItemURL: URL? { rootURL }
    nonisolated let presentedItemOperationQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.quillpad.macos.filepresenter"
        q.maxConcurrentOperationCount = 1
        return q
    }()

    override init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var initialURL = docs.appendingPathComponent("Quillpad")
        var initialSecurityScopedURL: URL?

        if let bookmark = UserDefaults.standard.data(forKey: "syncFolderBookmark") {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                if url.startAccessingSecurityScopedResource() {
                    initialURL = url
                    initialSecurityScopedURL = url

                    if isStale {
                        let newBookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                        UserDefaults.standard.set(newBookmark, forKey: "syncFolderBookmark")
                    }
                }
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }

        self.rootURL = initialURL
        self.securityScopedURL = initialSecurityScopedURL

        super.init()

        if let sortStr = UserDefaults.standard.string(forKey: "sortOption"), let sort = SortOption(rawValue: sortStr) {
            self.sortOption = sort
        }
        if let layoutStr = UserDefaults.standard.string(forKey: "layoutMode"), let layout = LayoutMode(rawValue: layoutStr) {
            self.layoutMode = layout
        }

        createDirectory(at: self.rootURL)
        loadMetadata()

        NSFileCoordinator.addFilePresenter(self)
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
        securityScopedURL?.stopAccessingSecurityScopedResource()
    }

    nonisolated func presentedSubitemDidChange(at url: URL) {
        Task { @MainActor [weak self] in

            try? await Task.sleep(for: .seconds(0.5))
            self?.loadMetadata()
        }
    }

    nonisolated func accommodatePresentedItemDeletion(completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }

    private func withSecurityScope<T>(_ block: () throws -> T) rethrows -> T {
        guard let url = securityScopedURL else { return try block() }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        return try block()
    }

    func loadMetadata() {
        isLoading = true
        let rURL = self.rootURL
        let sURL = self.securityScopedURL

        Task.detached(priority: .userInitiated) {
            let loadedNotes = NotesStore.scan(rootURL: rURL, securityScopedURL: sURL)
            await MainActor.run {
                var newNotes = loadedNotes
                let existingMap = Dictionary(uniqueKeysWithValues: self.notes.map { ($0.id, $0) })

                for i in 0..<newNotes.count {
                    if let existing = existingMap[newNotes[i].id], existing.isLoaded {
                        newNotes[i].content = existing.content
                        newNotes[i].isLoaded = true
                    }
                }

                self.notes = newNotes
                self.refreshMetadata()
                self.indexNotes(newNotes)
                self.isLoading = false
            }
        }
    }

    func loadContent(for noteId: UUID) async {
        guard let index = notes.firstIndex(where: { $0.id == noteId }), !notes[index].isLoaded, let url = notes[index].fileURL else { return }

        do {
            let fullContent = try withSecurityScope {
                var error: NSError?
                var content: String?
                NSFileCoordinator(filePresenter: nil).coordinate(readingItemAt: url, options: .withoutChanges, error: &error) { readURL in
                    content = try? String(contentsOf: readURL, encoding: .utf8)
                }
                if let error = error { throw error }
                return content
            }

            if let body = fullContent {
                let (_, b) = Self.parseFrontmatter(body)
                notes[index].content = b
                notes[index].isLoaded = true
            }
        } catch {
            logger.error("Failed to load content for \(noteId): \(error.localizedDescription)")
        }
    }

    private func refreshMetadata() {
        var newNotebookCounts: [String: Int] = [:]
        var newTagCounts: [String: Int] = [:]
        var allCount = 0
        var favCount = 0
        var archCount = 0
        var trashCount = 0
        var hiddenCount = 0
        var reminderCount = 0

        for note in notes {
            if note.isDeleted {
                trashCount += 1
                continue
            }

            if !note.reminders.filter({ $0 > Date() }).isEmpty {
                reminderCount += 1
            }

            if note.isArchived {
                archCount += 1
            } else if note.isHidden {
                hiddenCount += 1
            } else {
                allCount += 1
                if note.isPinned {
                    favCount += 1
                }

                if let nb = note.notebookName {
                    newNotebookCounts[nb, default: 0] += 1
                }

                for tag in note.tags {
                    newTagCounts[tag, default: 0] += 1
                }
            }
        }

        var newCounts: [NoteFilter: Int] = [:]
        newCounts[.all] = allCount
        newCounts[.favorites] = favCount
        newCounts[.archived] = archCount
        newCounts[.trash] = trashCount
        newCounts[.hidden] = hiddenCount
        newCounts[.reminders] = reminderCount

        for (name, count) in newNotebookCounts {
            newCounts[.notebook(name)] = count
        }
        for (name, count) in newTagCounts {
            newCounts[.tag(name)] = count
        }

        self.counts = newCounts
        self.notebooks = newNotebookCounts.keys.sorted().map { Notebook(name: $0) }
        self.tags = newTagCounts.keys.sorted().map { Tag(name: $0) }
    }

    private func createDirectory(at url: URL) {
        do {
            try withSecurityScope {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }
        } catch {
            logger.error("Failed to create directory at \(url): \(error.localizedDescription)")
        }
    }

    nonisolated private static func scan(rootURL: URL, securityScopedURL: URL?) -> [Note] {
        var results: [Note] = []
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .creationDateKey, .contentModificationDateKey]

        func withScope<T>(_ block: () throws -> T) -> T? {
            guard let url = securityScopedURL else { return try? block() }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            return try? block()
        }

        func scanFolder(_ directory: URL, isArchived: Bool = false, isDeleted: Bool = false, isHidden: Bool = false) {
             guard let enumerator = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { return }

            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) else { continue }
                if let isDir = resourceValues.isDirectory, isDir { continue }

                if fileURL.pathExtension == "md" || fileURL.pathExtension == "txt" {
                    if let note = parseNoteMetadata(at: fileURL, resources: resourceValues, rootURL: rootURL, forcedArchived: isArchived, forcedDeleted: isDeleted, forcedHidden: isHidden) {
                        results.append(note)
                    }
                }
            }
        }

        _ = withScope {
            scanFolder(rootURL)

            let archiveURL = rootURL.appendingPathComponent(".archive")
            if FileManager.default.fileExists(atPath: archiveURL.path) {
                scanFolder(archiveURL, isArchived: true)
            }

            let trashURL = rootURL.appendingPathComponent(".trash")
            if FileManager.default.fileExists(atPath: trashURL.path) {
                scanFolder(trashURL, isDeleted: true)
            }

            let hiddenURL = rootURL.appendingPathComponent(".hidden")
            if FileManager.default.fileExists(atPath: hiddenURL.path) {
                scanFolder(hiddenURL, isHidden: true)
            }
        }

        return results
    }

    nonisolated private static func parseNoteMetadata(at url: URL, resources: URLResourceValues, rootURL: URL, forcedArchived: Bool = false, forcedDeleted: Bool = false, forcedHidden: Bool = false) -> Note? {
        var notebook: String? = nil
        let parentDir = url.deletingLastPathComponent()
        let parentName = parentDir.lastPathComponent

        if parentDir != rootURL {
            if [".archive", ".trash", ".hidden"].contains(parentName) {
                notebook = nil
            } else {
                notebook = parentName
            }
        }

        guard let fileHandle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? fileHandle.close() }
        let data = (try? fileHandle.read(upToCount: 2048)) ?? Data()
        guard let headerStr = String(data: data, encoding: .utf8) else { return nil }

        let (frontmatter, bodyPreview) = parseFrontmatter(headerStr)

        var stableID: UUID
        if let uidStr = frontmatter["uid"] as? String, let uuid = UUID(uuidString: uidStr) {
            stableID = uuid
        } else if let idStr = frontmatter["id"] as? String, let uuid = UUID(uuidString: idStr) {
             stableID = uuid
        } else {
             let relativePath = url.path.replacingOccurrences(of: rootURL.path, with: "")
             stableID = UUID.from(string: relativePath)
        }

        let titleFromFilename = url.deletingPathExtension().lastPathComponent

        let tags = frontmatter["tags"] as? [String] ?? []
        let attachments = frontmatter["attachments"] as? [String] ?? []
        let remindersStrings = frontmatter["reminders"] as? [String] ?? []
        let reminders = remindersStrings.compactMap { ISO8601DateFormatter().date(from: $0) }

        let isPinned = frontmatter["pinned"] as? Bool ?? false
        let isArchived = forcedArchived || (frontmatter["archived"] as? Bool ?? false)
        let isDeleted = forcedDeleted || (frontmatter["deleted"] as? Bool ?? (frontmatter["trash"] as? Bool ?? false))
        let isHidden = forcedHidden || (frontmatter["hidden"] as? Bool ?? false)

        let color = frontmatter["color"] as? String

        let preview = String(bodyPreview.prefix(150)).trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")

        return Note(
            id: stableID,
            title: titleFromFilename,
            content: nil,
            preview: preview,
            createdAt: resources.creationDate ?? Date(),
            updatedAt: resources.contentModificationDate ?? Date(),
            isArchived: isArchived,
            isDeleted: isDeleted,
            isPinned: isPinned,
            color: color,
            notebookName: notebook,
            tags: tags,
            attachments: attachments,
            reminders: reminders,
            fileURL: url,
            isLoaded: false,
            isHidden: isHidden
        )
    }

    nonisolated private static func parseFrontmatter(_ text: String) -> (dict: [String: Any], content: String) {
        let pattern = "^---\n(.*?)\n---\n"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return ([:], text) }

        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))

        if let match = results.first {
            let frontmatterRange = match.range(at: 1)
            let yamlString = nsString.substring(with: frontmatterRange)

            var dict: [String: Any] = [:]
            yamlString.enumerateLines { line, _ in
                let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 {
                    let key = String(parts[0])
                    let value = String(parts[1])

                    if key == "tags" || key == "attachments" || key == "reminders" {
                        let clean = value.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
                        let items = clean.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        dict[key] = items.map { String($0) }
                    } else if ["pinned", "archived", "deleted", "trash", "hidden"].contains(key) {
                        dict[key] = (value == "true")
                    } else {
                        var cleanValue = value
                        if cleanValue.hasPrefix("\"") && cleanValue.hasSuffix("\"") {
                            cleanValue = String(cleanValue.dropFirst().dropLast())
                        }
                        dict[key] = cleanValue
                    }
                }
            }
            let content = nsString.substring(from: match.range.location + match.range.length)
            return (dict, content)
        }
        return ([:], text)
    }

    private func serializeNote(_ note: Note) -> String {
        var output = "---" + "\n"
        output += "uid: \(note.id.uuidString)\n"
        if !note.tags.isEmpty {
            output += "tags: [\(note.tags.joined(separator: ", "))]\n"
        }
        if !note.attachments.isEmpty {
            output += "attachments: [\(note.attachments.joined(separator: ", "))]\n"
        }
        if !note.reminders.isEmpty {
            let formatter = ISO8601DateFormatter()
            let dates = note.reminders.map { formatter.string(from: $0) }
            output += "reminders: [\(dates.joined(separator: ", "))]\n"
        }
        if note.isPinned { output += "pinned: true\n" }
        if note.isArchived { output += "archived: true\n" }
        if note.isDeleted { output += "deleted: true\n" }
        if note.isHidden { output += "hidden: true\n" }

        if let color = note.color {
            output += "color: \(color)\n"
        }
        output += "---" + "\n"
        output += note.content ?? ""
        return output
    }

    @discardableResult
    func addNote(notebookName: String? = nil) -> UUID {
        var folderURL = rootURL
        if let nb = notebookName {
            folderURL = folderURL.appendingPathComponent(nb)
            createDirectory(at: folderURL)
        }

        let id = UUID()
        let newNote = Note(
            id: id,
            title: "Untitled Note",
            content: "",
            preview: "No additional text",
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false,
            isDeleted: false,
            isPinned: false,
            color: nil,
            notebookName: notebookName,
            tags: [],
            attachments: [],
            reminders: [],
            fileURL: nil,
            isLoaded: true,
            isHidden: false
        )

        saveNote(newNote, isNew: true)
        return id
    }

    func saveNote(_ note: Note, isNew: Bool = false) {
        var filename = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if filename.isEmpty { filename = "Untitled" }
        filename = filename.replacingOccurrences(of: "/", with: "-")
        filename += ".md"

        var folderURL = rootURL

        if note.isDeleted {
            folderURL = rootURL.appendingPathComponent(".trash")
        } else if note.isArchived {
            folderURL = rootURL.appendingPathComponent(".archive")
        } else if note.isHidden {
            folderURL = rootURL.appendingPathComponent(".hidden")
        } else if let nb = note.notebookName {
             folderURL = rootURL.appendingPathComponent(nb)
        }

        createDirectory(at: folderURL)

        let destinationURL = folderURL.appendingPathComponent(filename)
        let content = serializeNote(note)

        do {
            try withSecurityScope {
                let coordinator = NSFileCoordinator(filePresenter: self)
                var error: NSError?

                if let oldURL = note.fileURL, oldURL != destinationURL, FileManager.default.fileExists(atPath: oldURL.path) {
                    coordinator.coordinate(writingItemAt: oldURL, options: .forMoving, writingItemAt: destinationURL, options: .forReplacing, error: &error) { url1, url2 in
                        do {
                            try FileManager.default.moveItem(at: url1, to: url2)
                            try content.write(to: url2, atomically: true, encoding: .utf8)
                        } catch {
                            self.logger.error("Save/Move failed: \(error.localizedDescription)")
                        }
                    }
                } else {
                    coordinator.coordinate(writingItemAt: destinationURL, options: .forReplacing, error: &error) { url in
                        do {
                            try content.write(to: url, atomically: true, encoding: .utf8)
                        } catch {
                            self.logger.error("Save failed: \(error.localizedDescription)")
                        }
                    }
                }
                if let error = error { throw error }
            }

            if let index = self.notes.firstIndex(where: { $0.id == note.id }) {
                self.notes[index] = note
                self.notes[index].fileURL = destinationURL
                self.notes[index].updatedAt = Date()
                self.notes[index].preview = String(note.content?.prefix(100) ?? "").replacingOccurrences(of: "\n", with: " ")
                self.indexNote(self.notes[index])
            } else {
                var n = note
                n.fileURL = destinationURL
                self.notes.insert(n, at: 0)
                self.indexNote(n)
            }
            self.refreshMetadata()
        } catch {
            logger.error("Failed to coordinate save: \(error.localizedDescription)")
        }
    }

    func deleteNote(_ note: Note) {
        guard let url = note.fileURL else { return }

        do {
            try withSecurityScope {
                let coordinator = NSFileCoordinator(filePresenter: self)
                var error: NSError?
                coordinator.coordinate(writingItemAt: url, options: .forDeleting, error: &error) { writeURL in
                     try? FileManager.default.removeItem(at: writeURL)
                }

                let parentDir = url.deletingLastPathComponent()
                for att in note.attachments {
                    let attURL = parentDir.appendingPathComponent(att)
                    coordinator.coordinate(writingItemAt: attURL, options: .forDeleting, error: &error) { wURL in
                        try? FileManager.default.removeItem(at: wURL)
                    }
                }
                if let error = error { throw error }
            }

            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes.remove(at: index)
            }
            deindexNote(note)
            refreshMetadata()
        } catch {
            logger.error("Failed to delete note: \(error.localizedDescription)")
        }
    }

    func deepSearch(query: String) async -> [UUID] {
        guard !query.isEmpty else { return [] }
        let lowerQuery = query.localizedLowercase

        let sURL = self.securityScopedURL

        return await Task.detached(priority: .userInitiated) { [notes = self.notes, securityScopedURL = sURL] in
            var matchedIDs: [UUID] = []

            func check(_ text: String) -> Bool {
                return text.localizedCaseInsensitiveContains(lowerQuery)
            }

            for note in notes {
                if check(note.title) || check(note.preview) {
                    matchedIDs.append(note.id)
                    continue
                }

                if let content = note.content {
                    if check(content) {
                        matchedIDs.append(note.id)
                    }
                } else if let url = note.fileURL {
                    var fileContent: String?

                    if let sURL = securityScopedURL {
                        _ = sURL.startAccessingSecurityScopedResource()
                        fileContent = try? String(contentsOf: url, encoding: .utf8)
                        sURL.stopAccessingSecurityScopedResource()
                    } else {
                        fileContent = try? String(contentsOf: url, encoding: .utf8)
                    }

                    if let fc = fileContent, check(fc) {
                        matchedIDs.append(note.id)
                    }
                }
            }
            return matchedIDs
        }.value
    }

    func addNotebook(name: String) {
        let url = rootURL.appendingPathComponent(name)
        createDirectory(at: url)
        loadMetadata()
    }

    func deleteNotebook(name: String) {
         let url = rootURL.appendingPathComponent(name)
         do {
             try withSecurityScope {
                 let coordinator = NSFileCoordinator(filePresenter: nil)
                 var error: NSError?
                 coordinator.coordinate(writingItemAt: url, options: .forDeleting, error: &error) { wURL in
                     try? FileManager.default.removeItem(at: wURL)
                 }
                 if let error = error { throw error }
             }
             loadMetadata()
         } catch {
             logger.error("Failed to delete notebook: \(error.localizedDescription)")
         }
    }

    func duplicateNote(_ note: Note) {
        let dup = Note(
            id: UUID(),
            title: "\(note.title) Copy",
            content: note.content,
            preview: note.preview,
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: note.isArchived,
            isDeleted: note.isDeleted,
            isPinned: false,
            color: note.color,
            notebookName: note.notebookName,
            tags: note.tags,
            attachments: note.attachments,
            reminders: [],
            fileURL: nil,
            isLoaded: note.isLoaded,
            isHidden: note.isHidden
        )

        if dup.content == nil {
            Task {
                await loadContent(for: note.id)
                if let loaded = notes.first(where: { $0.id == note.id }) {
                     var fullDup = dup
                     fullDup.content = loaded.content
                     saveNote(fullDup, isNew: true)
                }
            }
        } else {
            saveNote(dup, isNew: true)
        }
    }

    func indexNotes(_ notes: [Note]) {
        Task.detached(priority: .background) {
            let items = notes.map { note -> CSSearchableItem in
                let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
                attributeSet.title = note.title
                attributeSet.contentDescription = note.preview
                attributeSet.contentModificationDate = note.updatedAt
                attributeSet.keywords = note.tags
                if let nb = note.notebookName {
                    attributeSet.keywords?.append(nb)
                }

                return CSSearchableItem(uniqueIdentifier: note.id.uuidString, domainIdentifier: "org.qosp.notes", attributeSet: attributeSet)
            }

            CSSearchableIndex.default().indexSearchableItems(items) { error in
                if let error = error {
                    print("Spotlight indexing error: \(error.localizedDescription)")
                }
            }
        }
    }

    func indexNote(_ note: Note) {
        indexNotes([note])
    }

    func deindexNote(_ note: Note) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [note.id.uuidString]) { error in
            if let error = error {
                 self.logger.error("Spotlight deletion error: \(error.localizedDescription)")
            }
        }
    }
}

extension UUID {
    nonisolated static func from(string: String) -> UUID {
        let hash = Insecure.MD5.hash(data: string.data(using: .utf8)!)
        return UUID(uuid: hash.withUnsafeBytes { $0.load(as: uuid_t.self) })
    }
}
