import SwiftUI

struct NoteRowView: View {
    let note: Note

    var displayName: String {
        if note.title.isEmpty || note.title == "Untitled" {
            return note.preview.isEmpty ? "Untitled Note" : note.preview
        }
        return note.title
    }

    var body: some View {
        HStack(spacing: 12) {
            if let colorString = note.color {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: colorString))
                    .frame(width: 4)
                    .padding(.vertical, 8)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(note.isPinned ? Color.orange : Color.primary)
                        .lineLimit(1)

                    Spacer()

                    Text(note.updatedAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }

                Text(note.preview.isEmpty ? "No additional text" : note.preview)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if !note.tags.isEmpty || note.isPinned {
                    HStack(spacing: 6) {
                        if note.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                        }

                        ForEach(note.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.quaternary)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
    }
}
