![art](SwiftChain.png)

### SwiftChain

*Inspired by the original [NaiveChain](https://github.com/lhartikk/naivechain) by* **@lhartikk**.

A minimal, educational blockchain implemented in Swift.  It runs as an interactive CLI, mines proof-of-work blocks in milliseconds, persists to a local JSON cache, and supports a handful of demo-grade "smart"-contract types.

Designed to show core blockchain concepts—hash-chained blocks, PoW mining, token balances, contract processing—without heavyweight dependencies or complex networking.

```bash

Features

Category Details
Blocks index, timestamp, payload, previousHash, nonce, hash
Proof of Work Hash must start with "00" (tweakable)
Smart Contracts transfer/mint/burn/message
Balances Simple account→Int ledger, auto-recomputed on load
Persistence	Chain cached to blockchain.json in project root
Demo Signatures	Fake SHA-256 signature helper (illustrative only)(NOT SECURE!)
Integrity validate command walks and verifies whole chain
History	Per-account transaction log

```
```bash

Project Structure

Sources/
├── CORE/SwiftChain.swift   # Entry + CLI lifecycle
├── LOGIC/blockchain.swift  # Mining, validation, cache, balances
└── CONTRACT/contract.swift # Contract models, (de)serialise, signatures
blockchain.json       # Cache
README.md
Package.swift

```
```bash

Quick Start

# 1. Clone & Run

1. git clone <repo url>

2. cd SwiftChain

3. (Open a terminal instance)

4. swift run (assuming swift is installed)

```

```diff
+Command Reference

+Command	Usage & Description
!add	add <text> — append a generic data block
!contract transfer	contract transfer <from> <to> <amt>
!contract mint	contract mint <to> <amt>
!contract burn	contract burn <from> <amt>
!contract message	contract message <from> <text>
!balance	balance <account> — show current balance
!history	history <account> — list all contract events for account
!print	Dump full chain with hashes & payloads
!validate	Verify chain integrity & PoW
!purge	Delete cache and reset to genesis
!shutdown / exit	Save cache & quit
!help	Show command list
```

```diff
+Tuning Proof-of-Work

!Open Blockchain.swift and edit:

!private let powPrefix = "00" // fewer zeros → faster mining

-Increasing zeros slows mining exponentially.
```
