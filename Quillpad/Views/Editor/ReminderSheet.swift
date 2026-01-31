import SwiftUI

struct ReminderSheet: View {
    @Binding var date: Date
    var onSet: (Date) -> Void

    var body: some View {
        VStack {
            DatePicker("Reminder", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .padding()
            Button("Set Reminder") {
                onSet(date)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
