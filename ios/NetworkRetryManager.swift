import Foundation

actor NetworkRetryManager {
    static let shared = NetworkRetryManager()
    private init() {}

    enum RetryPolicy {
        case exponentialBackoff(maxRetries: Int, baseDelay: TimeInterval)
        case fixedDelay(maxRetries: Int, delay: TimeInterval)
        case noRetry

        var maxRetries: Int {
            switch self {
            case .exponentialBackoff(let maxRetries, _): return maxRetries
            case .fixedDelay(let maxRetries, _): return maxRetries
            case .noRetry: return 0
            }
        }
    }

    enum NetworkError: Error, Equatable {
        case maxRetriesExceeded
        case cancelled
        case noInternet
        case serverError(statusCode: Int)
        case unknown(Error)

        static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
            switch (lhs, rhs) {
            case (.maxRetriesExceeded, .maxRetriesExceeded): return true
            case (.cancelled, .cancelled): return true
            case (.noInternet, .noInternet): return true
            case (.serverError(let a), .serverError(let b)): return a == b
            default: return false
            }
        }
    }

    func execute<T>(
        policy: RetryPolicy = .exponentialBackoff(maxRetries: 3, baseDelay: 1.0),
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        for attempt in 0...policy.maxRetries {
            do {
                return try await operation()
            } catch let urlError as URLError {
                if urlError.code == .cancelled {
                    throw NetworkError.cancelled
                }
                if urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                    throw NetworkError.noInternet
                }
                if attempt < policy.maxRetries {
                    let delay = calculateDelay(policy: policy, attempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                if attempt < policy.maxRetries {
                    let delay = calculateDelay(policy: policy, attempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw NetworkError.maxRetriesExceeded
    }

    private func calculateDelay(policy: RetryPolicy, attempt: Int) -> TimeInterval {
        switch policy {
        case .exponentialBackoff(_, let baseDelay):
            return baseDelay * pow(2.0, Double(attempt))
        case .fixedDelay(_, let delay):
            return delay
        case .noRetry:
            return 0
        }
    }
}

extension CloudService {
    func publishProjectWithRetry(_ project: HTMLProject) async -> (url: String, id: String)? {
        do {
            return try await NetworkRetryManager.shared.execute(
                policy: .exponentialBackoff(maxRetries: 3, baseDelay: 1.0)
            ) {
                if let result = await self.publishProjectWithDetails(project) {
                    return (url: result.url, id: result.id)
                } else {
                    throw NetworkRetryManager.NetworkError.unknown(NSError(domain: "Publish", code: -1))
                }
            }
        } catch NetworkRetryManager.NetworkError.maxRetriesExceeded {
            await MainActor.run {
                self.error = "publish_retry_failed".localized
                self.isPublishing = false
            }
            return nil
        } catch NetworkRetryManager.NetworkError.noInternet {
            await MainActor.run {
                self.error = "network_offline".localized
                self.isPublishing = false
            }
            return nil
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isPublishing = false
            }
            return nil
        }
    }
}
