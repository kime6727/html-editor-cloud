import SwiftUI

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let gradientColors: [Color]
}

struct OnboardingView: View {
    @EnvironmentObject var appRouter: AppRouter
    @State private var currentPage = 0
    
    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                icon: "play.circle.fill",
                title: "onboarding_title_1".localized,
                description: "onboarding_desc_1".localized,
                gradientColors: [Color.blue, Color.purple]
            ),
            OnboardingPage(
                icon: "doc.on.clipboard.fill",
                title: "onboarding_title_2".localized,
                description: "onboarding_desc_2".localized,
                gradientColors: [Color.purple, Color.pink]
            ),
            OnboardingPage(
                icon: "qrcode",
                title: "onboarding_title_3".localized,
                description: "onboarding_desc_3".localized,
                gradientColors: [Color.pink, Color.orange]
            ),
            OnboardingPage(
                icon: "crown.fill",
                title: "onboarding_title_4".localized,
                description: "onboarding_desc_4".localized,
                gradientColors: [Color.orange, Color.yellow]
            )
        ]
    }
    
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        ZStack {
            // Professional Deep Black Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 15/255, green: 15/255, blue: 18/255),
                    Color(red: 26/255, green: 26/255, blue: 36/255),
                    Color(red: 20/255, green: 20/255, blue: 30/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle glow effect
            Circle()
                .fill(Color("Color").opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: 100, y: -200)
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                VStack(spacing: 30) {
                    PageIndicator(currentPage: currentPage, totalPages: pages.count)
                    
                    if currentPage == pages.count - 1 {
                        VStack(spacing: 16) {
                            Button {
                                subscriptionManager.showPaywall = true
                            } label: {
                                HStack {
                                    Text("upgrade_now".localized)
                                    Image(systemName: "crown.fill")
                                }
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 280)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color("Color"))
                                        .shadow(color: Color("Color").opacity(0.4), radius: 10, x: 0, y: 5)
                                )
                            }
                            
                            Button {
                                appRouter.completeOnboarding()
                            } label: {
                                Text("get_started".localized)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.bottom, 60)
                    } else {
                        HStack {
                            Button("skip".localized) {
                                appRouter.completeOnboarding()
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.leading, 36)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    currentPage += 1
                                }
                            } label: {
                                HStack {
                                    Text("next_step".localized)
                                    Image(systemName: "arrow.right")
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 36)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color("Color"))
                                        .shadow(color: Color("Color").opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                            }
                            .padding(.trailing, 36)
                        }
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .sheet(isPresented: $subscriptionManager.showPaywall) {
            SubscriptionView()
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 180, height: 180)
                
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(6)
            }
            
            Spacer()
        }
        .padding(.top, 80)
    }
}

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AppRouter())
    }
}
