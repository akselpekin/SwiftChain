import Foundation

public enum ContractType: String, Codable {
    case transfer
}

public struct Contract: Codable {
    public let type: ContractType
    public let from: String
    public let to: String
    public let amount: Int

    public init(type: ContractType, from: String, to: String, amount: Int) {
        self.type = type
        self.from = from
        self.to = to
        self.amount = amount
    }
}

public func encodeContract(_ contract: Contract) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let data = try! encoder.encode(contract)
    return String(data: data, encoding: .utf8)!
}

public func decodeContract(_ payload: String) -> Contract? {
    let decoder = JSONDecoder()
    guard let data = payload.data(using: .utf8) else { return nil }
    return try? decoder.decode(Contract.self, from: data)
}