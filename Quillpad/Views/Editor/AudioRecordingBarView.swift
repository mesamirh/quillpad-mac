import SwiftUI

struct AudioRecordingBarView: View {
    @Bindable var audioRecorder: AudioRecorder
    var stopRecording: () -> Void

    var body: some View {
        if audioRecorder.isRecording {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(.red)
                Text("Recording... \(audioRecorder.timerString)")
                Spacer()
                Button("Stop") {
                    stopRecording()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .transition(.move(edge: .bottom))
        }
    }
}
