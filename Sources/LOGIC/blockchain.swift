import Foundation
import CryptoKit
import CONTRACT

let blockchainCacheFile = "blockchain.json"

public struct Block: Codable {
    public let index: Int
    public let timestamp: Date
    public let payload: String
    public let previousHash: String
    public let hash: String

    public static func calculateHash(index: Int, timestamp: Date, payload: String, previousHash: String) -> String {
        let input = "\(index)\(timestamp.timeIntervalSince1970)\(payload)\(previousHash)"
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public static func genesisBlock() -> Block {
        let ts = Date(timeIntervalSince1970: 0)
        let h = calculateHash(index: 0, timestamp: ts, payload: "Genesis Block", previousHash: "0")
        return Block(index: 0, timestamp: ts, payload: "Genesis Block", previousHash: "0", hash: h)
    }
}

public class Blockchain {
    public private(set) var chain: [Block]
    public private(set) var balances: [String: Int] = [:]

    public init() {
        if let loaded = Blockchain.loadFromCache() {
            self.chain = loaded
            self.recomputeBalances()
            print("Loaded blockchain from cache.")
        } else {
            self.chain = [Block.genesisBlock()]
            print("Initialized new blockchain.")
        }
    }

    public func getLatestBlock() -> Block {
        return chain.last!
    }

    public func addBlock(payload: String) {
        let prevBlock = getLatestBlock()
        let nextIndex = prevBlock.index + 1
        let nextTimestamp = Date()
        let nextHash = Block.calculateHash(index: nextIndex, timestamp: nextTimestamp, payload: payload, previousHash: prevBlock.hash)
        let newBlock = Block(index: nextIndex, timestamp: nextTimestamp, payload: payload, previousHash: prevBlock.hash, hash: nextHash)
        if isValidNewBlock(newBlock, previousBlock: prevBlock) {
            chain.append(newBlock)
            if let contract = CONTRACT.decodeContract(payload) {
                processContract(contract)
            }
            print("Block added (index \(newBlock.index)).")
            saveToCache()
        } else {
            print("Failed to add block: invalid block.")
        }
    }

    public func isValidNewBlock(_ newBlock: Block, previousBlock: Block) -> Bool {
        if previousBlock.index + 1 != newBlock.index { return false }
        if previousBlock.hash != newBlock.previousHash { return false }
        let hashCheck = Block.calculateHash(index: newBlock.index, timestamp: newBlock.timestamp, payload: newBlock.payload, previousHash: newBlock.previousHash)
        if hashCheck != newBlock.hash { return false }
        return true
    }

    public func printChain() {
        for block in chain {
            print("""
            ---
            Index: \(block.index)
            Time: \(block.timestamp)
            Payload: \(block.payload)
            PrevHash: \(block.previousHash)
            Hash: \(block.hash)
            """)
        }
    }

    private func processContract(_ contract: Contract) {
        switch contract.type {
        case .transfer:
            let from = contract.from
            let to = contract.to
            let amount = contract.amount
            balances[from, default: 0] -= amount
            balances[to, default: 0] += amount
        }
    }

    public func getBalance(account: String) -> Int {
        balances[account, default: 0]
    }

    public func saveToCache() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(chain)
            try data.write(to: URL(fileURLWithPath: blockchainCacheFile))
        } catch {
            print("Failed to save chain to cache: \(error)")
        }
    }

    public static func loadFromCache() -> [Block]? {
        guard FileManager.default.fileExists(atPath: blockchainCacheFile) else { return nil }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: blockchainCacheFile))
            let decoder = JSONDecoder()
            let chain = try decoder.decode([Block].self, from: data)
            return chain
        } catch {
            print("Failed to load chain from cache: \(error)")
            return nil
        }
    }

    public func purgeCache() {
        do {
            if FileManager.default.fileExists(atPath: blockchainCacheFile) {
                try FileManager.default.removeItem(atPath: blockchainCacheFile)
                print("Cache file purged.")
            }
        } catch {
            print("Failed to purge cache: \(error)")
        }
        self.chain = [Block.genesisBlock()]
        self.balances = [:]
        saveToCache()
        print("Chain reset to genesis block.")
    }

    private func recomputeBalances() {
        self.balances = [:]
        for block in chain {
            if let contract = CONTRACT.decodeContract(block.payload) {
                processContract(contract)
            }
        }
    }
}