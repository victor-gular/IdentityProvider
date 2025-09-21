# IdentityProvider

IdentityProvider is an address reputation system smart contract for digital identity provider accuracy and security scoring built on the Stacks blockchain using the Clarity smart contract language.

## Overview

The IdentityProvider smart contract enables the creation and management of a decentralized reputation system for digital identity providers. It tracks accuracy and security scores, manages verification records, and maintains historical reputation data to ensure transparency and accountability in digital identity verification services.

## Features

- **Provider Registration**: Self-registration system for identity providers with unique names
- **Dual Scoring System**: Separate tracking of accuracy and security scores (0-100 scale)
- **Verification Recording**: Comprehensive logging of verification attempts and outcomes
- **Reputation History**: Historical tracking of score changes with block-level precision
- **Administrative Controls**: Owner-only functions for reputation updates and provider management
- **Statistical Analysis**: Success rate calculations and verification statistics
- **Provider Status Management**: Activation/deactivation capabilities for provider control
- **Weighted Reputation Calculation**: Combined accuracy (60%) and security (40%) scoring

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.0
- **Epoch**: 2.5
- **Score Range**: 0-100 (inclusive)
- **Default Score**: 50 for new providers
- **Name Length**: Maximum 50 ASCII characters

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks development environment
- [Node.js](https://nodejs.org/) - For running tests and development tools

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd IdentityProvider
```

2. Navigate to the contract directory:
```bash
cd IdentityProvider_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
clarinet test
```

## Usage Examples

### Provider Registration

```clarity
;; Register as an identity provider
(contract-call? .IdentityProvider register-provider "Acme Identity Services")
```

### Recording Verification Events

```clarity
;; Record a successful verification with positive impact
(contract-call? .IdentityProvider record-verification
  'SP1ABC...PROVIDER-ADDRESS
  true    ;; success
  5       ;; positive accuracy impact
  3)      ;; positive security impact
```

### Querying Provider Information

```clarity
;; Get complete provider information
(contract-call? .IdentityProvider get-provider 'SP1ABC...PROVIDER-ADDRESS)

;; Get only reputation scores
(contract-call? .IdentityProvider get-provider-reputation 'SP1ABC...PROVIDER-ADDRESS)

;; Get verification statistics
(contract-call? .IdentityProvider get-verification-stats 'SP1ABC...PROVIDER-ADDRESS)
```

## Contract Functions

### Public Functions

#### Provider Management
- `register-provider(name)` - Register a new identity provider
- `deactivate-provider(provider)` - Deactivate a provider (admin only)
- `reactivate-provider(provider)` - Reactivate a provider (admin only)
- `transfer-ownership(new-owner)` - Transfer contract ownership (admin only)

#### Reputation Management
- `update-reputation(provider, accuracy-score, security-score, event-type)` - Update provider scores (admin only)
- `record-verification(provider, success, accuracy-impact, security-impact)` - Record verification event

### Read-Only Functions

#### Provider Information
- `get-provider(provider)` - Get complete provider data
- `get-provider-reputation(provider)` - Get reputation scores and status
- `get-verification-stats(provider)` - Get verification statistics with success rate
- `get-overall-reputation(provider)` - Get weighted reputation score
- `is-provider-active(provider)` - Check if provider is active

#### Historical Data
- `get-reputation-history(provider, block-height)` - Get reputation at specific block
- `get-verification-record(provider, verification-id)` - Get specific verification record
- `get-verification-counter(provider)` - Get current verification counter

#### Administrative
- `get-contract-owner()` - Get current contract owner

### Error Codes

- `ERR_UNAUTHORIZED (100)` - Caller lacks required permissions
- `ERR_PROVIDER_NOT_FOUND (101)` - Provider address not registered
- `ERR_PROVIDER_ALREADY_EXISTS (102)` - Provider already registered
- `ERR_INVALID_SCORE (103)` - Score outside valid range (0-100)
- `ERR_INVALID_NAME (104)` - Empty or invalid provider name
- `ERR_PROVIDER_NOT_ACTIVE (105)` - Provider is deactivated

## Data Structures

### Provider Record
```clarity
{
  name: (string-ascii 50),
  accuracy-score: uint,
  security-score: uint,
  total-verifications: uint,
  successful-verifications: uint,
  is-active: bool,
  registration-block: uint
}
```

### Verification Record
```clarity
{
  requester: principal,
  success: bool,
  timestamp: uint,
  accuracy-impact: int,
  security-impact: int
}
```

### Reputation History
```clarity
{
  accuracy-score: uint,
  security-score: uint,
  event-type: (string-ascii 20)
}
```

## Deployment Guide

### Development Network (Devnet)

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
::deploy_contracts
```

3. Interact with the contract using the console

### Testnet Deployment

1. Configure your deployment in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure your deployment in `settings/Mainnet.toml`
2. Thoroughly test on testnet first
3. Deploy using Clarinet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Security Notes

### Access Control
- **Contract Owner**: Has exclusive rights to update reputation scores, activate/deactivate providers, and transfer ownership
- **Provider Registration**: Open to any principal, but each can only register once
- **Verification Recording**: Open to any principal for transparency

### Score Integrity
- Scores are bounded between 0-100 and validated on updates
- Historical reputation data is immutable once recorded
- Verification events include impact values for transparency

### Best Practices
- Regularly monitor provider activity and reputation changes
- Implement off-chain validation before calling reputation update functions
- Use multi-signature wallets for contract ownership in production
- Consider implementing time-based restrictions for reputation updates

### Audit Recommendations
- Review all administrative functions before mainnet deployment
- Validate score calculation logic thoroughly
- Test edge cases for verification recording
- Ensure proper access control implementation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or contributions, please:
- Open an issue on GitHub
- Review the Clarity documentation at [docs.stacks.co](https://docs.stacks.co)
- Check the Clarinet documentation at [docs.hiro.so](https://docs.hiro.so/clarinet)