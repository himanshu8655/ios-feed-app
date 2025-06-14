import SwiftUI
import AVFoundation

extension Notification.Name {
    static let mergeDidFinish = Notification.Name("mergeDidFinish")
}

struct CameraView: View {
    @StateObject private var mgr = MultiCamManager()
    let onFinished: (URL, URL) -> Void

    @State private var isProcessing = false

    @State private var showRecordingIndicator = false

    @State private var didRequestPermissions = false
    @State private var permissionErrorMessage: String?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                if let errorMsg = permissionErrorMessage {
                    VStack {
                        Spacer()
                        Text(errorMsg)
                            .font(.headline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                }
                else {
                    VStack(spacing: 0) {
                        CameraSectionView(
                            previewLayer: mgr.frontLayer,
                            label: "Front Camera",
                            height: geo.size.height * 0.45
                        )

                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .frame(height: 1)

                        CameraSectionView(
                            previewLayer: mgr.backLayer,
                            label: "Back Camera",
                            height: geo.size.height * 0.45
                        )

                        Spacer()

                        recordButton
                            .padding(.horizontal, 24)
                            .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                    }

                    if showRecordingIndicator {
                        RecordingIndicator()
                            .transition(.opacity)
                    }

                    if isProcessing {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .transition(.opacity)
                    }
                }
            }
            .onAppear {
                requestCameraAndMicPermissions { granted, errorMessage in
                    DispatchQueue.main.async {
                        didRequestPermissions = true
                        permissionErrorMessage = errorMessage

                        if granted {
                            mgr.setupSession()
                            mgr.startSession()

                            NotificationCenter.default.addObserver(
                                forName: .mergeDidFinish,
                                object: nil,
                                queue: .main
                            ) { _ in
                                withAnimation(.easeInOut) {
                                    isProcessing = false
                                }
                            }
                        }
                    }
                }
            }
            .onDisappear {
                mgr.stopSession()
                NotificationCenter.default.removeObserver(
                    self,
                    name: .mergeDidFinish,
                    object: nil
                )
            }
            .onChange(of: mgr.isRecording) { isRecording in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showRecordingIndicator = isRecording
                }
            }
        }
        .navigationTitle("Dual Camera")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var recordButton: some View {
        Button(action: {
            mgr.record15Seconds { frontURL, backURL in
                withAnimation(.easeInOut) {
                    isProcessing = true
                }
                onFinished(frontURL, backURL)
            }
        }) {
            HStack(spacing: 8) {
                if mgr.isRecording {
                    Image(systemName: "record.circle.fill")
                        .symbolEffect(.pulse)
                } else {
                    Image(systemName: "record.circle")
                }
                Text(mgr.isRecording ? "Recording (15s)" : "Record 15s")
                    .fontWeight(.semibold)
            }
            .foregroundColor(mgr.isRecording ? .white : .red)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(mgr.isRecording ? Color.red : Color(.systemGray5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(mgr.isRecording ? Color.clear : Color.red, lineWidth: 2)
            )
        }
        .disabled(mgr.isRecording || permissionErrorMessage != nil)
        .buttonStyle(ScaleButtonStyle())
    }

    private func requestCameraAndMicPermissions(
        completion: @escaping (_ granted: Bool, _ errorMessage: String?) -> Void
    ) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            requestMicPermission(completion: completion)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    requestMicPermission(completion: completion)
                } else {
                    completion(false, "Camera access is required to record video.")
                }
            }

        default:
            completion(false, "Camera access has been denied. Please enable it in Settings.")
        }
    }

    private func requestMicPermission(
        completion: @escaping (_ granted: Bool, _ errorMessage: String?) -> Void
    ) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true, nil)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    completion(true, nil)
                } else {
                    completion(false, "Microphone access is required to record audio.")
                }
            }

        default:
            completion(false, "Microphone access has been denied. Please enable it in Settings.")
        }
    }
}


private struct CameraSectionView: View {
    var previewLayer: AVCaptureVideoPreviewLayer?
    var label: String
    var height: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            CameraPreviewView(previewLayer: previewLayer!)
                .frame(height: height)
                .background(Color.black)

            Text(label)
                .font(.caption)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black.opacity(0.5))
                .cornerRadius(4)
                .padding(8)
        }
    }
}

private struct RecordingIndicator: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(.red)
                    Text("Recording")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
            Spacer()
        }
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CameraView { _, _ in }
        }
    }
}
