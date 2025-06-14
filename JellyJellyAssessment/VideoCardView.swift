import SwiftUI
import AVKit

struct VideoCardView: View {
    let video: Video
    @State private var player: AVPlayer?
    @State private var showControls = false
    @State private var isPlaying = false
    @State private var isMuted = true
    @State private var showTapHint = true
    @State private var showMuteFeedback = false
    @State private var controlsTimer: Timer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .onAppear {
                        player.play()
                        isPlaying = true
                        startControlsTimer()
                    }
            }
            
            AsyncImage(url: video.thumbnailURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .opacity(isPlaying ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3), value: isPlaying)
                } else if phase.error != nil {
                    Color.gray
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            
            VStack {
                Spacer()
                
                if showControls {
                    HStack {
                        Button {
                            toggleMute()
                        } label: {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        
                        Spacer()
                        
                        Button {
                            togglePlayPause()
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .transition(.opacity)
                }
            }
            
            if showMuteFeedback {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .padding(20)
                    .background(Circle().fill(Color.black.opacity(0.7)))
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation {
                                showMuteFeedback = false
                            }
                        }
                    }
            }
            
            if showTapHint {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 6) {
                        Text("Tap to \(isPlaying ? "pause" : "play")")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white)
                        
                        Text("Double tap to \(isMuted ? "unmute" : "mute")")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(10)
                    .background(Capsule().fill(Color.black.opacity(0.7)))
                    .padding(.bottom, 50)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showTapHint = false
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanupPlayer()
        }
        .onTapGesture {
            togglePlayPause()
            showControls = true
            resetControlsTimer()
        }
        .onTapGesture(count: 2) {
            toggleMute()
            showMuteFeedback = true
            resetControlsTimer()
        }
    }
    
    private func setupPlayer() {
        player = AVPlayer(url: video.videoURL)
        player?.isMuted = isMuted
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                            object: player?.currentItem,
                                            queue: .main) { _ in
            player?.seek(to: .zero)
            player?.play()
            isPlaying = true
        }
    }
    
    private func cleanupPlayer() {
        controlsTimer?.invalidate()
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    private func togglePlayPause() {
        isPlaying.toggle()
        isPlaying ? player?.play() : player?.pause()
        resetControlsTimer()
    }
    
    private func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }
    
    private func startControlsTimer() {
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        startControlsTimer()
    }
}
