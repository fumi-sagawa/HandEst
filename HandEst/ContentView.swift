//
//  ContentView.swift
//  HandEst
//
//  Created by fumiyasagawa on 2025/05/27.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 20) {
                Image(systemName: "hand.wave.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 40))
                
                Text("HandEst")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("手のトラッキングとリアルタイム3Dモデル変換")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                if viewStore.isLoading {
                    ProgressView("読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .padding()
            .onAppear {
                viewStore.send(.onAppear)
            }
            .alert(
                "エラー",
                isPresented: .constant(viewStore.hasError),
                actions: {
                    Button("OK") {
                        viewStore.send(.dismissError)
                    }
                },
                message: {
                    if let errorMessage = viewStore.errorMessage {
                        Text(errorMessage)
                    }
                }
            )
        }
    }
}

#Preview {
    ContentView(
        store: Store(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        )
    )
}
