import Foundation

struct Tag: Identifiable, Hashable {
    var id: String { name }
    var name: String
}
