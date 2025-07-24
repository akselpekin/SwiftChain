import Foundation
import LOGIC
import CONTRACT

let blockchain = Blockchain()
print("SwiftChain (with contracts, persistent cache). Type 'help' for commands.")

func printHelp() {
    print("""
    Commands:
      add <text>                            Add a block with given text
      contract transfer <from> <to> <amt>   Add a transfer contract block
      balance <account>                     Show account balance
      print                                 Print the full chain
      last                                  Show the last block
      shutdown                              Save and quit
      purge                                 Delete cache and reset chain
      help                                  Show this message
      exit                                  Force quit
    """)
}

while true {
    print("> ", terminator: "")
    guard let line = readLine() else { break }
    let parts = line.split(separator: " ").map { String($0) }
    guard let cmd = parts.first?.lowercased() else { continue }

    switch cmd {
    case "add":
        if parts.count >= 2 {
            let text = parts.dropFirst().joined(separator: " ")
            blockchain.addBlock(payload: text)
        } else {
            print("Usage: add <data>")
        }
    case "contract":
        if parts.count == 5 && parts[1].lowercased() == "transfer" {
            let from = parts[2]
            let to = parts[3]
            if let amount = Int(parts[4]) {
                let contract = Contract(type: .transfer, from: from, to: to, amount: amount)
                let payload = encodeContract(contract)
                blockchain.addBlock(payload: payload)
            } else {
                print("Amount must be an integer.")
            }
        } else {
            print("Usage: contract transfer <from> <to> <amount>")
        }
    case "balance":
        if parts.count == 2 {
            let account = parts[1]
            let balance = blockchain.getBalance(account: account)
            print("\(account): \(balance)")
        } else {
            print("Usage: balance <account>")
        }
    case "print":
        blockchain.printChain()
    case "last":
        let last = blockchain.getLatestBlock()
        print("""
        Index: \(last.index)
        Time: \(last.timestamp)
        Payload: \(last.payload)
        PrevHash: \(last.previousHash)
        Hash: \(last.hash)
        """)
    case "purge":
        blockchain.purgeCache()
    case "shutdown", "exit", "quit":
        blockchain.saveToCache()
        print("Saved chain. Exiting.")
        exit(0)
    case "help":
        printHelp()
    default:
        print("Unknown command. Type 'help' for a list of commands.")
    }
}