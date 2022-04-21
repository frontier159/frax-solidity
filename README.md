# Frax Finance – Solidity Implementation

<p align="center">
  <img width="200" height="200" src="https://i.ibb.co/9HHVcGV/frax-logo.png">
</p>

<p align="center">

🖥 **Website** – https://frax.finance

📖 **Documentation** – https://docs.frax.finance

📲 **Telegram** – https://t.me/fraxfinance
</p>

## What is Frax?
Frax is the first fractional-algorithmic stablecoin protocol. Frax is open-source, permissionless, and entirely on-chain – currently implemented on Ethereum (with possible cross chain implementations in the future). The end goal of the Frax protocol is to provide a highly scalable, decentralized, algorithmic money in place of fixed-supply digital assets like BTC. 

<b> Frax is a new paradigm in stablecoin design. It brings together familiar concepts into a never before seen protocol: </b>
  
  * <b>Fractional-Algorithmic</b> – Frax is the first and only stablecoin with parts of its supply backed by collateral and parts of the supply algorithmic. The ratio of collateralized and algorithmic depends on the market's pricing of the FRAX stablecoin. If FRAX is trading at above $1, the protocol decreases the collateral ratio. If FRAX is trading at under $1, the protocol increases the collateral ratio. 

  * <b>Decentralized & Governance-minimized</b> – Community governed and emphasizing a highly autonomous, algorithmic approach with no active management.  

  * <b>Fully on-chain oracles</b> – Frax v1 uses Uniswap (ETH, USDT, USDC time-weighted average prices) and Chainlink (USD price) oracles. 

  * <b>Two Tokens</b> – FRAX is the stablecoin targeting a tight band around $1/coin. Frax Shares (FXS) is the governance token which accrues fees, seigniorage revenue, and excess collateral value.

  * <b>Swap-based Monetary Policy</b> – Frax uses principles from automated market makers like Uniswap to create swap-based price discovery and real-time stabilization incentives through arbitrage.
  

## Running tests
cd ./src/hardhat
npx hardhat test ./test/FraxSwap/fraxswap-twamm-test.js

## Frontier Updates

The existing readme doesn't give many clues about setup, and the tests didn't work for me out of the box.

I upgraded such that it:

* Uses typescript
* Uses yarn

```bash
nvm use
# NB: "@poanet/solidity-flattener": "^3.0.7"  only works with node v16 
# which wasn't picked up in npm...so --ignore-engines
yarn install --ignore-engines

# Generate typechain/typescript
cd src/hardhat
npx hardhat --tsconfig ../../tsconfig.json typechain
cd ..
yarn tsc

# Setup the dotenv
cp SAMPLE.env .env
# Update .env so INFURA_PROJECT_ID equals your project key. You can signup for free (rate limited).

# Also not ideal that the ./src/hardhat/hardhat.config.ts isn't in the root directory...can't use 'yarn hardhat'
# doesn't look like it can be configured?

# Crank up a forked mainnet
cd src/hardhat
npx hardhat --tsconfig ../../tsconfig.json node --fork https://mainnet.infura.io/v3/<INFURA_PROJECT_ID>

# In a separate terminal
cd src/hardhat
npx hardhat --tsconfig ../../tsconfig.json run scripts/unifiedFarm.ts --network localhost
```
