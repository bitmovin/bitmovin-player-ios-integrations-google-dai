import BitmovinGoogleDAIPlayer
import BitmovinPlayerCore
import Foundation
import SwiftUI

struct ContentView: View {
    private let player: Player

    init() {
        let config = PlayerConfig()
        config.key = "YOUR-LICENSE-KEY"

        player = PlayerFactory.createGoogleDaiPlayer(
            playerConfig: config
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Bitmovin Google DAI Player")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)

            VideoPlayerView(
                player: player
            )
            .aspectRatio(16 / 9, contentMode: .fit)
            .cornerRadius(25)

            Spacer()
        }
        .padding()
        .onAppear {
            let googleDaiSource = GoogleDaiSource()

            player.googleDai.load(source: googleDaiSource)
        }
    }
}

#Preview {
    ContentView()
}
