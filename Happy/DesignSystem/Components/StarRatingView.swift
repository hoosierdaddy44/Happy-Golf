import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int  // 0 = none selected

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .happyAccent : .happySandLight)
                    .font(.system(size: 26))
                    .onTapGesture { rating = star }
            }
        }
    }
}

// Read-only display version
struct StarRatingDisplayView: View {
    let rating: Double
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(.happyAccent)
                .font(.system(size: 11))
            Text(String(format: "%.1f", rating))
                .font(HappyFont.bodyMedium(size: 12))
                .foregroundColor(.happyBlack)
            if count > 0 {
                Text("(\(count))")
                    .font(HappyFont.metaTiny)
                    .foregroundColor(.happyMuted)
            }
        }
    }
}
