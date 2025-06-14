import Photos

func saveVideoToPhotos(url: URL, completion: @escaping (Bool) -> Void) {
    PHPhotoLibrary.requestAuthorization { status in
        guard status == .authorized || status == .limited else {
            DispatchQueue.main.async { completion(false) }
            return
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
