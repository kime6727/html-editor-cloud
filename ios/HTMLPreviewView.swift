import SwiftUI
import WebKit

struct HTMLPreviewView: UIViewRepresentable {
    let htmlContent: String
    @Binding var isLoading: Bool
    @Binding var consoleMessages: [ConsoleMessage]
    
    struct ConsoleMessage: Identifiable {
        let id = UUID()
        let type: MessageType
        let message: String
        let timestamp: Date
        
        enum MessageType: String {
            case log, warn, error, info
        }
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "consoleHandler")
        
        let consoleScript = """
            (function() {
                var originalLog = console.log;
                var originalWarn = console.warn;
                var originalError = console.error;
                var originalInfo = console.info;
                
                function sendToNative(type, args) {
                    try {
                        var message = Array.from(args).map(function(arg) {
                            if (typeof arg === 'object') {
                                return JSON.stringify(arg);
                            }
                            return String(arg);
                        }).join(' ');
                        window.webkit.messageHandlers.consoleHandler.postMessage({type: type, message: message});
                    } catch(e) {}
                }
                
                console.log = function() { sendToNative('log', arguments); originalLog.apply(console, arguments); };
                console.warn = function() { sendToNative('warn', arguments); originalWarn.apply(console, arguments); };
                console.error = function() { sendToNative('error', arguments); originalError.apply(console, arguments); };
                console.info = function() { sendToNative('info', arguments); originalInfo.apply(console, arguments); };
                
                window.onerror = function(msg, url, line, col, error) {
                    sendToNative('error', ['Error: ' + msg + ' (line ' + line + ')']);
                    return false;
                };
            })();
        """
        
        let script = WKUserScript(source: consoleScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = true
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.scrollView.showsHorizontalScrollIndicator = true
        webView.isInspectable = true
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if htmlContent != context.coordinator.lastContent {
            context.coordinator.lastContent = htmlContent
            DispatchQueue.main.async {
                self.isLoading = true
            }
            webView.loadHTMLString(htmlContent, baseURL: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, consoleMessages: $consoleMessages)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var lastContent: String = ""
        @Binding var isLoading: Bool
        @Binding var consoleMessages: [ConsoleMessage]
        
        init(isLoading: Binding<Bool>, consoleMessages: Binding<[ConsoleMessage]>) {
            _isLoading = isLoading
            _consoleMessages = consoleMessages
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            consoleMessages.append(ConsoleMessage(
                type: .error,
                message: "Failed to load: \(error.localizedDescription)",
                timestamp: Date()
            ))
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleHandler",
               let body = message.body as? [String: Any],
               let type = body["type"] as? String,
               let msg = body["message"] as? String {
                let messageType = ConsoleMessage.MessageType(rawValue: type) ?? .log
                DispatchQueue.main.async {
                    self.consoleMessages.append(ConsoleMessage(
                        type: messageType,
                        message: msg,
                        timestamp: Date()
                    ))
                }
            }
        }
    }
}

struct ConsoleView: View {
    @Binding var messages: [HTMLPreviewView.ConsoleMessage]
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                    Text("console".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    if !messages.isEmpty {
                        Text("\(messages.count)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(10)
                    }
                    Image(systemName: isExpanded ? "arrow.down.right" : "arrow.up.right")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(messages) { message in
                            ConsoleMessageRow(message: message)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color(.systemBackground))
                
                HStack {
                    Spacer()
                    Button("clear_console".localized) {
                        messages.removeAll()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .background(Color(.systemGray6))
            }
        }
    }
}

struct ConsoleMessageRow: View {
    let message: HTMLPreviewView.ConsoleMessage
    
    var icon: String {
        switch message.type {
        case .log: return "bubble.left"
        case .warn: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .info: return "info.circle"
        }
    }
    
    var iconColor: Color {
        switch message.type {
        case .log: return .primary
        case .warn: return .orange
        case .error: return .red
        case .info: return .blue
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(iconColor)
                .frame(width: 16)
            
            Text(message.message)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(iconColor)
                .lineLimit(3)
            
            Spacer()
            
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}


