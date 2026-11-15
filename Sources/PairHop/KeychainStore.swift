import Foundation
import Security

struct KeychainError: Error, LocalizedError, Equatable {
    var message: String
    var status: OSStatus

    var errorDescription: String? { "\(message) (\(status))." }
}

enum KeychainStore {
    private static let service = "com.posadskiy.pairhop.peer-code"

    private static let legacyService = "com.posadskiy.perihop.peer-code"

    private static var itemQuery: [String: Any] { query(for: service) }

    private static func query(for service: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
    }

    /// PeriHop kept the code under another name. Copies it across, then removes the old item.
    /// macOS may ask to allow the new app to read it; if that is declined the code is
    /// entered again in Settings.
    static func adoptLegacyCode() {
        guard readCode() == nil else { return }
        var query = query(for: legacyService)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let code = String(data: data, encoding: .utf8), !code.isEmpty else { return }
        do {
            try saveCode(code)
            SecItemDelete(self.query(for: legacyService) as CFDictionary)
        } catch {
            AppLog.config.error("Could not carry the pairing code over: \(error)")
        }
    }

    static func readCode() -> String? {
        var query = itemQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Replaces the stored code in place, so a failed write keeps the old one.
    /// An empty code removes it.
    static func saveCode(_ code: String) throws {
        guard !code.isEmpty else {
            let status = SecItemDelete(itemQuery as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError(message: "Couldn't remove the pairing code", status: status)
            }
            return
        }
        let data = Data(code.utf8)
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(itemQuery as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else {
            throw KeychainError(message: "Couldn't save the pairing code", status: status)
        }
        var add = itemQuery
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let added = SecItemAdd(add as CFDictionary, nil)
        guard added == errSecSuccess else {
            throw KeychainError(message: "Couldn't save the pairing code", status: added)
        }
    }
}
