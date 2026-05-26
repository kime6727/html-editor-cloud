import SwiftUI

struct AutoCompleteView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("suggestions".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(suggestions.enumerated()), id: \.element) { index, suggestion in
                        Button(action: {
                            HapticScenario.buttonTap.feedback()
                            onSelect(suggestion)
                        }) {
                            Text(suggestion)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    index == selectedIndex ? Color.blue.opacity(0.2) : Color(.systemGray5)
                                )
                                .foregroundColor(index == selectedIndex ? .blue : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
