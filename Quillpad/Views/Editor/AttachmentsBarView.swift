import SwiftUI

struct AttachmentsBarView: View {
    @Binding var note: Note
    var store: NotesStore
    let playAudio: (String) -> Void

    var body: some View {
        Group {
            if !note.attachments.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(note.attachments), id: \.self) { attachment in
                                attachmentItem(attachment)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(height: 50)
                }
            }
        }
    }

    @ViewBuilder
    private func attachmentItem(_ att: String) -> some View {
        HStack {
            Image(systemName: att.hasSuffix(".m4a") ? "waveform" : "paperclip")
                .foregroundColor(.accentColor)

            Text(att)
                .lineLimit(1)
                .font(.caption)

            if att.hasSuffix(".m4a") {
                Button(action: { playAudio(att) }) {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
        .contextMenu {
            Button("Remove", role: .destructive) {
                removeAttachment(att)
            }
        }
    }

    private func removeAttachment(_ name: String) {
        note.attachments.removeAll { $0 == name }
        store.saveNote(note)
    }
}
