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
        // CameraViewを直接表示（テスト用）
        CameraView(
            store: store.scope(
                state: \.camera,
                action: \.camera
            )
        )
    }
}

#Preview {
    ContentView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
