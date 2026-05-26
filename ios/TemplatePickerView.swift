import SwiftUI

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    var onSelect: ((HTMLTemplate) -> Void)?
    
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(HTMLTemplate.templates, id: \.id) { template in
                        TemplateCard(template: template, isProFeature: template.isPro) {
                            if template.isPro && !subscriptionManager.isPro {
                                subscriptionManager.showPaywall = true
                                return
                            }
                            if let onSelect = onSelect {
                                onSelect(template)
                            } else {
                                documentManager.createNewProject(from: template)
                                dismiss()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("select_template".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) { dismiss() }
                }
            }
        }
    }
}

struct TemplateCard: View {
    let template: HTMLTemplate
    var isProFeature: Bool = false
    let onTap: () -> Void
    @State private var showPreview = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Preview area
            ZStack {
                Color(.systemGray6)
                
                if let previewImage = template.previewImage {
                    Image(previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: templateIcon)
                            .font(.system(size: 36))
                            .foregroundColor(Color("Color"))
                        
                        Text(template.category.rawValue.localized)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color("Color").opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color("Color").opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                // Pro badge overlay
                if isProFeature {
                    VStack {
                        HStack {
                            Spacer()
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }
            .frame(height: 100)
            .clipped()
            
            // Info (Fixed height for uniformity)
            VStack(alignment: .leading, spacing: 6) {
                Text(template.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(template.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(height: 34, alignment: .topLeading) // Fixed height for description
                
                Spacer(minLength: 0)
                
                HStack(spacing: 4) {
                    ForEach(template.files.prefix(3), id: \.id) { file in
                        Image(systemName: file.type.icon)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    Spacer()
                    Text(template.category.rawValue.localized)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .padding(12)
            .frame(height: 100) // Fixed height for info section
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .onTapGesture {
            onTap()
        }
    }
    
    var templateIcon: String {
        switch template.nameKey {
        case "template_blank_name": return "doc"
        case "template_website_name": return "globe"
        case "template_responsive_name": return "iphone"
        case "template_login_name": return "person.text.rectangle"
        case "template_animation_name": return "sparkles"
        case "template_click_name": return "hand.tap"
        case "template_snake_name": return "tortoise"
        case "template_breakout_name": return "square.grid.3x3"
        case "template_memory_name": return "square.on.square"
        case "template_particles_name": return "sparkles"
        case "template_clock_name": return "clock"
        case "template_cube_name": return "cube"
        case "template_typewriter_name": return "keyboard"
        case "template_todo_name": return "checklist"
        case "template_weather_name": return "cloud.sun"
        default: return template.category.icon
        }
    }
}
