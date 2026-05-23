# CrowdFund

A decentralized crowdfunding smart contract built with Solidity and Foundry.

CrowdFund allows users to create fundraising campaigns, contribute ETH to campaigns, track contributors, withdraw successfully funded campaigns, and claim refunds from failed campaigns — all fully on-chain.

---

# Overview

CrowdFund is a Web3 crowdfunding protocol that enables decentralized fundraising without intermediaries.

The protocol supports:

- Campaign creation
- ETH contributions
- USD minimum contribution validation using Chainlink price feeds
- Contributor tracking
- Secure withdrawals
- Refunds for failed campaigns
- Event emission for frontend integrations
- Custom Solidity errors for gas optimization

This project was built to deepen understanding of Solidity smart contract engineering, storage architecture, mappings, arrays, events, and secure ETH handling patterns.

---

# Features

## Campaign Creation
Users can create fundraising campaigns with:
- title
- description
- funding goal
- campaign deadline

## ETH Funding
Users can fund campaigns directly with ETH.

## Chainlink Price Feeds
ETH contributions are validated against a minimum USD value using Chainlink oracles.

## Contributor Tracking
The protocol tracks:
- contributor addresses
- contribution amounts per campaign

## Secure Withdrawals
Campaign owners can withdraw funds only when:
- campaign deadline has passed
- funding goal has been reached

## Refund System
Contributors can reclaim funds if:
- campaign deadline has passed
- funding goal was not reached

## Events
The contract emits events for:
- campaign creation
- funding
- withdrawals
- refunds

## Custom Errors
Gas-efficient custom Solidity errors are used instead of revert strings.

---

# Smart Contract Architecture

```txt
src/
│
├── CrowdFund.sol
├── PriceConverter.sol
└── interfaces/
    └── AggregatorV3Interface.sol
```

---

# Core Solidity Concepts Used

- Structs
- Enums
- Arrays
- Nested Mappings
- Events
- Custom Errors
- Modifiers
- Payable Functions
- Chainlink Oracles
- CEI (Checks Effects Interactions) Pattern
- Storage vs Memory
- ETH Transfers using `.call`

---

# Campaign Storage Model

Each campaign is stored inside an array:

```solidity
Campaign[] private s_campaigns;
```

Campaign IDs are generated automatically using array indexes.

Example:

```txt
Campaign 0
Campaign 1
Campaign 2
```

Contributor accounting uses nested mappings:

```solidity
mapping(uint256 => mapping(address => uint256))
    private s_contributions;
```

This allows the protocol to track:

```txt
campaignId => contributor => amount funded
```

---

# Security Considerations

The contract implements several security-focused practices:

- CEI Pattern
- Access control validation
- Withdrawal state tracking
- Contribution accounting
- Refund validation
- Safe ETH transfer handling using `.call`

---

# Tech Stack

- Solidity `^0.8.24`
- Foundry
- Chainlink Price Feeds
- Ethereum

---

# Installation

## Clone Repository

```bash
git clone https://github.com/your-username/crowdfund.git
```

## Enter Project Directory

```bash
cd crowdfund
```

## Install Dependencies

```bash
forge install
```

---

# Build

```bash
forge build
```

---

# Run Tests

```bash
forge test
```

---

# Format Code

```bash
forge fmt
```

---

# Local Deployment

Start Anvil:

```bash
anvil
```

Deploy:

```bash
forge script script/DeployCrowdFund.s.sol \
--rpc-url http://127.0.0.1:8545 \
--broadcast
```

---

# Future Improvements

Planned future protocol upgrades include:

- Campaign categories
- Emergency pause functionality
- Milestone-based fund releases
- DAO governance
- Contributor voting
- Frontend integration
- Multi-chain deployment
- NFT reward systems

---

# Learning Goals

This project was built to practice:

- Smart contract architecture
- Solidity storage design
- Mapping and array patterns
- Secure ETH handling
- Protocol state management
- Chainlink integration
- Real-world Web3 engineering patterns.

---
# License

MIT


