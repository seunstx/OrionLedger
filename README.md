# OrionLedger 🏠⭐

> Immutable Property Registry with Secure Escrow System and Decentralized Dispute Resolution

OrionLedger is a decentralized platform built on Stacks blockchain that enables secure registration and verification of property ownership on-chain. Property deeds are minted as NFTs with comprehensive metadata, full ownership history tracking, secure escrow contracts for property sales, and a robust decentralized arbitration system for ownership disputes.

## ✨ Features

- **NFT-Based Deed System**: Each property is represented as a unique NFT with immutable ownership records
- **Comprehensive Metadata**: Store property address, coordinates, type, and area information
- **Ownership History**: Complete on-chain history of all property transfers
- **Verification System**: Timestamp-based property verification for authenticity
- **Secure Transfers**: Built-in validation and error handling for all operations
- **🔒 Escrow System**: Multi-signature escrow contracts for secure property sales with automated fund management
- **Multi-Party Validation**: Seller, buyer, and arbiter signature requirements for transaction security
- **Deposit Management**: Secure handling of buyer deposits with automatic refunds on cancellation
- **⚖️ Dispute Resolution**: Decentralized arbitration system for ownership disputes with evidence submission
- **Multi-Arbitrator Consensus**: 3-5 arbitrator voting system with majority ruling requirements
- **Evidence Management**: On-chain evidence submission and IPFS hash storage for dispute documentation

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd orionledger
```

2. Check contract validity:
```bash
clarinet check
```

3. Run tests:
```bash
clarinet test
```

## 📋 Contract Functions

### Read-Only Functions

**Property Functions:**
- `get-property-details(property-id)` - Retrieve property metadata
- `get-property-owner(property-id)` - Get current property owner
- `get-total-properties()` - Get total registered properties count
- `verify-ownership(property-id, owner)` - Verify if principal owns property
- `get-property-history-count(property-id)` - Get number of ownership transfers
- `get-property-history-entry(property-id, history-id)` - Get specific history entry

**Escrow Functions:**
- `get-escrow-details(escrow-id)` - Retrieve escrow contract details
- `get-property-escrow(property-id)` - Get escrow ID for a property
- `get-total-escrows()` - Get total escrows created
- `is-escrow-expired(escrow-id)` - Check if escrow has expired
- `get-escrow-funds(escrow-id)` - Get current escrow balance
- `all-parties-signed(escrow-id)` - Check if all parties have signed

**Dispute Functions:**
- `get-dispute-details(dispute-id)` - Retrieve dispute information
- `get-property-dispute(property-id)` - Get dispute ID for a property
- `get-total-disputes()` - Get total disputes created
- `is-dispute-expired(dispute-id)` - Check if dispute has expired
- `get-dispute-evidence-count(dispute-id)` - Get number of evidence submissions
- `get-dispute-evidence-entry(dispute-id, evidence-id)` - Get specific evidence entry
- `get-arbitrator-vote(dispute-id, arbitrator)` - Get arbitrator's vote details
- `has-arbitrator-voted(dispute-id, arbitrator)` - Check if arbitrator has voted
- `is-arbitrator(dispute-id, arbitrator)` - Verify arbitrator role

### Public Functions

**Property Functions:**
- `register-property(address, lat, lng, property-type, area-sqft)` - Register new property
- `transfer-property(property-id, new-owner)` - Direct property ownership transfer
- `verify-property(property-id)` - Update property verification timestamp
- `update-property-metadata(property-id, ...)` - Update property information

**Escrow Functions:**
- `create-escrow(property-id, buyer, arbiter, sale-price, deposit-amount, duration-blocks)` - Create escrow contract
- `deposit-to-escrow(escrow-id, amount)` - Deposit funds to escrow (buyer only)
- `sign-escrow(escrow-id)` - Sign escrow agreement (all parties)
- `complete-escrow(escrow-id)` - Execute property transfer and fund release
- `cancel-escrow(escrow-id)` - Cancel escrow and refund deposits

**Dispute Functions:**
- `create-dispute(property-id, respondent, dispute-type, arbitrators, duration-blocks)` - Create ownership dispute
- `submit-evidence(dispute-id, evidence-hash, description)` - Submit evidence for dispute
- `vote-on-dispute(dispute-id, vote, reasoning)` - Arbitrator voting on disputes
- `close-expired-dispute(dispute-id)` - Close expired disputes

## ⚖️ Dispute Resolution System

### 1. Creating a Dispute
- Any party can challenge property ownership by creating a dispute
- Must specify respondent, dispute type, and select 3-5 arbitrators
- System prevents disputes on properties with active escrows
- Disputes have configurable expiration periods

### 2. Evidence Submission
- Both claimant and respondent can submit evidence
- Evidence stored as IPFS hashes with descriptions
- All evidence submissions are timestamped and immutable
- Support for multiple evidence entries per dispute

### 3. Arbitrator Voting
- Selected arbitrators review evidence and cast votes
- Each arbitrator provides reasoning for their decision
- Majority consensus (>50%) required for dispute resolution
- Votes are final and cannot be changed

### 4. Dispute Resolution
- **Claimant Wins**: Property transferred to claimant automatically
- **Respondent Wins**: Current ownership maintained
- **Expiration**: Disputes can be closed after expiration period
- All outcomes recorded in property history

## 🔐 Escrow System Workflow

### 1. Creating an Escrow
- Property owner creates escrow specifying buyer, arbiter, price, and terms
- System validates all parties are different principals
- Escrow becomes active and prevents direct property transfers

### 2. Deposit and Signing
- Buyer deposits required amount to escrow contract
- All three parties (seller, buyer, arbiter) must sign the agreement
- Signatures are tracked individually and immutably

### 3. Completion or Cancellation
- **Completion**: All parties signed + sufficient funds → automatic property transfer
- **Cancellation**: Any party can cancel → automatic refund to buyer
- **Expiration**: Expired escrows can be cancelled by anyone

## 🏗️ Architecture

The contract uses eight main data structures:

1. **NFT Collection**: `property-deed` tokens representing unique properties
2. **Property Registry**: Metadata storage for each property
3. **History Tracking**: Complete ownership transfer history
4. **Escrow Registry**: Multi-signature escrow contract details
5. **Escrow Funds**: Secure fund management for each escrow
6. **Dispute Registry**: Arbitration contract details and voting status
7. **Evidence Storage**: On-chain evidence submissions with IPFS hashes
8. **Arbitrator Votes**: Individual arbitrator decisions and reasoning

## 🔒 Security Features

- Ownership validation for all state-changing operations
- Input validation and comprehensive error handling
- Immutable registration and transfer timestamps
- Protected metadata updates
- Multi-signature escrow validation
- Automatic fund management and refunds
- Expiration-based escrow protection
- Prevention of duplicate escrows/disputes per property
- Majority consensus requirement for dispute resolution
- Evidence integrity through cryptographic hashes
- Arbitrator role validation and vote finality

## 🛠️ Development

### Project Structure
```
├── contracts/
│   └── orionledger.clar
├── tests/
│   └── orionledger_test.ts
├── Clarinet.toml
└── README.md
```

### Error Codes
- `u100` - Unauthorized operation
- `u101` - Property not found
- `u102` - Property already exists
- `u103` - Invalid owner
- `u104` - Transfer failed
- `u105` - Invalid metadata
- `u106` - Escrow not found
- `u107` - Escrow already exists
- `u108` - Insufficient funds
- `u109` - Escrow not active
- `u110` - Already signed
- `u111` - Invalid signatory
- `u112` - Escrow expired
- `u113` - Invalid price
- `u114` - Invalid duration
- `u115` - Dispute not found
- `u116` - Dispute already exists
- `u117` - Invalid evidence
- `u118` - Dispute not active
- `u119` - Invalid arbitrator
- `u120` - Dispute expired
- `u121` - Already voted
- `u122` - Not arbitrator
- `u123` - Invalid ruling

## 🚀 Usage Examples

### Creating a Dispute
```clarity
(contract-call? .orionledger create-dispute
    u1                                    ;; property-id
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7  ;; respondent
    "ownership-challenge"                 ;; dispute-type
    (list                                ;; arbitrators (3-5)
        'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE
        'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE
        'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR
    )
    u2016                               ;; duration-blocks (~14 days)
)
```

### Submitting Evidence
```clarity
(contract-call? .orionledger submit-evidence
    u1                                  ;; dispute-id
    "QmX7M9CiYXjVkZk9BxjV8YzRqK4nZ2P1A3sB5c6D7e8F9g0H"  ;; IPFS hash
    "Property ownership documents and title deeds"         ;; description
)
```

### Arbitrator Voting
```clarity
(contract-call? .orionledger vote-on-dispute
    u1                                  ;; dispute-id
    "claimant"                         ;; vote (claimant/respondent)
    "Evidence clearly supports claimant's ownership claim"  ;; reasoning
)
```

### Creating an Escrow Contract
```clarity
(contract-call? .orionledger create-escrow 
    u1                    ;; property-id
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7  ;; buyer
    'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE   ;; arbiter
    u100000000            ;; sale-price (1000 STX)
    u10000000             ;; deposit-amount (100 STX)
    u1440                 ;; duration-blocks (~10 days)
)
```

### Completing a Property Sale
```clarity
;; 1. Buyer deposits funds
(contract-call? .orionledger deposit-to-escrow u1 u10000000)

;; 2. All parties sign
(contract-call? .orionledger sign-escrow u1)

;; 3. Buyer completes the transaction
(contract-call? .orionledger complete-escrow u1)
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure `clarinet check` passes
5. Submit a pull request

## 🌟 Future Roadmap

- ✅ **Dispute Resolution**: Add decentralized arbitration system for ownership disputes with evidence submission
- Property Valuation: Integrate price oracles and automated property valuation models
- Rental Management: Enable property rental agreements with automated rent collection
- Property Fragmentation: Allow fractional ownership through tokenization of property shares
- Insurance Integration: Connect with decentralized insurance protocols for property coverage
- Geographic Search: Implement spatial indexing for location-based property discovery
- Document Storage: Add IPFS integration for storing property documents and images
- Auction Mechanism: Create on-chain property auction system with bidding functionality
- Cross-Chain Bridge: Enable property deed transfers across different blockchain networks
- Advanced Arbitration: Multi-tiered arbitration with appeals process and specialized arbitrator pools