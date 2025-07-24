import Foundation
import CryptoKit

public enum ContractType: String, Codable {
    case transfer
    case mint
    case burn
    case message
}

public struct Contract: Codable {
    public let type: ContractType
    public let from: String?
    public let to: String?
    public let amount: Int?
    public let text: String?
    public var signature: String?

    // MARK: – Convenience factories
    public static func transfer(from: String, to: String, amount: Int) -> Contract {
        Contract(type: .transfer, from: from, to: to, amount: amount, text: nil, signature: nil)
    }
    public static func mint(to: String, amount: Int) -> Contract {
        Contract(type: .mint, from: nil, to: to, amount: amount, text: nil, signature: nil)
    }
    public static func burn(from: String, amount: Int) -> Contract {
        Contract(type: .burn, from: from, to: nil, amount: amount, text: nil, signature: nil)
    }
    public static func message(from: String, text: String) -> Contract {
        Contract(type: .message, from: from, to: nil, amount: nil, text: text, signature: nil)
    }

    // MARK: – Demo signature helper (NOT secure)
    public static func sign(data: String, withKey key: String) -> String {
        let digest = SHA256.hash(data: Data((data + key).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: – (De)serialisation helpers
public func encodeContract(_ contract: Contract) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try! encoder.encode(contract)
    return String(data: data, encoding: .utf8)!
}

public func decodeContract(_ payload: String) -> Contract? {
    guard let data = payload.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(Contract.self, from: data)
}