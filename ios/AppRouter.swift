import SwiftUI

class AppRouter: ObservableObject {
    @Published var showOnboarding: Bool
    @Published var currentRoute: AppRoute = .main
    
    enum AppRoute {
        case main
        case settings
        case documentList
    }
    
    init() {
        let hasSeen = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        self.showOnboarding = !hasSeen
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        withAnimation {
            showOnboarding = false
        }
    }
    
    func navigate(to route: AppRoute) {
        withAnimation {
            currentRoute = route
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var documentManager: DocumentManager
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        Group {
            switch documentManager.initializationStatus {
            case .initializing:
                SplashView()
            case .ready:
                mainAppContent
            case .failed(let error):
                InitializationErrorView(error: error)
            }
        }
        .onAppear {
        }
    }
    
    @ViewBuilder
    private var mainAppContent: some View {
        if appRouter.showOnboarding {
            OnboardingView()
        } else {
            MainTabView()
                .sheet(isPresented: $subscriptionManager.showPaywall) {
                    SubscriptionView()
                }
        }
    }
}

struct InitializationErrorView: View {
    let error: String
    @EnvironmentObject var documentManager: DocumentManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("init_failed".localized)
                .font(.title2.bold())
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("retry".localized) {
                Task {
                    await documentManager.reinitialize()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct SplashView: View {
    @State private var startAnimation = false
    
    var body: some View {
        ZStack {
            // Premium background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "0F2027"),
                    Color(hex: "203A43"),
                    Color(hex: "2C5364")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Removed glowing background circles as requested
            
            VStack(spacing: 30) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .cornerRadius(24) // App Store Style Rounded Corners
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .scaleEffect(startAnimation ? 1.0 : 0.8)
                    .opacity(startAnimation ? 1 : 0)
                
                VStack(spacing: 12) {
                    Text("html_editor_pro".localized)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("splash_tagline".localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .kerning(1.2)
                }
                .offset(y: startAnimation ? 0 : 20)
                .opacity(startAnimation ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0).delay(0.2)) {
                startAnimation = true
            }
        }
    }
}

// Helper for Hex colors if not exists
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
