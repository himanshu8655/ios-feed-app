import SwiftUI
import Photos

struct ContentView: View {
    @State private var selectedTab = 0

    @AppStorage("recordedPathsData") private var recordedPathsData: Data = Data()

    @State private var recordedURLs: [URL] = []

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tag(0)
                .tabItem { Label("Feed", systemImage: "list.bullet") }

            CameraView { frontURL, backURL in
                let filename = "merged_\(UUID().uuidString).mov"
                let mergedURL = FileManager
                    .default
                    .temporaryDirectory
                    .appendingPathComponent(filename)

                mergeVideosVertically(
                    frontURL: frontURL,
                    backURL: backURL,
                    outputURL: mergedURL
                ) { out in
                    guard let out = out else {
                        return
                    }

                    recordedURLs.append(out)

                    let paths = recordedURLs.map(\.absoluteString)
                    if let data = try? JSONEncoder().encode(paths) {
                        recordedPathsData = data
                    }
                    selectedTab = 2
                }
            }
            .tag(1)
            .tabItem { Label("Camera", systemImage: "camera") }

            CameraRollView(urls: recordedURLs)
                .tag(2)
                .tabItem { Label("Camera Roll", systemImage: "photo.on.rectangle") }
        }
        .onAppear {
            if let strings = try? JSONDecoder()
                .decode([String].self, from: recordedPathsData)
            {
                recordedURLs = strings.compactMap { URL(string: $0) }
            }
        }
    }
}
