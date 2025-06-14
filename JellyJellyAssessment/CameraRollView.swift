import SwiftUI
import AVKit

struct CameraRollView: View {
    let urls: [URL]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    private let spacing: CGFloat = 16
    private let itemAspect: CGFloat = 9/16
    @State private var fullscreenURL: URL? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                if urls.isEmpty {
                    Text("No videos yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(urls, id: \.self) { url in
                            Button(action: {
                                fullscreenURL = url
                            }) {
                                VideoPlayer(player: AVPlayer(url: url))
                                    .aspectRatio(itemAspect, contentMode: .fit)
                                    .cornerRadius(8)
                                    .shadow(radius: 4)
                            }
                        }
                    }
                    .padding(spacing)
                }
            }
            .navigationTitle("Camera Roll")
            .fullScreenCover(item: $fullscreenURL) { url in
                VideoDetailView(url: url)
            }
        }
    }
}

struct VideoDetailView: View {
    let url: URL
    @State private var player: AVPlayer
    @Environment(\.presentationMode) var presentationMode

    init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .onAppear { player.play() }
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
