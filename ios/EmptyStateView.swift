import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    var secondaryButtonTitle: String? = nil
    var secondaryButtonAction: (() -> Void)? = nil
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: isAnimating ? -3 : 3)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                    Button(action: {
                        HapticScenario.buttonTap.feedback()
                        buttonAction()
                    }) {
                        Label(buttonTitle, systemImage: "doc.badge.plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color("Color"), Color("Color").opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
                
                if let secondaryButtonTitle = secondaryButtonTitle, let secondaryButtonAction = secondaryButtonAction {
                    Button(action: {
                        HapticScenario.buttonTap.feedback()
                        secondaryButtonAction()
                    }) {
                        Label(secondaryButtonTitle, systemImage: "square.on.square")
                            .font(.headline)
                            .foregroundColor(Color("Color"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Color").opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct FileBrowserEmptyState: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                    .offset(y: isAnimating ? -2 : 2)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            VStack(spacing: 6) {
                Text("no_files".localized)
                    .font(.headline)
                
                Text("add_files_hint".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct PreviewEmptyState: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.green.opacity(0.1), .blue.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                Image(systemName: "eye.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }
            
            VStack(spacing: 8) {
                Text("no_preview".localized)
                    .font(.title3.bold())
                
                Text("select_project_preview".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}
