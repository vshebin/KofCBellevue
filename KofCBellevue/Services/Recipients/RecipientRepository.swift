import Foundation
protocol RecipientRepository {
    func loadRecipients() async throws -> [KoCRecipient]
}
enum RecipientRepositoryError: LocalizedError {
    case notConfigured
    var errorDescription: String? { "The church database is not configured yet." }
}
