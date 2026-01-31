import SwiftUI

struct NoteHeaderView: View {
    @Binding var note: Note
    let onSave: () -> Void

    var body: some View {
        TextField("Title", text: $note.title)
            .font(.system(size: 28, weight: .bold))
            .textFieldStyle(.plain)
            .padding()
            .onSubmit {
                onSave()
            }
    }
}
