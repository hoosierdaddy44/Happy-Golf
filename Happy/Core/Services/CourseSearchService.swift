import MapKit
import SwiftUI

struct CourseResult: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let location: String // "City, ST"
}

@MainActor
class CourseSearchService: ObservableObject {
    @Published var results: [CourseResult] = []
    @Published var isSearching = false

    private var searchTask: Task<Void, Never>?

    func search(query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }
            isSearching = true
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "\(query) golf course"
            request.resultTypes = .pointOfInterest
            if let response = try? await MKLocalSearch(request: request).start() {
                results = response.mapItems.compactMap { item in
                    guard let name = item.name else { return nil }
                    let city = item.placemark.locality ?? ""
                    let state = item.placemark.administrativeArea ?? ""
                    let loc = [city, state].filter { !$0.isEmpty }.joined(separator: ", ")
                    return CourseResult(name: name, location: loc)
                }
            }
            isSearching = false
        }
    }

    func clear() {
        searchTask?.cancel()
        results = []
        isSearching = false
    }
}
