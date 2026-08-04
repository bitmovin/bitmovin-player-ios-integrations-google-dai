import BitmovinPlayer
import SwiftUI

struct ContentView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Google DAI integration tests running")
                .font(.title.weight(.semibold))

            Spacer()

            Image(systemName: "play.diamond.fill")
                .font(.system(size: 64, weight: .light))
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    .white,
                    Color(red: 0, green: 106.0 / 255.0, blue: 237.0 / 255.0)
                )
                .scaleEffect(isAnimating ? 1.08 : 0.92)
                .opacity(isAnimating ? 1 : 0.7)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Text("Please don't interrupt this test run.")
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Bitmovin Player: \(PlayerFactory.sdkVersion)")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ContentView()
}
