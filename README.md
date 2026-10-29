# Raffle

A Solidity smart contract project built with Foundry. Users can enter a decentralized raffle by paying an ETH entrance fee. Chainlink VRF v2.5 provides verifiable randomness to select a winner, who receives the ETH accumulated in the contract. The raffle uses upkeep functions to determine when a draw can occur.

## Prerequisites

- [Git](https://git-scm.com/)
- [Foundry](https://getfoundry.sh/)
- An RPC URL for Sepolia if deploying or testing against Sepolia.
- A funded wallet if deploying to Sepolia.
- A configured and funded Chainlink VRF subscription for Sepolia deployments.

## Quick Start

Clone the repository and install dependencies:

```bash
git clone https://github.com/ZalandZamar/Raffle.git
cd Raffle
forge install
```

Configure your environment variables in a `.env` file if required by your deployment scripts or Makefile.

**Security:** Never commit `.env` or expose your private keys. Ensure `.env` is listed in `.gitignore`. Use only local Anvil accounts for local development.

## Deployment

### Deploy locally to Anvil

Start a local Anvil node in a separate terminal:

```bash
anvil
```

Then deploy the contract:

```bash
make deploy-anvil
```

Ensure the local VRF coordinator mock, subscription, funding, and consumer registration are configured correctly by the deployment scripts.

### Deploy to Sepolia

Configure `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as required by your deployment scripts, then run the appropriate deployment command.

If your Makefile defines a Sepolia deployment target, use that target. Otherwise, run:

```bash
forge script script/DeployRaffle.s.sol:DeployRaffle \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --broadcast \
    --private-key "$PRIVATE_KEY"
```

Ensure your deployment wallet has enough Sepolia ETH for gas fees and that your Chainlink VRF subscription is properly funded and configured.

## Interacting with the Contract

After deployment, use the deployed contract address to interact with the raffle.

### Enter the raffle

Call `enterRaffle()` and send at least the configured entrance fee in ETH.

### Check upkeep

Call `checkUpkeep(bytes)` to determine whether the raffle meets the conditions for a draw.

### Perform upkeep

Call `performUpkeep(bytes)` when upkeep is needed to request random words from Chainlink VRF.

The raffle must be configured with a valid VRF subscription and authorized consumer address. Automated draws require separate Chainlink Automation registration and configuration.

## Testing

Run the test suite locally:

```bash
forge test
```

Run tests with detailed execution traces:

```bash
forge test -vvv
```

Run a specific test:

```bash
forge test --match-test testEmitsEventOnEntrance -vvv
```

Build the project:

```bash
forge build
```

Check test coverage:

```bash
forge coverage
```

## Built With

- Solidity
- Foundry
- Chainlink VRF v2.5
- Chainlink Automation-compatible interface
- Anvil

## Disclaimer

This project is for learning and educational purposes. Smart contracts can contain vulnerabilities, and randomness, upkeep, and payout mechanisms require careful testing. Review and test the contracts thoroughly before using them with real funds.
