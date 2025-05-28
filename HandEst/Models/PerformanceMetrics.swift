import Foundation

/// 手認識のパフォーマンスメトリクスを管理する構造体
public struct PerformanceMetrics: Equatable, Codable {
    /// 現在のFPS
    public var currentFPS: Double = 0
    
    /// 平均FPS
    public var averageFPS: Double = 0
    
    /// 処理時間（ミリ秒）
    public var processingTimeMs: Double = 0
    
    /// フレームドロップ率（0.0-1.0）
    public var frameDropRate: Double = 0
    
    /// 処理された総フレーム数
    public var totalFramesProcessed: Int = 0
    
    /// 手の検出率（0.0-1.0）
    public var detectionRate: Double = 0
    
    public init(
        currentFPS: Double = 0,
        averageFPS: Double = 0,
        processingTimeMs: Double = 0,
        frameDropRate: Double = 0,
        totalFramesProcessed: Int = 0,
        detectionRate: Double = 0
    ) {
        self.currentFPS = currentFPS
        self.averageFPS = averageFPS
        self.processingTimeMs = processingTimeMs
        self.frameDropRate = frameDropRate
        self.totalFramesProcessed = totalFramesProcessed
        self.detectionRate = detectionRate
    }
}