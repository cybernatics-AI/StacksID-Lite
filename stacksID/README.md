# Cross-Chain Identity Contract

A minimal, efficient smart contract for managing cross-chain user identities on the Stacks blockchain. This contract allows users to create unified profiles and link addresses from multiple blockchain networks.

## Overview

The Cross-Chain Identity Contract provides a simple yet powerful foundation for managing user identities across different blockchain ecosystems. Users can register a profile on Stacks and associate addresses from Ethereum, Solana, Cosmos, Bitcoin, and other supported chains.

## Features

- **User Registration**: Create a unique identity with a username
- **Cross-Chain Address Linking**: Associate addresses from multiple blockchain networks
- **Address Verification**: Contract owner can verify linked addresses for authenticity
- **Extensible Chain Support**: Easy to add support for new blockchain networks
- **Gas Efficient**: Minimal storage and computation requirements

## Supported Chains

The contract currently supports the following blockchain networks:

| Chain ID | Network |
|----------|---------|
| 1        | Ethereum |
| 2        | Solana |
| 3        | Cosmos |
| 4        | Bitcoin |

## Contract Functions

### Public Functions

#### `register(username)`
Register a new identity with a unique username.

**Parameters:**
- `username` (string-ascii 50): Unique username for the identity

**Returns:** `(ok true)` on success

**Errors:**
- `ERR-IDENTITY-EXISTS (u101)`: Identity already exists for this principal

**Example:**
```clarity
(contract-call? .cross-chain-identity register "alice123")
```

#### `add-chain-address(chain, address)`
Link an address from another blockchain to your identity.

**Parameters:**
- `chain` (uint): Chain ID of the blockchain network
- `address` (string-ascii 128): Address on the specified chain

**Returns:** `(ok true)` on success

**Errors:**
- `ERR-IDENTITY-NOT-FOUND (u102)`: User must register first
- `ERR-INVALID-CHAIN (u103)`: Chain is not supported

**Example:**
```clarity
(contract-call? .cross-chain-identity add-chain-address u1 "0x742d35Cc6634C0532925a3b8D0C9c0e1B0aE9b12")
```

#### `verify-chain-address(user, chain)`
Verify a user's linked address (contract owner only).

**Parameters:**
- `user` (principal): The user whose address to verify
- `chain` (uint): Chain ID of the address to verify

**Returns:** `(ok true)` on success

**Errors:**
- `ERR-NOT-AUTHORIZED (u100)`: Only contract owner can verify
- `ERR-IDENTITY-NOT-FOUND (u102)`: Address link not found

### Read-Only Functions

#### `get-profile(user)`
Retrieve a user's profile information.

**Parameters:**
- `user` (principal): The user's principal address

**Returns:** Profile data or `none` if not found

#### `get-chain-address(user, chain)`
Get a user's linked address for a specific chain.

**Parameters:**
- `user` (principal): The user's principal address
- `chain` (uint): Chain ID to query

**Returns:** Address link data or `none` if not found

#### `get-total-users()`
Get the total number of registered users.

**Returns:** Total user count (uint)

## Data Structures

### User Profile
```clarity
{
    username: (string-ascii 50),
    created-at: uint,
    profile-hash: (optional (buff 32)),
    is-active: bool
}
```

### Chain Link
```clarity
{
    address: (string-ascii 128),
    verified: bool,
    added-at: uint
}
```

## Usage Examples

### Basic Registration Flow
```clarity
;; 1. Register a new identity
(contract-call? .cross-chain-identity register "alice")

;; 2. Add Ethereum address
(contract-call? .cross-chain-identity add-chain-address u1 "0x742d35Cc6634C0532925a3b8D0C9c0e1B0aE9b12")

;; 3. Add Solana address
(contract-call? .cross-chain-identity add-chain-address u2 "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU")

;; 4. Check profile
(contract-call? .cross-chain-identity get-profile 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Verification (Owner Only)
```clarity
;; Verify a user's Ethereum address
(contract-call? .cross-chain-identity verify-chain-address 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u1)
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100  | ERR-NOT-AUTHORIZED | Caller not authorized for this action |
| 101  | ERR-IDENTITY-EXISTS | Identity already exists for this principal |
| 102  | ERR-IDENTITY-NOT-FOUND | Identity or address link not found |
| 103  | ERR-INVALID-CHAIN | Specified chain is not supported |

## Deployment

1. Deploy the contract to Stacks blockchain
2. The deploying address becomes the contract owner
3. Users can immediately start registering identities

## Security Considerations

- **Owner Privileges**: Only the contract owner can verify addresses
- **Identity Uniqueness**: Each principal can only have one identity
- **Chain Validation**: Addresses can only be added for supported chains
- **No Native Verification**: Address verification requires manual approval by owner

## Future Enhancements

- **Automated Verification**: Implement cryptographic proof verification
- **Profile Metadata**: Support for avatars, bio, and other profile data
- **Reputation System**: Track cross-chain activity and reputation scores
- **Governance**: Transition to decentralized governance for chain additions
- **Address Migration**: Allow updating of linked addresses

## Development

### Prerequisites
- Clarinet CLI
- Stacks blockchain knowledge
- Understanding of cross-chain concepts

### Testing
```bash
clarinet test
```

### Local Development
```bash
clarinet console
clarinet integrate
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Contact

For questions or support, please open an issue in the repository.