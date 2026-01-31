import SwiftUI

struct NoteGridItemView: View {
    let note: Note
    @State private var isHovered = false

    var displayName: String {
        if note.title.isEmpty || note.title == "Untitled" {
            return note.preview.isEmpty ? "Untitled Note" : note.preview
        }
        return note.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .top) {
                if let colorString = note.color {
                    Rectangle()
                        .fill(Color(hex: colorString))
                        .frame(height: 6)
                } else {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(height: 6)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(note.isPinned ? Color.orange : Color.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                    }
                }

                Text(note.preview.isEmpty ? "No additional text" : note.preview)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 12)

                HStack {
                    Text(note.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)

                    Spacer()

                    if !note.tags.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 8))
                            Text("\(note.tags.count)")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .cornerRadius(6)
                    }
                }
            }
            .padding(12)
        }
        .frame(height: 160)
        .background(.ultraThinMaterial)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isHovered ? 0.2 : 0.05), radius: isHovered ? 10 : 3, x: 0, y: isHovered ? 5 : 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}
