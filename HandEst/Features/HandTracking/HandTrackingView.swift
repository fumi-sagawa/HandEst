import SwiftUI
import ComposableArchitecture

/// ハンドトラッキングのデバッグ情報を表示するビュー
struct HandTrackingView: View {
    let store: StoreOf<HandTrackingFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 8) {
                // デバッグモードトグル
                HStack {
                    Text("デバッグモード")
                        .font(.headline)
                    
                    Spacer()
                    
                    Toggle("", isOn: viewStore.binding(
                        get: \.isDebugMode,
                        send: HandTrackingFeature.Action.toggleDebugMode
                    ))
                    .labelsHidden()
                }
                .padding(.horizontal)
                
                if viewStore.isDebugMode {
                    DebugInfoView(
                        debugInfo: viewStore.debugInfo,
                        performanceMetrics: viewStore.performanceMetrics,
                        error: viewStore.error
                    )
                }
            }
            .padding(.vertical)
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
        }
    }
}

/// デバッグ情報の詳細表示ビュー
struct DebugInfoView: View {
    let debugInfo: DebugInfo?
    let performanceMetrics: PerformanceMetrics
    let error: MediaPipeError?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // エラー情報
            if let error = error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error.errorDescription ?? error.localizedDescription)
                        .font(.caption)
                }
                .padding(.horizontal)
            }
            
            // パフォーマンス情報
            VStack(alignment: .leading, spacing: 4) {
                Text("パフォーマンス")
                    .font(.caption.bold())
                
                HStack(spacing: 20) {
                    Label("\(String(format: "%.1f", performanceMetrics.currentFPS)) FPS", systemImage: "speedometer")
                        .font(.caption)
                    
                    Label("\(String(format: "%.1f", performanceMetrics.processingTimeMs)) ms", systemImage: "clock")
                        .font(.caption)
                }
                
                HStack(spacing: 20) {
                    Label("検出率: \(String(format: "%.0f", performanceMetrics.detectionRate * 100))%", systemImage: "eye")
                        .font(.caption)
                    
                    Label("総フレーム: \(performanceMetrics.totalFramesProcessed)", systemImage: "photo.stack")
                        .font(.caption)
                }
                
                if performanceMetrics.frameDropRate > 0.1 {
                    Label("フレームドロップ: \(String(format: "%.0f", performanceMetrics.frameDropRate * 100))%", systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal)
            
            // 手の検出情報
            if let debugInfo = debugInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("手の検出情報")
                        .font(.caption.bold())
                    
                    Text("検出された手: \(debugInfo.detectedHandsCount)")
                        .font(.caption)
                    
                    if let leftConfidence = debugInfo.leftHandConfidence {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("左手信頼度: \(String(format: "%.2f", leftConfidence))")
                        }
                        .font(.caption)
                    }
                    
                    if let rightConfidence = debugInfo.rightHandConfidence {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("右手信頼度: \(String(format: "%.2f", rightConfidence))")
                        }
                        .font(.caption)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    var state = HandTrackingFeature.State()
    state.isDebugMode = true
    state.performanceMetrics = PerformanceMetrics(
        currentFPS: 28.5,
        averageFPS: 29.2,
        processingTimeMs: 35.0,
        frameDropRate: 0.05,
        totalFramesProcessed: 150,
        detectionRate: 0.95
    )
    state.debugInfo = DebugInfo(
        detectedHandsCount: 2,
        leftHandConfidence: 0.98,
        rightHandConfidence: 0.95,
        primaryLandmarks: []
    )
    
    return HandTrackingView(
        store: Store(
            initialState: state
        ) {
            HandTrackingFeature()
        }
    )
    .background(Color.gray)
}