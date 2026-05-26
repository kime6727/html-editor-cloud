import SwiftUI
import WebKit

struct MultiFilePreviewView: View {
    let project: HTMLProject
    let deviceType: DeviceType
    @State private var isLoading = false
    @State private var consoleMessages: [HTMLPreviewView.ConsoleMessage] = []
    @State private var isConsoleExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header info
            HStack {
                Image(systemName: deviceType.icon)
                    .font(.caption)
                Text(deviceType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                
                Text("\(Int(deviceType.width)) × \(Int(deviceType.height))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Simulator area
            GeometryReader { geometry in
                let containerWidth = geometry.size.width - 32
                let containerHeight = geometry.size.height - 32
                
                let frameWidth = deviceType.width
                let frameHeight = deviceType.height
                
                let scaleFactor = min(
                    containerWidth / frameWidth,
                    containerHeight / frameHeight
                )
                
                ZStack {
                    Color(.systemGray5)
                    
                    ZStack {
                        // Shadow and Background
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        
                        MultiFileWebView(
                            project: project,
                            isLoading: $isLoading,
                            consoleMessages: $consoleMessages
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if isLoading {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("loading".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(12)
                        }
                    }
                    .frame(width: frameWidth, height: frameHeight)
                    .scaleEffect(scaleFactor)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            
            ConsoleView(messages: $consoleMessages, isExpanded: $isConsoleExpanded)
        }
    }
}

// MARK: - Multi File WebView
struct MultiFileWebView: UIViewRepresentable {
    let project: HTMLProject
    @Binding var isLoading: Bool
    @Binding var consoleMessages: [HTMLPreviewView.ConsoleMessage]
    @EnvironmentObject var documentManager: DocumentManager
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "consoleHandler")
        contentController.add(context.coordinator, name: "nativeBridge")
        
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
        
        let bridgeScript = """
            window.antigravity = {
                haptic: function(style) {
                    window.webkit.messageHandlers.nativeBridge.postMessage({action: 'haptic', data: {style: style || 'medium'}});
                },
                share: function(text, url) {
                    window.webkit.messageHandlers.nativeBridge.postMessage({action: 'share', data: {text: text, url: url}});
                },
                saveData: function(key, value) {
                    window.webkit.messageHandlers.nativeBridge.postMessage({action: 'saveData', data: {key: key, value: value}});
                },
                close: function() {
                    window.webkit.messageHandlers.nativeBridge.postMessage({action: 'close'});
                }
            };
        """
        
        contentController.addUserScript(WKUserScript(source: consoleScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        contentController.addUserScript(WKUserScript(source: bridgeScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        
        configuration.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = true
        webView.isInspectable = true
        
        webView.scrollView.minimumZoomScale = 0.25
        webView.scrollView.maximumZoomScale = 5.0
        webView.scrollView.isMultipleTouchEnabled = true
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinchGesture.delegate = context.coordinator
        webView.scrollView.addGestureRecognizer(pinchGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = context.coordinator
        webView.scrollView.addGestureRecognizer(doubleTapGesture)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if the project content actually changed or if it's the first load
        let projectHash = project.files.map { "\($0.id):\($0.updatedAt.timeIntervalSince1970)" }.joined()
        if projectHash != context.coordinator.lastProjectHash {
            context.coordinator.lastProjectHash = projectHash
            
            if let result = documentManager.prepareProjectForRunning(project) {
                DispatchQueue.main.async {
                    self.isLoading = true
                }
                webView.loadFileURL(result.indexURL, allowingReadAccessTo: result.projectDir)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, consoleMessages: $consoleMessages)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, UIGestureRecognizerDelegate {
        var lastProjectHash: String = ""
        @Binding var isLoading: Bool
        @Binding var consoleMessages: [HTMLPreviewView.ConsoleMessage]
        private var currentScale: CGFloat = 1.0
        private var lastScale: CGFloat = 1.0
        
        init(isLoading: Binding<Bool>, consoleMessages: Binding<[HTMLPreviewView.ConsoleMessage]>) {
            _isLoading = isLoading
            _consoleMessages = consoleMessages
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            
            if gesture.state == .began {
                lastScale = scrollView.zoomScale
            }
            
            let newScale = min(max(lastScale * gesture.scale, scrollView.minimumZoomScale), scrollView.maximumZoomScale)
            scrollView.setZoomScale(newScale, animated: false)
            
            if gesture.state == .ended || gesture.state == .cancelled {
                lastScale = newScale
            }
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            
            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                let point = gesture.location(in: scrollView)
                let zoomRect = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            consoleMessages.append(HTMLPreviewView.ConsoleMessage(
                type: .error,
                message: String(format: "load_failed".localized, error.localizedDescription),
                timestamp: Date()
            ))
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleHandler",
               let body = message.body as? [String: Any],
               let type = body["type"] as? String,
               let msg = body["message"] as? String {
                let messageType = HTMLPreviewView.ConsoleMessage.MessageType(rawValue: type) ?? .log
                DispatchQueue.main.async {
                    self.consoleMessages.append(HTMLPreviewView.ConsoleMessage(
                        type: messageType,
                        message: msg,
                        timestamp: Date()
                    ))
                }
            } else if message.name == "nativeBridge",
                      let body = message.body as? [String: Any],
                      let action = body["action"] as? String {
                let data = body["data"] as? [String: Any]
                handleBridgeAction(action, data: data)
            }
        }
        
        private func handleBridgeAction(_ action: String, data: [String: Any]?) {
            switch action {
            case "haptic":
                let styleStr = data?["style"] as? String ?? "medium"
                let style: UIImpactFeedbackGenerator.FeedbackStyle
                switch styleStr {
                case "light": style = .light
                case "medium": style = .medium
                case "heavy": style = .heavy
                case "rigid": style = .rigid
                case "soft": style = .soft
                default: style = .medium
                }
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
                
            case "share":
                if let text = data?["text"] as? String {
                    let urlStr = data?["url"] as? String
                    let url = urlStr.flatMap { URL(string: $0) }
                    var items: [Any] = [text]
                    if let url = url {
                        items.append(url)
                    }
                    
                    let avc = UIActivityViewController(activityItems: items, applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(avc, animated: true)
                    }
                }
                
            case "saveData":
                if let key = data?["key"] as? String, let value = data?["value"] {
                    UserDefaults.standard.set(value, forKey: "html_tool_data_\(key)")
                }
                
            case "close":
                NotificationCenter.default.post(name: NSNotification.Name("ClosePreview"), object: nil)
                
            default:
                break
            }
        }
    }
}
