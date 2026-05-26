// MARK: - Rating System Integrations

import SwiftUI
import StoreKit

@MainActor
class RatingManager: ObservableObject {
    static let shared = RatingManager()
    
    @Published var showRatingPrompt = false
    
    private let hasRatedKey = "hasRatedApp"
    private let lastPromptDateKey = "lastRatingPromptDate"
    private let appRunCountKey = "appRunCount"
    
    var hasRated: Bool {
        get { UserDefaults.standard.bool(forKey: hasRatedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRatedKey) }
    }
    
    func incrementRunCount() {
        guard !showRatingPrompt else { return }
        
        let count = UserDefaults.standard.integer(forKey: appRunCountKey)
        UserDefaults.standard.set(count + 1, forKey: appRunCountKey)
        
        if count == 0 || (count > 0 && count % 5 == 0) {
            checkAndShowPrompt()
        }
    }
    
    func checkAndShowPrompt() {
        guard !hasRated && !showRatingPrompt else { return }
        
        if let lastDate = UserDefaults.standard.object(forKey: lastPromptDateKey) as? Date {
            if Date().timeIntervalSince(lastDate) < 3 * 24 * 3600 {
                return
            }
        }
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !self.showRatingPrompt {
                withAnimation(.spring()) {
                    self.showRatingPrompt = true
                }
            }
        }
    }
    
    func handleRating(_ rating: Int) {
        hasRated = true
        UserDefaults.standard.set(Date(), forKey: lastPromptDateKey)
        
        if rating == 5 {
            let urlString = "https://apps.apple.com/app/id\(AppConfig.appStoreID)?action=write-review"
            guard let url = URL(string: urlString) else { return }
            
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            }
        }
    }
}

struct RatingPromptView: View {
    @Binding var isPresented: Bool
    @State private var selectedRating: Int = 0
    @State private var showThanks = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                .onTapGesture { withAnimation { isPresented = false } }
            
            VStack(spacing: 20) {
                if !showThanks {
                    Text("rating_title".localized).font(.system(size: 20, weight: .bold)).multilineTextAlignment(.center)
                    Text("rating_desc".localized).font(.system(size: 16)).foregroundColor(.secondary).multilineTextAlignment(.center)
                    HStack(spacing: 15) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 30))
                                .foregroundColor(index <= selectedRating ? .orange : .gray.opacity(0.3))
                                .onTapGesture { withAnimation(.spring()) { selectedRating = index } }
                        }
                    }
                    .padding(.vertical, 10)
                    
                    Button(action: {
                        RatingManager.shared.handleRating(selectedRating)
                        if selectedRating < 5 {
                            withAnimation { showThanks = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { isPresented = false } }
                        } else {
                            isPresented = false
                        }
                    }) {
                        Text("rating_submit".localized).font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(selectedRating > 0 ? Color.blue : Color.gray).cornerRadius(12)
                    }
                    .disabled(selectedRating == 0)
                    
                    Button("rating_later".localized) { withAnimation { isPresented = false } }
                        .font(.subheadline).foregroundColor(.secondary)
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "heart.fill").font(.system(size: 50)).foregroundColor(.red)
                        Text("rating_thanks".localized).font(.headline)
                    }.transition(.scale)
                }
            }
            .padding(30).background(RoundedRectangle(cornerRadius: 24).fill(Color(UIColor.systemBackground)).shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10))
            .padding(.horizontal, 40)
        }
    }
}

