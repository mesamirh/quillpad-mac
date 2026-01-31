import SwiftUI

struct NoteFooterView: View {
    let content: String
    let updatedDate: Date

    private var words: Int {
        content.split { $0.isWhitespace || $0.isNewline }.count
    }

    private var chars: Int {
        content.count
    }

    private var readTime: Int {
        max(1, words / 200)
    }

    var body: some View {
        HStack {
            Text("\(words) words • \(chars) chars • \(readTime) min read")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("Last updated \(updatedDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
