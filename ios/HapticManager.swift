import UIKit

@MainActor
struct HapticManager {
    static let shared = HapticManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        prepare()
    }

    func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        softGenerator.prepare()
        rigidGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    func lightImpact() {
        lightGenerator.impactOccurred()
    }

    func mediumImpact() {
        mediumGenerator.impactOccurred()
    }

    func heavyImpact() {
        heavyGenerator.impactOccurred()
    }

    func softImpact() {
        softGenerator.impactOccurred()
    }

    func rigidImpact() {
        rigidGenerator.impactOccurred()
    }

    func selection() {
        selectionGenerator.selectionChanged()
    }

    func notificationSuccess() {
        notificationGenerator.notificationOccurred(.success)
    }

    func notificationWarning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    func notificationError() {
        notificationGenerator.notificationOccurred(.error)
    }
}

enum HapticScenario {
    case buttonTap
    case selectionChange
    case successAction
    case failureAction
    case warning
    case deleteAction
    case pullToRefresh
    case scrollEdge
    case tabSwitch
    case createAction
    case saveAction
    case copyAction
    case pasteAction
    case shareAction
    case toggleOn
    case toggleOff

    @MainActor
    var feedback: () -> Void {
        switch self {
        case .buttonTap:
            return { HapticManager.shared.lightImpact() }
        case .selectionChange:
            return { HapticManager.shared.selection() }
        case .successAction:
            return {
                HapticManager.shared.notificationSuccess()
                HapticManager.shared.lightImpact()
            }
        case .failureAction:
            return {
                HapticManager.shared.notificationError()
                HapticManager.shared.mediumImpact()
            }
        case .warning:
            return { HapticManager.shared.notificationWarning() }
        case .deleteAction:
            return { HapticManager.shared.mediumImpact() }
        case .pullToRefresh:
            return { HapticManager.shared.softImpact() }
        case .scrollEdge:
            return { HapticManager.shared.lightImpact() }
        case .tabSwitch:
            return { HapticManager.shared.lightImpact() }
        case .createAction:
            return { HapticManager.shared.notificationSuccess() }
        case .saveAction:
            return { HapticManager.shared.softImpact() }
        case .copyAction:
            return { HapticManager.shared.lightImpact() }
        case .pasteAction:
            return { HapticManager.shared.lightImpact() }
        case .shareAction:
            return { HapticManager.shared.mediumImpact() }
        case .toggleOn:
            return { HapticManager.shared.softImpact() }
        case .toggleOff:
            return { HapticManager.shared.softImpact() }
        }
    }
}
