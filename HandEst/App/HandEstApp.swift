//
//  HandEstApp.swift
//  HandEst
//
//  Created by fumiyasagawa on 2025/05/27.
//

import SwiftUI
import ComposableArchitecture

@main
struct HandEstApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(
                    initialState: AppFeature.State(),
                    reducer: { AppFeature() }
                )
            )
        }
    }
}
