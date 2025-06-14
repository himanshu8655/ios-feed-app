import AVFoundation
import Photos

func mergeVideosVertically(
    frontURL: URL,
    backURL: URL,
    outputURL: URL,
    completion: @escaping (URL?) -> Void
) {
    let frontAsset = AVURLAsset(url: frontURL)
    let backAsset = AVURLAsset(url: backURL)

    guard
        let frontVideoTrack = frontAsset.tracks(withMediaType: .video).first,
        let backVideoTrack = backAsset.tracks(withMediaType: .video).first
    else {
        NotificationCenter.default.post(name: .mergeDidFinish, object: nil)
        completion(nil)
        return
    }

    let frontAudioTrack = frontAsset.tracks(withMediaType: .audio).first

    let frontDuration = frontAsset.duration
    let backDuration = backAsset.duration

    let fSize = frontVideoTrack.naturalSize.applying(frontVideoTrack.preferredTransform)
    let bSize = backVideoTrack.naturalSize.applying(backVideoTrack.preferredTransform)
    let width = max(abs(fSize.width), abs(bSize.width))
    let height = abs(fSize.height) + abs(bSize.height)
    let renderSize = CGSize(width: width, height: height)

    let composition = AVMutableComposition()

    guard
        let frontCompTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
    else {
        NotificationCenter.default.post(name: .mergeDidFinish, object: nil)
        completion(nil)
        return
    }

    guard
        let backCompTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
    else {
        NotificationCenter.default.post(name: .mergeDidFinish, object: nil)
        completion(nil)
        return
    }

    do {
        try frontCompTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: frontDuration),
            of: frontVideoTrack,
            at: .zero
        )
    } catch {
        NotificationCenter.default.post(name: .mergeDidFinish, object: nil)
        completion(nil)
        return
    }

    let insertBackDuration = CMTimeMinimum(backDuration, frontDuration)
    do {
        try backCompTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: insertBackDuration),
            of: backVideoTrack,
            at: .zero
        )
    } catch {
        NotificationCenter.default.post(name: .mergeDidFinish, object: nil)
        completion(nil)
        return
    }

    if let audioTrack = frontAudioTrack {
        if let audioCompTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) {
            do {
                try audioCompTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: frontDuration),
                    of: audioTrack,
                    at: .zero
                )
            } catch {
            }
        }
    }

    let frontInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: frontCompTrack)
    frontInstruction.setTransform(frontVideoTrack.preferredTransform, at: .zero)

    let backInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: backCompTrack)
    let rotateTransform = backVideoTrack.preferredTransform
    let moveDownTransform = CGAffineTransform(translationX: 0, y: abs(fSize.height))
    let combinedBackTransform = rotateTransform.concatenating(moveDownTransform)
    backInstruction.setTransform(combinedBackTransform, at: .zero)

    let mainInstruction = AVMutableVideoCompositionInstruction()
    mainInstruction.timeRange = CMTimeRange(start: .zero, duration: frontDuration)
    mainInstruction.layerInstructions = [frontInstruction, backInstruction]

    let videoComposition = AVMutableVideoComposition()
    videoComposition.instructions = [mainInstruction]
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    videoComposition.renderSize = renderSize

    try? FileManager.default.removeItem(at: outputURL)

    guard let exporter = AVAssetExportSession(
        asset: composition,
        presetName: AVAssetExportPresetHighestQuality
    ) else {
        NotificationCenter.default.post(name: .mergeDidFinish, object: nil)
        completion(nil)
        return
    }
    exporter.outputURL = outputURL
    exporter.outputFileType = .mov
    exporter.videoComposition = videoComposition

    exporter.exportAsynchronously {
        DispatchQueue.main.async {
            if exporter.status == .completed {
                PHPhotoLibrary.requestAuthorization { status in
                    guard status == .authorized || status == .limited else {
                        NotificationCenter.default.post(name: .mergeDidFinish, object: nil)
                        completion(outputURL)
                        return
                    }
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
                    } completionHandler: { saved, error in
                        NotificationCenter.default.post(name: .mergeDidFinish, object: nil)
                        DispatchQueue.main.async { completion(outputURL) }
                    }
                }
            } else {
                NotificationCenter.default.post(name: .mergeDidFinish, object: nil)
                completion(nil)
            }
        }
    }
}
