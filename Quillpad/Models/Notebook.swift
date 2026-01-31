import Foundation

struct Notebook: Identifiable, Hashable {
    var id: String { name }
    var name: String
}
