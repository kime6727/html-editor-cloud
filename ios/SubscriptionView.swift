import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Text("unlock_pro_title".localized)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    
                    Text("pro_description".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Features
                VStack(alignment: .leading, spacing: 18) {
                    FeatureRow(icon: "archivebox.fill", title: "feature_zip_import".localized, description: "feature_zip_import_desc".localized, isNew: true)
                    FeatureRow(icon: "icloud.and.arrow.up.fill", title: "feature_cloud_publish".localized, description: "feature_cloud_publish_desc".localized)
                    FeatureRow(icon: "infinity", title: "feature_unlimited_projects".localized, description: "feature_unlimited_projects_desc".localized)
                    FeatureRow(icon: "folder.badge.plus", title: "feature_multi_file".localized, description: "feature_multi_file_desc".localized)
                    FeatureRow(icon: "iphone.badge.play", title: "feature_pro_preview".localized, description: "feature_pro_preview_desc".localized)
                    FeatureRow(icon: "sparkles", title: "feature_pro_templates".localized, description: "feature_pro_templates_desc".localized)
                }
                .padding(.horizontal, 24)
                
                // Footer & Agreements
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        Button("restore_purchases".localized) {
                            Task {
                                await subscriptionManager.restorePurchases()
                            }
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        
                        Text("|")
                            .foregroundColor(.secondary.opacity(0.3))
                        
                        Button("terms_of_service".localized) {
                            if let url = URL(string: "https://page.niceapp.eu.cc/index.php/archives/User-Service-Agreement.html") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        
                        Text("|")
                            .foregroundColor(.secondary.opacity(0.3))
                        
                        Button("privacy_policy".localized) {
                            if let url = URL(string: "https://page.niceapp.eu.cc/index.php/archives/Privacy-Policy.html") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                    
                    Text("subscription_agreement_hint".localized)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 120) // Extra padding for sticky button
            }
        }
        .safeAreaInset(edge: .bottom) {
            purchaseBar
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding()
            }
        }
    }
    
    private var purchaseBar: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("lifetime_pro".localized)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        if let product = subscriptionManager.products.first {
                            Text(product.displayPrice)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        } else if subscriptionManager.isFetching {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("---")
                                .font(.title3.bold())
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await subscriptionManager.upgradeToPro()
                        }
                    }) {
                        HStack {
                            if subscriptionManager.isPurchasing {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text("upgrade_now".localized)
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("Color"))
                                .shadow(color: Color("Color").opacity(0.4), radius: 10, x: 0, y: 5)
                        )
                    }
                    .disabled(subscriptionManager.isPurchasing)
                    .frame(width: 200) // Much larger button
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(.ultraThinMaterial)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var isNew: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color("Color").opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .foregroundColor(Color("Color"))
                    .font(.system(size: 20, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.headline)
                    
                    if isNew {
                        Text("new_tag".localized)
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    SubscriptionView()
}
