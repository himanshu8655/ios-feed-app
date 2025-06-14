import SwiftUI
import AVKit


struct Video: Identifiable, Decodable {
    let id: String
    let updatedAt: String
    let content: Content
    
    struct Content: Decodable {
        let url: URL
        let bucket: String
        let thumbnails: [URL]
    }
    
    var videoURL: URL { content.url }
    var thumbnailURL: URL { content.thumbnails.first ?? URL(string: "https://example.com/placeholder.jpg")! }
}
