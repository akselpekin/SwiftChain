import Foundation
import CryptoKit
import CONTRACT

private let cacheFile = "blockchain.json"

private let powPrefix = "00"

// MARK: – Block definition
public struct Block: Codable {
    public let index: Int
    public let timestamp: Date
    public let payload: String
    public let previousHash: String
    public let nonce: Int
    public let hash: String

    public static func calculateHash(index: Int, timestamp: Date, payload: String, previousHash: String, nonce: Int) -> String {
        let input = "\(index)\(timestamp.timeIntervalSince1970)\(payload)\(previousHash)\(nonce)"
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public static func genesis() -> Block {
        let ts = Date(timeIntervalSince1970: 0)
        let h = calculateHash(index: 0, timestamp: ts, payload: "Genesis Block", previousHash: "0", nonce: 0)
        return Block(index: 0, timestamp: ts, payload: "Genesis Block", previousHash: "0", nonce: 0, hash: h)
    }
}

// MARK: – Blockchain engine
public final class Blockchain {
    public private(set) var chain: [Block]
    public private(set) var balances: [String: Int] = [:]

    public init() {
        if let cached = Self.loadCache() {
            chain = cached
            recomputeBalances()
            print("Loaded blockchain from cache (\(chain.count) blocks).")
        } else {
            chain = [Block.genesis()]
            saveCache()
            print("Started new blockchain – genesis created.")
        }
    }

    // MARK: Mining & adding
    public func addBlock(payload: String) {
        let prev = chain.last!
        let nextIdx = prev.index + 1
        let ts = Date()
        let (nonce, hash) = mine(index: nextIdx, timestamp: ts, payload: payload, previousHash: prev.hash)
        let block = Block(index: nextIdx, timestamp: ts, payload: payload, previousHash: prev.hash, nonce: nonce, hash: hash)
        guard validateBlock(block, previous: prev) else {
            print("!!! Block rejected – invalid.")
            return
        }
        chain.append(block)
        if let contract = decodeContract(payload) { process(contract) }
        saveCache()
        print("Block #\(block.index) mined (nonce \(nonce)).")
    }

    private func mine(index: Int, timestamp: Date, payload: String, previousHash: String) -> (Int, String) {
        var nonce = 0
        while true {
            let h = Block.calculateHash(index: index, timestamp: timestamp, payload: payload, previousHash: previousHash, nonce: nonce)
            if h.hasPrefix(powPrefix) { return (nonce, h) }
            nonce += 1
        }
    }

    // MARK: Validation helpers
    public func validateBlock(_ block: Block, previous: Block) -> Bool {
        guard previous.index + 1 == block.index else { return false }
        guard previous.hash == block.previousHash else { return false }
        let calcHash = Block.calculateHash(index: block.index, timestamp: block.timestamp, payload: block.payload, previousHash: block.previousHash, nonce: block.nonce)
        guard calcHash == block.hash else { return false }
        guard block.hash.hasPrefix(powPrefix) else { return false }
        return true
    }

    public func validateChain() -> Bool {
        for i in 1..<chain.count {
            if !validateBlock(chain[i], previous: chain[i-1]) { return false }
        }
        return true
    }

    // MARK: Contract processing & balances
    private func process(_ contract: Contract) {
        switch contract.type {
        case .transfer:
            guard let from = contract.from, let to = contract.to, let amt = contract.amount else { return }
            balances[from, default: 0] -= amt
            balances[to, default: 0]   += amt
        case .mint:
            guard let to = contract.to, let amt = contract.amount else { return }
            balances[to, default: 0] += amt
        case .burn:
            guard let from = contract.from, let amt = contract.amount else { return }
            balances[from, default: 0] -= amt
        case .message:
            if let from = contract.from, let txt = contract.text {
                print("[Msg] \(from): \(txt)")
            }
        }
    }

    private func recomputeBalances() {
        balances.removeAll()
        chain.forEach { blk in
            if let c = decodeContract(blk.payload) { process(c) }
        }
    }

    // MARK: Cache I/O
    private static func loadCache() -> [Block]? {
        guard FileManager.default.fileExists(atPath: cacheFile) else { return nil }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: cacheFile))
            return try JSONDecoder().decode([Block].self, from: data)
        } catch {
            print("!!! Cache load failed: \(error)")
            return nil
        }
    }

    private func saveCache() {
        do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = try encoder.encode(chain)
            try json.write(to: URL(fileURLWithPath: cacheFile))
        } catch {
            print("!!! Cache save failed: \(error)")
        }
    }

    public func purge() {
        try? FileManager.default.removeItem(atPath: cacheFile)
        chain = [Block.genesis()]
        balances.removeAll()
        saveCache()
        print("Cache purged; chain reset to genesis.")
    }

    // MARK: Queries
    public func balance(of account: String) -> Int { balances[account, default: 0] }

    public func history(for account: String) {
        for blk in chain {
            guard let c = decodeContract(blk.payload) else { continue }
            switch c.type {
            case .transfer:
                if c.from == account || c.to == account {
                    print("[#\(blk.index)] transfer \(c.amount ?? 0) from \(c.from ?? "?") to \(c.to ?? "?")")
                }
            case .mint:
                if c.to == account {
                    print("[#\(blk.index)] mint \(c.amount ?? 0) to \(account)")
                }
            case .burn:
                if c.from == account {
                    print("[#\(blk.index)] burn \(c.amount ?? 0) from \(account)")
                }
            case .message:
                if c.from == account {
                    print("[#\(blk.index)] message: \(c.text ?? "")")
                }
            }
        }
    }

    public func printChain() {
        chain.forEach { blk in
            print("""
            ————————————————————————————
            #\(blk.index)  \(blk.timestamp)
            prev: \(blk.previousHash)
            nonce: \(blk.nonce)
            hash: \(blk.hash)
            payload: \(blk.payload)
            """)
        }
    }
}