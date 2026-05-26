import SwiftUI

@main
struct HTMLPreviewApp: App {
    @StateObject private var appRouter = AppRouter()
    @StateObject private var documentManager = DocumentManager()

    init() {
    }
    
    @State private var showSplash = true
    
    private func dismissSplash() {
        withAnimation {
            showSplash = false
        }
    }

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .onAppear {
                        let minimumSplashTime: UInt64 = 800_000_000
                        Task {
                            try? await Task.sleep(nanoseconds: minimumSplashTime)
                            await MainActor.run {
                                if case .initializing = documentManager.initializationStatus {
                                    Task {
                                        await waitForInitialization()
                                    }
                                } else {
                                    dismissSplash()
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        dismissSplash()
                    }
            } else {
                RootView()
                    .environmentObject(appRouter)
                    .environmentObject(documentManager)
            }
        }
    }
    
    private func waitForInitialization() async {
        for _ in 0..<100 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if case .initializing = documentManager.initializationStatus {
                continue
            }
            await MainActor.run { dismissSplash() }
            return
        }
        await MainActor.run { dismissSplash() }
    }
}
