import Foundation
// Inject an authenticated database query here. Do not silently fall back on failure.
struct DatabaseRecipientRepository: RecipientRepository {
    let fetch: (() async throws -> [KoCRecipient])?
    init(fetch: (() async throws -> [KoCRecipient])? = nil) { self.fetch = fetch }
    var isConfigured: Bool { fetch != nil }
    func loadRecipients() async throws -> [KoCRecipient] {
        guard let fetch else { throw RecipientRepositoryError.notConfigured }
        return try await fetch()
    }
}
