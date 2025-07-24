import Foundation
import LOGIC
import CONTRACT

let chain = Blockchain()
print("\SwiftChain Demo – type 'help' for commands.\n")

func help() {
    print("""
Commands:
  add <text>                               Add a generic data block
  contract transfer <from> <to> <amt>      Transfer tokens
  contract mint <to> <amt>                 Mint tokens
  contract burn <from> <amt>               Burn tokens
  contract message <from> <text>           Attach message to chain
  balance <account>                        Show account balance
  history <account>                        Show account contract history
  print                                    Dump full chain
  validate                                 Verify chain integrity
  purge                                    Delete cache & reset
  shutdown | exit                          Save & quit
  help                                     Show this list
""")
}

while true {
    print("> ", terminator: ""); guard let line = readLine() else { break }
    let parts = line.split(separator: " ").map(String.init)
    guard let command = parts.first?.lowercased() else { continue }

    switch command {
    case "add":
        if parts.count >= 2 {
            let text = parts.dropFirst().joined(separator: " ")
            chain.addBlock(payload: text)
        } else { print("Usage: add <text>") }

    case "contract":
        guard parts.count >= 2 else { print("Usage: contract <type> …"); continue }
        let type = parts[1].lowercased()
        switch type {
        case "transfer":
            guard parts.count == 5, let amt = Int(parts[4]) else { print("Usage: contract transfer <from> <to> <amt>"); continue }
            var c = Contract.transfer(from: parts[2], to: parts[3], amount: amt)
            let sigData = "transfer\(parts[2])\(parts[3])\(amt)"
            c.signature = Contract.sign(data: sigData, withKey: "demo-key")
            chain.addBlock(payload: encodeContract(c))
        case "mint":
            guard parts.count == 4, let amt = Int(parts[3]) else { print("Usage: contract mint <to> <amt>"); continue }
            let c = Contract.mint(to: parts[2], amount: amt)
            chain.addBlock(payload: encodeContract(c))
        case "burn":
            guard parts.count == 4, let amt = Int(parts[3]) else { print("Usage: contract burn <from> <amt>"); continue }
            let c = Contract.burn(from: parts[2], amount: amt)
            chain.addBlock(payload: encodeContract(c))
        case "message":
            guard parts.count >= 4 else { print("Usage: contract message <from> <text>"); continue }
            let text = parts.dropFirst(3).joined(separator: " ")
            let c = Contract.message(from: parts[2], text: text)
            chain.addBlock(payload: encodeContract(c))
        default:
            print("Unknown contract type: \(type)")
        }

    case "balance":
        guard parts.count == 2 else { print("Usage: balance <account>"); continue }
        print("Balance of \(parts[1]): \(chain.balance(of: parts[1]))")

    case "history":
        guard parts.count == 2 else { print("Usage: history <account>"); continue }
        chain.history(for: parts[1])

    case "print": chain.printChain()

    case "validate": print(chain.validateChain() ? "Chain valid" : "!!! Chain invalid")

    case "purge": chain.purge()

    case "shutdown", "exit", "quit":
        print("⌘ Shutting down – chain saved."); exit(0)

    case "help": help()

    default: print("Unknown command – type 'help'")
    }
}