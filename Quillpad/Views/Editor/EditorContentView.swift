import SwiftUI

struct EditorContentView: View {
    @Binding var content: String
    @Binding var isPreviewMode: Bool
    let fontSize: Double
    let note: Note 

    var body: some View {
        Group {
            if isPreviewMode {
                ScrollView {
                    Text(.init(content))
                        .font(.system(size: fontSize))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            } else {
                MarkdownTextView(text: $content, fontSize: fontSize)
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity)
            }
        }
    }
}
