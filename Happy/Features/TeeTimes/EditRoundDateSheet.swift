import SwiftUI

struct EditRoundDateSheet: View {
    let teeTime: TeeTime
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var date: Date
    @State private var teeTimeHour: Int
    @State private var teeTimeMinute: Int
    @State private var teeTimeAMPM: Int

    init(teeTime: TeeTime) {
        self.teeTime = teeTime
        _date = State(initialValue: teeTime.date)
        // Parse existing tee time string e.g. "7:30 AM"
        let parts = teeTime.teeTimeString.components(separatedBy: " ")
        let timeParts = (parts.first ?? "7:00").components(separatedBy: ":")
        _teeTimeHour = State(initialValue: Int(timeParts.first ?? "7") ?? 7)
        _teeTimeMinute = State(initialValue: Int(timeParts.last ?? "0") ?? 0)
        _teeTimeAMPM = State(initialValue: parts.last == "PM" ? 1 : 0)
    }

    private var teeTimeString: String {
        let ampm = teeTimeAMPM == 0 ? "AM" : "PM"
        return String(format: "%d:%02d %@", teeTimeHour, teeTimeMinute, ampm)
    }

    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.happySand)
                    .frame(width: 36, height: 4)
                    .padding(.top, HappySpacing.md)
                    .padding(.bottom, HappySpacing.xxl)

                VStack(alignment: .leading, spacing: 0) {
                    HappySectionLabel(text: "Edit Round")
                        .padding(.bottom, HappySpacing.md)
                    Text("Update Date\n& Time.")
                        .font(HappyFont.displayHeadline(size: 36))
                        .foregroundColor(.happyGreen)
                        .lineSpacing(4)
                        .padding(.bottom, HappySpacing.xxl)

                    VStack(spacing: HappySpacing.lg) {
                        // Date picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DATE".uppercased())
                                .font(HappyFont.formLabel)
                                .tracking(1.4)
                                .foregroundColor(.happyGreen)
                            DatePicker("", selection: $date, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(.happyGreen)
                                .padding(.vertical, 11)
                                .padding(.horizontal, HappySpacing.md)
                                .background(Color.happyWhite)
                                .cornerRadius(HappyRadius.input)
                                .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(Color.happySandLight, lineWidth: 1))
                        }

                        // Tee time picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TEE TIME".uppercased())
                                .font(HappyFont.formLabel)
                                .tracking(1.4)
                                .foregroundColor(.happyGreen)
                            HStack(spacing: 0) {
                                wheelPicker("Hour", selection: $teeTimeHour, options: Array(1...12), label: { "\($0)" })
                                Text(":").font(HappyFont.displayMedium(size: 20)).foregroundColor(.happyGreen).padding(.horizontal, 4)
                                wheelPicker("Min", selection: $teeTimeMinute, options: Array(stride(from: 0, through: 55, by: 5)), label: { String(format: "%02d", $0) })
                                wheelPicker("AM/PM", selection: $teeTimeAMPM, options: [0, 1], label: { $0 == 0 ? "AM" : "PM" })
                            }
                            .padding(.horizontal, HappySpacing.md)
                            .padding(.vertical, 4)
                            .background(Color.happyWhite)
                            .cornerRadius(HappyRadius.input)
                            .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(Color.happySandLight, lineWidth: 1))
                        }
                    }

                    HappyPrimaryButton(title: "Save Changes →", fullWidth: true) {
                        var updated = teeTime
                        updated.date = date
                        updated.teeTimeString = teeTimeString
                        Task {
                            await appState.updateTeeTime(updated)
                            dismiss()
                        }
                    }
                    .padding(.top, HappySpacing.xxl)
                }
                .padding(.horizontal, HappySpacing.xl)

                Spacer()
            }
        }
    }

    private func wheelPicker<T: Hashable>(_ title: String, selection: Binding<T>, options: [T], label: @escaping (T) -> String) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.self) { opt in
                Text(label(opt)).foregroundColor(.happyGreen).tag(opt)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 64, height: 80)
        .clipped()
    }
}
