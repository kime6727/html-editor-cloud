import SwiftUI

struct EditorToolbarView: View {
    let onInsertTag: (String) -> Void
    let onFormatCode: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onCopy: () -> Void
    let onPaste: () -> Void
    let onClear: () -> Void
    let onSelectAll: () -> Void
    let canUndo: Bool
    let canRedo: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Undo/Redo
                ToolbarButton(icon: "arrow.uturn.backward", action: onUndo)
                    .disabled(!canUndo)
                
                ToolbarButton(icon: "arrow.uturn.forward", action: onRedo)
                    .disabled(!canRedo)
                
                Divider()
                    .frame(height: 24)
                
                // Edit functions
                ToolbarButton(icon: "doc.on.clipboard", action: onCopy, tooltip: "copy".localized)
                ToolbarButton(icon: "doc.on.doc", action: onPaste, tooltip: "paste".localized)
                ToolbarButton(icon: "selection.pin.in.out", action: onSelectAll, tooltip: "select_all".localized)
                ToolbarButton(icon: "trash", action: onClear, tooltip: "clear_console".localized)
                
                Divider()
                    .frame(height: 24)
                
                // HTML tags
                ToolbarButton(label: "<div>", action: { onInsertTag("<div></div>") })
                ToolbarButton(label: "<p>", action: { onInsertTag("<p></p>") })
                ToolbarButton(label: "<a>", action: { onInsertTag("<a href=\"\"></a>") })
                ToolbarButton(label: "<img>", action: { onInsertTag("<img src=\"\" alt=\"\">") })
                ToolbarButton(label: "<ul>", action: { onInsertTag("<ul>\n  <li></li>\n</ul>") })
                ToolbarButton(label: "<table>", action: { onInsertTag("<table>\n  <tr>\n    <td></td>\n  </tr>\n</table>") })
                ToolbarButton(label: "<style>", action: { onInsertTag("<style>\n\n</style>") })
                ToolbarButton(label: "<script>", action: { onInsertTag("<script>\n\n</script>") })
                
                Divider()
                    .frame(height: 24)
                
                ToolbarButton(icon: "textformat", action: onFormatCode, tooltip: "format_code".localized)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }
}

struct ToolbarButton: View {
    var icon: String?
    var label: String?
    var tooltip: String?
    let action: () -> Void
    
    init(icon: String, action: @escaping () -> Void, tooltip: String? = nil) {
        self.icon = icon
        self.label = nil
        self.tooltip = tooltip
        self.action = action
    }
    
    init(label: String, action: @escaping () -> Void, tooltip: String? = nil) {
        self.icon = nil
        self.label = label
        self.tooltip = tooltip
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Group {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                } else if let label = label {
                    Text(label)
                        .font(.system(size: 12, design: .monospaced))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .cornerRadius(6)
        }
    }
}
