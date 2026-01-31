import SwiftUI

struct SketchSheet: View {
    @Binding var isPresented: Bool
    var canvasView: SimpleCanvasView
    var onSave: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Spacer()
                Button("Save Sketch") {
                    onSave()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            Divider()
            CanvasView(canvasView: canvasView)
                .frame(minWidth: 500, minHeight: 400)
        }
        .padding()
    }
}
