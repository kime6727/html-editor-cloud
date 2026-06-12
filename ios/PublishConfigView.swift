import SwiftUI

struct PublishConfigView: View {
    @Environment(\.dismiss) var dismiss
    let project: HTMLProject
    @Binding var isPresented: Bool
    let onPublish: (PublishConfig) -> Void
    
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var expireDays: Int = 0
    @State private var enableStats: Bool = true
    @State private var enablePassword: Bool = false
    @State private var accessPassword: String = ""
    @State private var showValidationError = false
    @State private var validationMessage: String = ""
    
    var expireOptions: [(Int, String)] {
        if subscriptionManager.isPro {
            return [
                (0, "never_expire".localized),
                (7, "7_days".localized),
                (30, "30_days".localized),
                (90, "90_days".localized)
            ]
        } else {
            return [
                (0, "1_hour".localized)
            ]
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("expire_settings".localized)) {
                    if subscriptionManager.isPro {
                        Picker("expire_after".localized, selection: $expireDays) {
                            ForEach(expireOptions, id: \.0) { option in
                                Text(option.1).tag(option.0)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("expire_hint".localized + " \(expireDays) " + "days".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text("free_publish_hint".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("stats_settings".localized)) {
                    Toggle("enable_visit_stats".localized, isOn: $enableStats)
                    
                    if enableStats {
                        HStack {
                            Image(systemName: "chart.bar")
                                .foregroundColor(.green)
                            Text("stats_hint".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("password_protection".localized)) {
                    Toggle("enable_password".localized, isOn: $enablePassword)
                    
                    if enablePassword {
                        SecureField("set_access_password".localized, text: $accessPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        Text("password_hint".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: publish) {
                        HStack {
                            Spacer()
                            Image(systemName: "icloud.and.arrow.up")
                            Text("publish_now".localized)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(isValid ? Color("Color") : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isValid)
                    .listRowBackground(Color.clear)
                }
            }
            .onAppear {
                Task { await SubscriptionManager.shared.verifyProStatus() }
            }
            .navigationTitle("publish_config".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
            }
        }
    }
    
    private var isValid: Bool {
        // If password is enabled, password must not be empty
        if enablePassword && accessPassword.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        // Password length check
        if enablePassword && accessPassword.count < 4 {
            return false
        }
        return true
    }
    
    private func publish() {
        let config = PublishConfig(
            expireDays: expireDays,
            enableStats: enableStats,
            accessPassword: enablePassword && !accessPassword.isEmpty ? accessPassword : nil
        )
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onPublish(config)
        }
    }
}
