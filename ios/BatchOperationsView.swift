import SwiftUI

struct BatchOperationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @StateObject private var cloudManager = CloudProjectManager.shared
    
    @Binding var selectedProjectIds: Set<String>
    @State private var selectedOperation: BatchOperation = .delete
    @State private var isExecuting = false
    @State private var showResult = false
    @State private var resultMessage = ""
    
    enum BatchOperation: String, CaseIterable, Identifiable {
        case delete = "delete"
        case extend = "extend"
        case toggleStatus = "toggle_status"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .delete: return "batch_delete".localized
            case .extend: return "batch_extend".localized
            case .toggleStatus: return "batch_toggle_status".localized
            }
        }
        
        var icon: String {
            switch self {
            case .delete: return "trash"
            case .extend: return "clock.arrow.circlepath"
            case .toggleStatus: return "switch.2"
            }
        }
        
        var color: Color {
            switch self {
            case .delete: return .red
            case .extend: return .blue
            case .toggleStatus: return .green
            }
        }
    }
    
    @State private var extendDays = 7
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("selected_count".localizedWithFormat(selectedProjectIds.count))) {
                    ForEach(BatchOperation.allCases) { operation in
                        HStack {
                            Image(systemName: operation.icon)
                                .foregroundColor(operation.color)
                                .frame(width: 24)
                            
                            Text(operation.displayName)
                                .foregroundColor(operation == .delete ? .red : .primary)
                            
                            Spacer()
                            
                            if selectedOperation == operation {
                                Image(systemName: "checkmark")
                                    .foregroundColor(operation.color)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedOperation = operation
                        }
                    }
                }
                
                if selectedOperation == .extend {
                    Section(header: Text("extend_days".localized), footer: Text("extend_days_hint".localized)) {
                        Stepper("\(extendDays) days", value: $extendDays, in: 1...365)
                    }
                }
                
                Section {
                    Button(action: executeBatch) {
                        HStack {
                            Spacer()
                            if isExecuting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("execute".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedOperation == .delete ? .red : .blue)
                            Spacer()
                        }
                    }
                    .disabled(isExecuting || selectedProjectIds.isEmpty)
                }
            }
            .navigationTitle("batch_operations".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
            }
            .alert("batch_confirm_title".localized, isPresented: $showResult) {
                Button("ok".localized) { dismiss() }
            } message: {
                Text(resultMessage)
            }
        }
    }
    
    private func executeBatch() {
        isExecuting = true
        Task {
            let backendOperation: String
            var params: [String: Any] = [:]
            
            switch selectedOperation {
            case .delete:
                backendOperation = "delete"
            case .extend:
                backendOperation = "extend_expiry"
                params["days"] = extendDays
            case .toggleStatus:
                backendOperation = "toggle_status"
                params["status"] = "active"
            }
            
            let result = await cloudManager.batchOperation(
                operation: backendOperation,
                projectIds: Array(selectedProjectIds),
                params: params
            )
            
            await MainActor.run {
                isExecuting = false
                resultMessage = "batch_success_msg".localizedWithFormat(result.successCount, result.failCount)
                showResult = true
                
                if result.success {
                    documentManager.toastItem = ToastItem(
                        message: "operation_success".localized,
                        type: .success
                    )
                    Task {
                        await cloudManager.loadPublishedProjects()
                    }
                }
            }
        }
    }
}
