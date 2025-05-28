//
//  ContentView.swift
//  HandEst
//
//  Created by fumiyasagawa on 2025/05/27.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        ZStack {
            // CameraViewを直接表示（テスト用）
            CameraView(
                store: store.scope(
                    state: \.camera,
                    action: \.camera
                )
            )
            
            // HandTrackingのデバッグビューをオーバーレイ
            VStack {
                HandTrackingView(
                    store: store.scope(
                        state: \.handTracking,
                        action: \.handTracking
                    )
                )
                
                Spacer()
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

#Preview {
    ContentView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
