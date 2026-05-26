@preconcurrency import SwiftUI
import UIKit

struct EnhancedHTMLEditorView: UIViewRepresentable {
    @Binding var text: String
    var onTextChange: ((String) -> Void)?
    @Binding var showLineNumbers: Bool
    @Binding var showSyntaxHighlight: Bool
    @Binding var scrollOffset: CGFloat
    var fontSize: CGFloat = 14
    
    func makeUIView(context: Context) -> UITextView {
        let textView = context.coordinator.makeTextView()
        textView.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.backgroundColor = .systemBackground
        textView.textColor = UIColor.label
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.keyboardType = .asciiCapable
        textView.returnKeyType = .default
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.allowsEditingTextAttributes = false
        
        // Apply syntax highlighting immediately if text is not empty
        if !text.isEmpty {
            textView.text = text
            applySyntaxHighlighting(to: textView)
        }
        
        let toolbar = createKeyboardToolbar()
        DispatchQueue.main.async {
            textView.inputAccessoryView = toolbar
        }
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            let selectedRange = textView.selectedRange
            context.coordinator.isApplyingHighlight = true
            textView.text = text
            textView.selectedRange = selectedRange
            context.coordinator.isApplyingHighlight = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func applySyntaxHighlighting(to textView: UITextView, preservingRange: NSRange? = nil) {
        guard let text = textView.text, !text.isEmpty else { return }
        
        let textLength = text.count
        
        if textLength > 50000 {
            return
        }
        
        let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        if textLength > 15000 {
            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: textLength))
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: textLength))
            
            let fastPatterns: [(pattern: String, color: UIColor)] = [
                ("</?[a-zA-Z][a-zA-Z0-9]*[^>]*>", UIColor.systemBlue),
                ("\"[^\"]*\"", UIColor.systemOrange),
                ("<!--.*?-->", UIColor.systemGreen),
            ]
            
            for (pattern, color) in fastPatterns {
                do {
                    let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                    let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: textLength))
                    for match in matches {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: match.range)
                    }
                } catch {
                    continue
                }
            }
            
            textView.attributedText = attributedString
            if let range = preservingRange {
                let maxLocation = textView.text?.count ?? 0
                let safeLocation = min(range.location, maxLocation)
                let safeLength = min(range.length, maxLocation - safeLocation)
                textView.selectedRange = NSRange(location: safeLocation, length: safeLength)
            }
            return
        }
        
        let attributedString = NSMutableAttributedString(string: text)
        
        attributedString.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: textLength))
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: textLength))
        
        let patterns: [(pattern: String, color: UIColor)] = [
            ("<!--.*?-->", UIColor.systemGreen),
            ("</?[a-zA-Z][a-zA-Z0-9]*[^>]*>", UIColor.systemBlue),
            ("\\b[a-zA-Z-]+=", UIColor.systemPurple),
            ("\"[^\"]*\"", UIColor.systemOrange),
            ("'[^']*'", UIColor.systemOrange),
            ("#[0-9a-fA-F]{3,8}\\b", UIColor.systemOrange),
            ("\\b\\d+\\.?\\d*(px|em|rem|%|vh|vw|s|ms)?\\b", UIColor.systemOrange),
            ("\\b(function|var|let|const|if|else|for|while|return|class|import|export)\\b", UIColor.systemPink),
            ("\\b(console|document|window)\\.", UIColor.systemYellow),
            ("\\b(log|warn|error|info)\\(", UIColor.systemYellow),
        ]
        
        for (pattern, color) in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: textLength))
                for match in matches {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: match.range)
                }
            } catch {
                continue
            }
        }
        
        textView.attributedText = attributedString
        
        if let range = preservingRange {
            let maxLocation = textView.text?.count ?? 0
            let safeLocation = min(range.location, maxLocation)
            let safeLength = min(range.length, maxLocation - safeLocation)
            textView.selectedRange = NSRange(location: safeLocation, length: safeLength)
        }
    }
    
    @MainActor
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: EnhancedHTMLEditorView
        private var debounceTimer: Timer?
        private var lastText: String = ""
        private var searchMatchObserver: NSObjectProtocol?
        var isApplyingHighlight = false
        
        private var keyboardInsertObserver: NSObjectProtocol?
        private var keyboardDismissObserver: NSObjectProtocol?
        private var selectAllObserver: NSObjectProtocol?

        init(_ parent: EnhancedHTMLEditorView) {
            self.parent = parent
            self.lastText = parent.text
            super.init()
            
            searchMatchObserver = NotificationCenter.default.addObserver(
                forName: .searchMatchFound,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                let range = notification.userInfo?["range"] as? Range<String.Index>
                
                Task { @MainActor in
                    guard let self = self,
                          let range = range else { return }
                    
                    let nsRange = NSRange(range, in: self.parent.text)
                    self.textView?.selectedRange = nsRange
                    self.textView?.scrollRangeToVisible(nsRange)
                }
            }

            keyboardInsertObserver = NotificationCenter.default.addObserver(
                forName: .insertKeyboardText,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                let text = notification.userInfo?["text"] as? String
                
                Task { @MainActor in
                    guard let self = self,
                          let textView = self.textView,
                          let text = text else { return }
                    
                    let selectedRange = textView.selectedRange
                    if let swiftRange = Range(selectedRange, in: textView.text) {
                        textView.text.replaceSubrange(swiftRange, with: text)
                        let newPosition = selectedRange.location + text.count
                        textView.selectedRange = NSRange(location: newPosition, length: 0)
                        self.textViewDidChange(textView)
                    }
                }
            }

            keyboardDismissObserver = NotificationCenter.default.addObserver(
                forName: .dismissKeyboard,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.textView?.resignFirstResponder()
                }
            }

            selectAllObserver = NotificationCenter.default.addObserver(
                forName: .selectAllText,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self, let textView = self.textView else { return }
                    textView.selectedRange = NSRange(location: 0, length: textView.text.count)
                    textView.becomeFirstResponder()
                }
            }
        }
        
        weak var textView: UITextView?
        
        func makeTextView() -> UITextView {
            let textView = UITextView()
            textView.delegate = self
            self.textView = textView
            return textView
        }
        
        deinit {
            MainActor.assumeIsolated {
                if let observer = searchMatchObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                if let observer = keyboardInsertObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                if let observer = keyboardDismissObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                if let observer = selectAllObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if isApplyingHighlight {
                return
            }
            
            let newText = textView.text ?? ""
            lastText = newText
            
            DispatchQueue.main.async {
                self.parent.text = newText
                self.parent.onTextChange?(newText)
            }
            
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self, weak textView] _ in
                guard let self = self, let textView = textView else { return }
                Task { @MainActor in
                    if self.parent.showSyntaxHighlight {
                        self.isApplyingHighlight = true
                        self.parent.applySyntaxHighlighting(to: textView)
                        self.isApplyingHighlight = false
                    }
                }
            }
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard text == ">" else { return true }
            
            let nsString = textView.text as NSString
            let before = nsString.substring(to: range.location)
            
            if let lastOpen = before.lastIndex(of: "<") {
                let tagStart = before.index(after: lastOpen)
                let tagContent = String(before[tagStart...])
                
                let trimmed = tagContent.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty && !trimmed.hasPrefix("/") && !trimmed.hasPrefix("!") else { return true }
                
                let tagName = trimmed.components(separatedBy: CharacterSet.whitespaces.union(.init(charactersIn: ">/"))).first ?? trimmed
                guard !tagName.isEmpty else { return true }
                
                let selfClosingTags = ["br", "hr", "img", "input", "meta", "link", "area", "base", "col", "embed", "param", "source", "track", "wbr"]
                guard !selfClosingTags.contains(tagName.lowercased()) else { return true }
                
                let closingTag = "</\(tagName)>"
                let insertText = ">\(closingTag)"
                
                if let swiftRange = Range(range, in: textView.text) {
                    textView.text.replaceSubrange(swiftRange, with: insertText)
                    let newPosition = range.location + 1
                    textView.selectedRange = NSRange(location: newPosition, length: 0)
                    self.textViewDidChange(textView)
                    return false
                }
            }
            
            return true
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let offset = scrollView.contentOffset.y
            DispatchQueue.main.async {
                self.parent.scrollOffset = offset
            }
        }
    }

    private func createKeyboardToolbar() -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.barStyle = .default
        toolbar.isTranslucent = false
        toolbar.backgroundColor = UIColor.systemGray6
        toolbar.layer.borderWidth = 0.5
        toolbar.layer.borderColor = UIColor.separator.cgColor

        let items: [UIBarButtonItem] = [
            createToolbarButton(title: "<", input: "<"),
            createToolbarButton(title: ">", input: ">"),
            createToolbarButton(title: "/", input: "/"),
            createToolbarButton(title: "\"", input: "\""),
            createToolbarButton(title: "=", input: "="),
            createToolbarButton(title: "{", input: "{"),
            createToolbarButton(title: "}", input: "}"),
            createToolbarButton(title: ";", input: ";"),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            createToolbarButton(title: "dismiss_keyboard".localized, input: nil)
        ]

        toolbar.setItems(items, animated: false)
        return toolbar
    }

    private func createToolbarButton(title: String, input: String?) -> UIBarButtonItem {
        var config = UIButton.Configuration.plain()
        let nsAttrs = [NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 16, weight: .semibold)]
        let attributedTitle = NSAttributedString(string: title, attributes: nsAttrs)
        config.attributedTitle = AttributedString(attributedTitle)
        config.baseForegroundColor = input != nil ? UIColor.label : UIColor.systemBlue
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        
        let button = UIButton(configuration: config)
        
        if let input = input {
            button.addTarget(KeyboardToolbarHandler.shared, action: #selector(KeyboardToolbarHandler.shared.insertText(_:)), for: .touchUpInside)
            objc_setAssociatedObject(button, &AssociatedKeys.inputText, input, .OBJC_ASSOCIATION_RETAIN)
        } else {
            button.addTarget(KeyboardToolbarHandler.shared, action: #selector(KeyboardToolbarHandler.shared.dismissKeyboard(_:)), for: .touchUpInside)
        }
        
        let item = UIBarButtonItem(customView: button)
        return item
    }
}

private struct AssociatedKeys {
    nonisolated(unsafe) static var inputText: UInt8 = 0
}

extension Notification.Name {
    static let insertKeyboardText = Notification.Name("insertKeyboardText")
    static let dismissKeyboard = Notification.Name("dismissKeyboard")
}

@MainActor
final class KeyboardToolbarHandler: NSObject {
    static let shared = KeyboardToolbarHandler()

    @objc func insertText(_ sender: UIBarButtonItem) {
        guard let input = objc_getAssociatedObject(sender, &AssociatedKeys.inputText) as? String else { return }
        NotificationCenter.default.post(name: .insertKeyboardText, object: nil, userInfo: ["text": input])
    }

    @objc func dismissKeyboard(_ sender: UIBarButtonItem) {
        NotificationCenter.default.post(name: .dismissKeyboard, object: nil)
    }
}

struct LineNumbersView: View {
    let text: String
    let scrollOffset: CGFloat
    let fontSize: CGFloat
    
    private var lineCount: Int {
        let components = text.components(separatedBy: "\n")
        return max(components.count, 1)
    }
    
    private var lineHeight: CGFloat {
        return fontSize * 1.5
    }
    
    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(1...lineCount, id: \.self) { line in
                        Text("\(line)")
                            .font(.system(size: fontSize * 0.85, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(height: lineHeight)
                            .id(line)
                    }
                }
            }
            .onChange(of: scrollOffset) { oldValue, newValue in
                let currentLine = Int(newValue / lineHeight) + 1
                if currentLine > 0 && currentLine <= lineCount {
                    withAnimation(.none) {
                        reader.scrollTo(currentLine, anchor: .top)
                    }
                }
            }
        }
    }
}

struct LineNumbersHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct EditorWithLineNumbers: View {
    @Binding var text: String
    var onTextChange: ((String) -> Void)?
    @State private var scrollOffset: CGFloat = 0
    var fontSize: CGFloat = 14
    
    var body: some View {
        HStack(spacing: 0) {
            LineNumbersView(text: text, scrollOffset: scrollOffset, fontSize: fontSize)
            
            EnhancedHTMLEditorView(
                text: $text,
                onTextChange: onTextChange,
                showLineNumbers: .constant(true),
                showSyntaxHighlight: .constant(true),
                scrollOffset: $scrollOffset,
                fontSize: fontSize
            )
        }
    }
}
