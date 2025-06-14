import SwiftUI
import AVKit

@MainActor
class FeedViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTYzNjM4MjEwOCwiZXhwIjoxOTUxOTU4MTA4fQ.YdFG3RUvDJmRHoUQV4C5TsZcg2moGDDmnr4RNKO-Bcg"
    
    private var currentPage = 0
    private let pageSize = 10
    
    func fetchVideos() {
        currentPage = 0
        videos.removeAll()
        loadPage()
    }
    
    func loadPage() {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        
        let offset = currentPage * pageSize
        let urlString =
            "https://cbtzdoasmkbbiwnyoxvz.supabase.co/rest/v1/shareable_data" +
            "?select=*&limit=\(pageSize)&offset=\(offset)&privacy=eq.public&order=updated_at.desc"
        
        guard let url = URL(string: urlString) else {
            error = URLError(.badURL)
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(token, forHTTPHeaderField: "Apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let newVideos = try decoder.decode([Video].self, from: data)
                
                if currentPage == 0 {
                    videos = newVideos
                } else {
                    videos.append(contentsOf: newVideos)
                }
                
                if newVideos.count == pageSize {
                    currentPage += 1
                }
            } catch {
                self.error = error
                print("API Error:", error)
            }
            isLoading = false
        }
    }
}
