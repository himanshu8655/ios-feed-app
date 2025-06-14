import SwiftUI
import AVKit

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var currentIndex = 0
    
    @State private var isGlobalMuted = true
    
    @State private var showToast = false
    
    var body: some View {
        ZStack {            
            if viewModel.isLoading && viewModel.videos.isEmpty {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            } else if let error = viewModel.error, viewModel.videos.isEmpty {
                ErrorView(error: error, retryAction: viewModel.fetchVideos)
            } else if !viewModel.videos.isEmpty {
                VerticalPagerView(
                    currentIndex: $currentIndex,
                    items: viewModel.videos
                ) { video in
                    VideoPlayerCard(video: video, isGlobalMuted: $isGlobalMuted)
                }
                .overlay(
                    VStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.bottom, 12)
                                .tint(.white)
                        }
                    }
                )
                .refreshable {
                    viewModel.fetchVideos()
                }
                .onChange(of: currentIndex) { newIndex in
                    let threshold = viewModel.videos.count - 2
                    if newIndex >= threshold {
                        viewModel.loadPage()
                    }
                }
            } else {
                Text("No videos available")
                    .foregroundColor(.white)
            }
            
            if showToast {
                VStack {
                    Text("Double-tap to mute/unmute")
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.top, 50)
                    Spacer()
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .onAppear {
            if viewModel.videos.isEmpty {
                viewModel.fetchVideos()
            }
            
            if !showToast {
                showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showToast = false
                    }
                }
            }
        }
    }
}


struct VerticalPagerView<Item: Identifiable, Content: View>: View {
    @Binding var currentIndex: Int
    let items: [Item]
    let content: (Item) -> Content
    
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $currentIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    content(item)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .rotationEffect(.degrees(-90))
                        .tag(index)
                        .animation(.easeInOut(duration: 0.25), value: currentIndex)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(width: geometry.size.height, height: geometry.size.width)
            .rotationEffect(.degrees(90), anchor: .topLeading)
            .offset(x: geometry.size.width)
        }
    }
}


struct VideoPlayerCard: View {
    let video: Video

    @Binding var isGlobalMuted: Bool

    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .onDisappear {
                        player.pause()
                        self.player = nil
                    }
            } else {
                AsyncImage(url: video.thumbnailURL) { img in
                    img
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }

            if !isPlaying {
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                    .opacity(0.8)
            }
        }
        .background(Color.black)
        .onAppear {
            setupPlayerAndStart()
        }
        .onTapGesture(count: 2) {
            toggleMute()
        }
        .onTapGesture {
            togglePlayPause()
        }
    }

    private func setupPlayerAndStart() {
        guard player == nil else { return }
        let newPlayer = AVPlayer(url: video.videoURL)

        newPlayer.isMuted = isGlobalMuted
        newPlayer.play()
        isPlaying = true

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            newPlayer.seek(to: .zero)
            newPlayer.play()
            isPlaying = true
        }

        player = newPlayer
    }

    private func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    private func toggleMute() {
        guard let player = player else { return }
        player.isMuted.toggle()
        isGlobalMuted = player.isMuted
    }
}


struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Error loading videos")
                .font(.headline)
                .foregroundColor(.white)

            Text(error.localizedDescription)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundColor(.black)
        }
        .padding()
    }
}


struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
