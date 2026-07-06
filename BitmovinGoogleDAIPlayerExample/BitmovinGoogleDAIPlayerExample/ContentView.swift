import BitmovinGoogleDAIPlayer
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Bitmovin Google DAI Player")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)

            Text("Demo app setup is ready. Integration implementation is intentionally empty.")
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
