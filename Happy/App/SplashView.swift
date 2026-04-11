import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.happyCream.ignoresSafeArea()
            VStack(spacing: HappySpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: HappyRadius.icon)
                        .fill(Color.happyGreen)
                        .frame(width: 52, height: 52)
                    Text("⛳")
                        .font(.system(size: 28))
                }
                Text("Happy")
                    .font(HappyFont.displayMedium(size: 28))
                    .foregroundColor(.happyGreen)
            }
        }
    }
}
