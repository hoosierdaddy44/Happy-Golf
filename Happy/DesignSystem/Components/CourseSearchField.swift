import SwiftUI

/// A text field that shows golf course autocomplete suggestions via MapKit.
/// If `location` binding is provided, it will be auto-filled when a course is selected.
struct CourseSearchField: View {
    let label: String
    @Binding var courseName: String
    var location: Binding<String>? = nil

    @StateObject private var service = CourseSearchService()
    @State private var showSuggestions = false
    @State private var fieldFrame: CGRect = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Label
            Text(label.uppercased())
                .font(HappyFont.formLabel)
                .tracking(1.4)
                .foregroundColor(.happyGreen)
                .padding(.bottom, 6)

            // Input
            HStack {
                TextField("e.g. Bethpage Black", text: $courseName)
                    .font(HappyFont.bodyRegular(size: 14))
                    .foregroundColor(.happyBlack)
                    .onChange(of: courseName) { _, val in
                        showSuggestions = true
                        service.search(query: val)
                    }

                if service.isSearching {
                    ProgressView().scaleEffect(0.7)
                } else if !courseName.isEmpty {
                    Button {
                        courseName = ""
                        location?.wrappedValue = ""
                        service.clear()
                        showSuggestions = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.happyMuted)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(HappySpacing.md)
            .background(Color.happyCream)
            .cornerRadius(HappyRadius.input)
            .overlay(RoundedRectangle(cornerRadius: HappyRadius.input).stroke(Color.happySandLight, lineWidth: 1))
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        fieldFrame = geo.frame(in: .global)
                    }.onChange(of: geo.frame(in: .global)) { _, frame in
                        fieldFrame = frame
                    }
                }
            )
        }
        .overlay(alignment: .topLeading) {
            if showSuggestions && !service.results.isEmpty {
                suggestionsList
                    .frame(width: fieldFrame.width)
                    .offset(y: fieldFrame.height + 26) // label height + input height
                    .zIndex(999)
            }
        }
    }

    private var suggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(service.results.prefix(5).enumerated()), id: \.element.id) { idx, result in
                Button {
                    courseName = result.name
                    location?.wrappedValue = result.location
                    service.clear()
                    showSuggestions = false
                } label: {
                    HStack(spacing: HappySpacing.sm) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.happyGreenLight)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name)
                                .font(HappyFont.bodyMedium(size: 13))
                                .foregroundColor(.happyBlack)
                            if !result.location.isEmpty {
                                Text(result.location)
                                    .font(HappyFont.metaTiny)
                                    .foregroundColor(.happyMuted)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, HappySpacing.md)
                    .padding(.vertical, HappySpacing.sm)
                    .background(Color.happyWhite)
                }
                .buttonStyle(.plain)

                if idx < min(service.results.count, 5) - 1 {
                    HappyDivider().padding(.horizontal, HappySpacing.md)
                }
            }
        }
        .background(Color.happyWhite)
        .cornerRadius(HappyRadius.card)
        .overlay(RoundedRectangle(cornerRadius: HappyRadius.card).stroke(Color.happySandLight, lineWidth: 1))
        .shadow(color: Color.happyGreen.opacity(0.1), radius: 16, y: 6)
    }
}
