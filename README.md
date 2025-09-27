# 🌟 CryptoNomads

**A decentralized social layer application  that connects Discord usernames with identities through Self Protocol and ENS integration.**
## 🚀 Overview

CryptoNomads is a revolutionary identity verification system that bridges Web2 social identities (Discord) with Web3 blockchain identities. Users can verify their real-world identity through Self Protocol's privacy-preserving zero-knowledge proofs and automatically receive ENS subdomains mapped to their Discord usernames.

## ✨ Features

- **🔐 Privacy-First Verification**: Uses Self Protocol's zero-knowledge proofs for identity verification
- **👤 Discord Integration**: Maps verified identities to Discord usernames
- **🌐 ENS Subdomain Registration**: Automatic `.cryptonomads.eth` subdomain mint label with your universal discord profile
- **🛡️ Age Verification**: Ensures users are 18+ years old
- **🌍 Compliance**: Built-in country restrictions and OFAC compliance

## 🏗️ Architecture


## 📋 Contract Details

| Property | Value |
|----------|-------|
| **Contract Address** | `0x149cbA3EE15C863563a18808814a10815369458E` |
| **Network** | Celo Mainnet |
| **Verification Hub** | `0xe57F4773bd9c9d8b6Cd70431117d353298B9f5BF` |
| **ENS Registry** | `0x22FAbb6A2004CA7E944B3263c9c12E2D1Ea15F2F` |
| **Scope Hash** | `20705775392655063595161714987618253111443058090425597648011351146636338285671` |

## 📁 Project Structure

```
workshop/
├── app/                          # Next.js Frontend
│   ├── app/
│   │   ├── page.tsx             # Landing page
│   │   ├── layout.tsx           # App layout
│   │   ├── globals.css          # Global styles
│   │   ├── verified/            # Post-verification page
│   │   └── verification/[uuid]/ # Verification flow
│   └── package.json
├── contracts/                    # Smart Contracts
│   ├── src/
│   │   ├── cryptoNomads.sol     # Main contract
│   │   └── durin-ens/           # ENS integration
│   ├── script/                  # Deployment scripts
│   ├── foundry.toml             # Foundry config
│   └── package.json
└── README.md
```

## 🛠️ Technology Stack

### Smart Contracts
- **Solidity 0.8.28** - Smart contract development
- **Foundry/Forge** - Development framework and testing
- **Self Protocol** - Zero-knowledge identity verification
- **ENS (Ethereum Name Service)** - Decentralized naming system
- **OpenZeppelin** - Security-audited contract libraries

### Frontend
- **Next.js 14** - React framework with App Router
- **TypeScript** - Type-safe development
- **Tailwind CSS** - Utility-first CSS framework
- **Privy** - Wallet connection and authentication

### Backend & Infrastructure
- **MongoDB Atlas** - User data storage
- **Vercel** - Frontend deployment
- **Celo Network** - Low-cost, carbon-negative blockchain

## ⚙️ Setup & Installation

### Prerequisites
- Node.js 18+
- Foundry
- Git

### 1. Clone the Repository
```bash
git clone <repository-url>
cd workshop
```

### 2. Install Dependencies

**Frontend:**
```bash
cd app
npm install
```

**Contracts:**
```bash
cd contracts
forge install
```

### 3. Environment Configuration

**Frontend (.env.local):**
```env
NEXT_PUBLIC_SELF_ENDPOINT="0x149cbA3EE15C863563a18808814a10815369458E"
NEXT_PUBLIC_SELF_APP_NAME="CryptoNomads Verification"
NEXT_PUBLIC_SELF_SCOPE="crypto-nomads"
NEXT_PUBLIC_CRYPTONOMADS_CONTRACT_ADDRESS="0x149cbA3EE15C863563a18808814a10815369458E"
NEXT_PUBLIC_CHAIN_ID="42220"
MONGO_URI="your-mongodb-connection-string"
```

**Contracts (.env):**
```env
PRIVATE_KEY="your-private-key"
IDENTITY_VERIFICATION_HUB_ADDRESS="0xe57F4773bd9c9d8b6Cd70431117d353298B9f5BF"
NETWORK="celo-mainnet"
SCOPE_SEED="crypto-nomads"
```

### 4. Run the Application

**Frontend:**
```bash
cd app
npm run dev
```

**Local blockchain (optional):**
```bash
cd contracts
anvil
```

## 🚦 Usage Flow

1. **Connect Wallet**: User connects their wallet via Privy
2. **Discord Verification**: User verifies ownership of Discord account
3. **Identity Verification**: Self Protocol verifies user's real-world identity
4. **Smart Contract**: Verification data is stored on-chain with Discord username mapping
5. **ENS Registration**: Automatic subdomain creation (e.g., `username.cryptonomads.eth`)
6. **Completion**: User receives verified status and ENS subdomain

## 🔧 Development Commands

### Smart Contracts
```bash
# Compile contracts
forge build

# Run tests
forge test

# Deploy to Celo Mainnet
forge create src/cryptoNomads.sol:CryptoNomads \
  --broadcast \
  --private-key $PRIVATE_KEY \
  --rpc-url https://forno.celo.org \
  --constructor-args $HUB_ADDRESS $SCOPE $CONFIG $REGISTRY_ADDRESS

# Set scope on deployed contract
cast send $CONTRACT_ADDRESS "setScope(uint256)" $CALCULATED_SCOPE \
  --rpc-url https://forno.celo.org \
  --private-key $PRIVATE_KEY
```

### Frontend
```bash
# Development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

## 🧪 Testing

```bash
# Run smart contract tests
cd contracts
forge test -vvv

# Run frontend tests
cd app
npm test
```


## 🎯 Roadmap

- [ ] Multi-chain deployment (Polygon, Base, Arbitrum)
- [ ] Enhanced ENS profile customization
- [ ] Social verification beyond Discord
- [ ] DAO governance integration

---

**Built with 💜 by the CryptoNomads team**
