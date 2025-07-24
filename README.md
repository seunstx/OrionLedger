# OrionLedger 🏠⭐

> Immutable Property Registry in the Constellations

OrionLedger is a decentralized platform built on Stacks blockchain that enables secure registration and verification of property ownership on-chain. Property deeds are minted as NFTs with comprehensive metadata and full ownership history tracking.

## ✨ Features

- **NFT-Based Deed System**: Each property is represented as a unique NFT with immutable ownership records
- **Comprehensive Metadata**: Store property address, coordinates, type, and area information
- **Ownership History**: Complete on-chain history of all property transfers
- **Verification System**: Timestamp-based property verification for authenticity
- **Secure Transfers**: Built-in validation and error handling for all operations

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

- `get-property-details(property-id)` - Retrieve property metadata
- `get-property-owner(property-id)` - Get current property owner
- `get-total-properties()` - Get total registered properties count
- `verify-ownership(property-id, owner)` - Verify if principal owns property
- `get-property-history-count(property-id)` - Get number of ownership transfers
- `get-property-history-entry(property-id, history-id)` - Get specific history entry

### Public Functions

- `register-property(address, lat, lng, property-type, area-sqft)` - Register new property
- `transfer-property(property-id, new-owner)` - Transfer property ownership
- `verify-property(property-id)` - Update property verification timestamp
- `update-property-metadata(property-id, ...)` - Update property information

## 🏗️ Architecture

The contract uses three main data structures:

1. **NFT Collection**: `property-deed` tokens representing unique properties
2. **Property Registry**: Metadata storage for each property
3. **History Tracking**: Complete ownership transfer history

## 🔒 Security Features

- Ownership validation for all state-changing operations
- Input validation and error handling
- Immutable registration timestamps
- Protected metadata updates

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

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure `clarinet check` passes
5. Submit a pull request

## 🌟 Future Roadmap

See our planned features and enhancements in the development pipeline.