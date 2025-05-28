import AVFoundation
import ComposableArchitecture
import SwiftUI

struct CameraView: View {
    @Bindable var store: StoreOf<CameraFeature>
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            if let captureSession = store.captureSession {
                CameraPreviewView(session: captureSession)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "camera")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("カメラを起動中...")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // デバッグ情報
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Auth: \(authStatusText(store.authorizationStatus))")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Active: \(store.isCameraActive ? "Yes" : "No")")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if let error = store.error {
                            Text("Error: \(error.localizedDescription)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                }
            }
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    if store.isCameraActive {
                        Button {
                            store.send(.switchCamera)
                        } label: {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 50)
                    }
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: scenePhase) { _, newPhase in
            store.send(.scenePhaseChanged(newPhase))
        }
        .alert(
            "カメラアクセス",
            isPresented: .constant(store.shouldShowPermissionAlert)
        ) {
            Button("設定を開く") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("キャンセル", role: .cancel) {
                store.send(.clearError)
            }
        } message: {
            Text("カメラの使用を許可してください。設定アプリからHandEstのカメラ権限を有効にしてください。")
        }
        .alert(
            "エラー",
            isPresented: .constant(store.error != nil),
            presenting: store.error
        ) { error in
            Button("OK") {
                store.send(.clearError)
            }
        } message: { error in
            Text(error.userMessage)
        }
    }
    
    private func authStatusText(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "NotDetermined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        @unknown default: return "Unknown"
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var previewLayer: AVCaptureVideoPreviewLayer {
            // swiftlint:disable:next force_cast
            layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        
        // メインスレッドで実行
        DispatchQueue.main.async {
            view.previewLayer.connection?.videoOrientation = .portrait
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? PreviewView else { return }
        
        // セッションの更新
        view.previewLayer.session = session
        
        // 向きの更新
        DispatchQueue.main.async {
            view.previewLayer.connection?.videoOrientation = .portrait
        }
    }
}

#Preview {
    CameraView(
        store: Store(
            initialState: CameraFeature.State(
                authorizationStatus: .authorized,
                isCameraActive: false
            )
        ) {
            CameraFeature()
        } withDependencies: {
            $0.cameraManager = .testValue
        }
    )
}