import SwiftUI

@main
struct HTMLPreviewApp: App {
    @StateObject private var appRouter = AppRouter()
    @StateObject private var documentManager = DocumentManager()

    init() {
    }

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environmentObject(appRouter)
                .environmentObject(documentManager)
        }
    }
}

/// 顶层容器：把 splash 切换逻辑移到这里，
/// 避免 `@State` 放在 `App` 结构体里导致 SwiftUI 行为不可靠，
/// 也避免 init 死锁时整个 app 一直停在白屏 launch screen。
struct RootContainerView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @State private var showSplash = true
    @State private var didKickoffWatchdog = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                RootView()
                    .transition(.opacity)
            }
        }
        .task {
            // 最小展示时长 800ms
            try? await Task.sleep(nanoseconds: 800_000_000)
            await waitForReadyOrForce(maxIterations: 200, intervalNs: 100_000_000)
        }
        .onTapGesture {
            // 用户点击 splash 直接进入
            withAnimation { showSplash = false }
        }
    }

    /// 等待初始化完成；最多等 200 * 100ms = 20s，
    /// 即便 init 死锁也会强制 dismiss 进入 RootView。
    @MainActor
    private func waitForReadyOrForce(maxIterations: Int, intervalNs: UInt64) async {
        for _ in 0..<maxIterations {
            try? await Task.sleep(nanoseconds: intervalNs)
            if case .initializing = documentManager.initializationStatus {
                continue
            }
            withAnimation { showSplash = false }
            return
        }
        // 超时：强制 dismiss，让 RootView 显示失败/默认界面
        NSLog("[HTMLPreviewApp] initialization watchdog timeout, force dismiss splash")
        withAnimation { showSplash = false }
    }
}
