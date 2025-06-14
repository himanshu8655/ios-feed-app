import Foundation
import AVFoundation

final class MultiCamManager: NSObject, ObservableObject {

    private let session = AVCaptureMultiCamSession()

    private let frontOutput = AVCaptureMovieFileOutput()
    private let backOutput  = AVCaptureMovieFileOutput()

    let frontLayer = AVCaptureVideoPreviewLayer()
    let backLayer  = AVCaptureVideoPreviewLayer()

    @Published var isRecording = false
    private var didConfigure = false


    func setupSession() {
        guard !didConfigure else { return }
        didConfigure = true

        guard AVCaptureMultiCamSession.isMultiCamSupported,
              let frontCam = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video,
                                                      position: .front),
              let backCam  = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video,
                                                      position: .back)
        else {
            return
        }

        session.beginConfiguration()


        do {
            let frontInput = try AVCaptureDeviceInput(device: frontCam)
            session.addInputWithNoConnections(frontInput)

            if let frontVideoPort = frontInput.ports.first(where: { $0.mediaType == .video }) {
                let previewConn = AVCaptureConnection(inputPort: frontVideoPort, videoPreviewLayer: frontLayer)
                if session.canAddConnection(previewConn) {
                    session.addConnection(previewConn)
                }

                if session.canAddOutput(frontOutput) {
                    session.addOutput(frontOutput)
                    let recConn = AVCaptureConnection(inputPorts: [frontVideoPort], output: frontOutput)
                    if session.canAddConnection(recConn) {
                        session.addConnection(recConn)
                    }
                }
            }
        } catch {
        }


        do {
            let backInput = try AVCaptureDeviceInput(device: backCam)
            session.addInputWithNoConnections(backInput)

            if let backVideoPort = backInput.ports.first(where: { $0.mediaType == .video }) {
                let previewConn = AVCaptureConnection(inputPort: backVideoPort, videoPreviewLayer: backLayer)
                if session.canAddConnection(previewConn) {
                    session.addConnection(previewConn)
                }

                if session.canAddOutput(backOutput) {
                    session.addOutput(backOutput)
                    let recConn = AVCaptureConnection(inputPorts: [backVideoPort], output: backOutput)
                    if session.canAddConnection(recConn) {
                        session.addConnection(recConn)
                    }
                }
            }
        } catch {
        }


        if let micDevice = AVCaptureDevice.default(for: .audio) {
            do {
                let micInput = try AVCaptureDeviceInput(device: micDevice)
                session.addInputWithNoConnections(micInput)

                if let audioPort = micInput.ports.first(where: { $0.mediaType == .audio }) {
                    let audioConn = AVCaptureConnection(inputPorts: [audioPort], output: frontOutput)
                    if session.canAddConnection(audioConn) {
                        session.addConnection(audioConn)
                    }
                }
            } catch {
                print("Failed to add microphone input: \(error)")
            }
        } else {
            print("No default audio device found")
        }

        

        frontLayer.session = session
        backLayer.session  = session
        frontLayer.videoGravity = .resizeAspectFill
        backLayer.videoGravity  = .resizeAspectFill

        session.commitConfiguration()
    }


    func startSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setMode(.videoRecording)
            try audioSession.setActive(true, options: [])
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stopSession() {
        session.stopRunning()
    }


    func record15Seconds(completion: @escaping (URL, URL) -> Void) {
        guard !isRecording else { return }
        isRecording = true

        let uuid = UUID().uuidString
        let frontURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("front_\(uuid).mov")
        let backURL  = FileManager.default.temporaryDirectory
            .appendingPathComponent("back_\(uuid).mov")

        try? FileManager.default.removeItem(at: frontURL)
        try? FileManager.default.removeItem(at: backURL)

        frontOutput.maxRecordedDuration = CMTime(seconds: 15, preferredTimescale: 600)
        backOutput.maxRecordedDuration  = CMTime(seconds: 15, preferredTimescale: 600)
        frontOutput.startRecording(to: frontURL, recordingDelegate: self)
        backOutput.startRecording(to: backURL, recordingDelegate: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.frontOutput.stopRecording()
            self.backOutput.stopRecording()
            self.isRecording = false
            completion(frontURL, backURL)
        }
    }
}


extension MultiCamManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
    }
}
