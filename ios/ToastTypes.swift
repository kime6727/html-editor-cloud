import SwiftUI

// MARK: - Toast Type

enum ToastType: String {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }

    var haptic: UINotificationFeedbackGenerator.FeedbackType? {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .warning
        case .info: return nil
        }
    }
}

// MARK: - Toast Item

struct ToastItem: Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval

    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }

    init(message: String, type: ToastType, duration: TimeInterval = 2.5) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let type: ToastType
    let duration: TimeInterval
    @Binding var isPresented: Bool
    @State private var dismissTask: DispatchWorkItem?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.system(size: 20, weight: .semibold))
                .accessibilityHidden(true)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button {
                dismissTask?.cancel()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            .accessibilityLabel("Dismiss notification")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.12), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(type.color.opacity(0.25), lineWidth: 1.5)
        )
        .padding(.horizontal, 16)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .onAppear {
            dismissTask?.cancel()
            let task = DispatchWorkItem {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }
            dismissTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
        }
        .onDisappear {
            dismissTask?.cancel()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.rawValue): \(message)")
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastItem?
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if isPresented, let toast = toast {
                        VStack {
                            ToastView(
                                message: toast.message,
                                type: toast.type,
                                duration: toast.duration,
                                isPresented: $isPresented
                            )
                            .padding(.top, 12)
                            Spacer()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isPresented)
            )
            .onChange(of: toast) { _, newValue in
                if newValue != nil {
                    isPresented = true
                } else {
                    isPresented = false
                }
            }
            .onChange(of: isPresented) { _, newValue in
                if !newValue {
                    toast = nil
                }
            }
    }
}

// MARK: - View Extension

extension View {
    func toast(_ toast: Binding<ToastItem?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

// MARK: - Toast Manager

@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var currentToast: ToastItem?
    private var toastQueue: [ToastItem] = []
    private var isShowing = false

    private init() {}

    func show(_ message: String, type: ToastType, duration: TimeInterval = 2.5) {
        let item = ToastItem(message: message, type: type, duration: duration)

        if isShowing {
            toastQueue.append(item)
        } else {
            present(item)
        }
    }

    func showSuccess(_ message: String, duration: TimeInterval = 2.0) {
        show(message, type: .success, duration: duration)
    }

    func showError(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .error, duration: duration)
    }

    func showWarning(_ message: String, duration: TimeInterval = 2.5) {
        show(message, type: .warning, duration: duration)
    }

    func showInfo(_ message: String, duration: TimeInterval = 2.0) {
        show(message, type: .info, duration: duration)
    }

    private func present(_ item: ToastItem) {
        isShowing = true
        currentToast = item

        if let haptic = item.type.haptic {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(haptic)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + item.duration + 0.3) { [weak self] in
            self?.showNext()
        }
    }

    private func showNext() {
        isShowing = false
        currentToast = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self, !self.toastQueue.isEmpty else { return }
            let next = self.toastQueue.removeFirst()
            self.present(next)
        }
    }
}
