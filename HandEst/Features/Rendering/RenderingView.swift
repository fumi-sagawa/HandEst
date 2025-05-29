import ComposableArchitecture
import SwiftUI
import RealityKit

struct RenderingView: View {
    let store: StoreOf<RenderingFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                // RealityKitビュー
                RealityKitContainerView(store: store)
                    .ignoresSafeArea()
                
                // エラー表示
                if let error = viewStore.renderingError {
                    VStack {
                        Spacer()
                        ErrorBanner(error: error.localizedDescription)
                            .padding()
                    }
                }
            }
            .onAppear {
                viewStore.send(.initializeRealityKit)
            }
        }
    }
}

/// RealityKitのコンテナビュー
struct RealityKitContainerView: UIViewRepresentable {
    let store: StoreOf<RenderingFeature>
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // カメラモードの設定（ARではなく通常の3D表示）
        arView.cameraMode = .nonAR
        
        // コーディネーターにARViewを保存
        context.coordinator.arView = arView
        context.coordinator.setupScene()
        
        return arView
    }
    
    func updateUIView(_ arView: ARView, context: Context) {
        let viewStore = ViewStore(self.store, observe: { $0 })
        
        // ランドマークの更新を処理
        if let landmarks = viewStore.currentHandLandmarks {
            context.coordinator.updateHandModel(with: landmarks)
        }
        
        // モデルタイプの変更を処理
        if context.coordinator.currentModelType != viewStore.modelType {
            context.coordinator.updateModelType(viewStore.modelType)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    typealias UIViewType = ARView
    
    class Coordinator: NSObject {
        var arView: ARView?
        var handModelEntity: ModelEntity?
        var modelProvider: HandModelProvider = SimpleHandModelProvider()
        var currentModelType: ModelType = .simple
        var anchorEntity: AnchorEntity?
        
        func setupScene() {
            guard let arView = arView else { return }
            
            // アンカーエンティティの作成
            let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, -0.3)) // カメラから30cm前方
            self.anchorEntity = anchor
            
            // 手のモデルを作成
            let handModel = modelProvider.createHandModel()
            handModelEntity = handModel
            
            anchor.addChild(handModel)
            
            // ライティングの設定
            setupLighting(for: anchor)
            
            // シーンに追加
            arView.scene.addAnchor(anchor)
        }
        
        func setupLighting(for anchor: AnchorEntity) {
            // 基本的な環境光
            let lightEntity = Entity()
            
            // ポイントライト
            let pointLight = PointLight()
            pointLight.light.intensity = 10000
            pointLight.light.color = .white
            pointLight.position = SIMD3<Float>(0, 0.2, 0)
            
            lightEntity.components.set(pointLight.light)
            lightEntity.position = pointLight.position
            
            anchor.addChild(lightEntity)
            
            // アンビエントライト（環境光）の追加
            let ambientLight = Entity()
            var ambientLightComponent = PointLight().light
            ambientLightComponent.intensity = 5000
            ambientLightComponent.color = .white
            ambientLight.components.set(ambientLightComponent)
            ambientLight.position = SIMD3<Float>(0, -0.2, 0)
            
            anchor.addChild(ambientLight)
        }
        
        func updateHandModel(with landmarks: [HandLandmark]) {
            guard let handModel = handModelEntity else { return }
            modelProvider.updateHandModel(handModel, with: landmarks)
        }
        
        func updateModelType(_ newType: ModelType) {
            guard newType != currentModelType else { return }
            
            // 新しいモデルプロバイダーを作成
            switch newType {
            case .simple:
                modelProvider = SimpleHandModelProvider()
            case .mesh, .realistic:
                // 将来実装
                modelProvider = SimpleHandModelProvider()
            }
            
            // 既存のモデルを削除して新しいモデルを作成
            if let oldModel = handModelEntity,
               let parent = oldModel.parent {
                oldModel.removeFromParent()
                
                let newModel = modelProvider.createHandModel()
                handModelEntity = newModel
                parent.addChild(newModel)
            }
            
            currentModelType = newType
        }
    }
}

/// エラーバナー表示用のビュー
struct ErrorBanner: View {
    let error: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.8))
        .cornerRadius(8)
    }
}

#Preview {
    RenderingView(
        store: Store(
            initialState: RenderingFeature.State(),
            reducer: { RenderingFeature() }
        )
    )
}