-include .env

RPC_URL ?= http://127.0.0.1:8545
RAFFLE ?= 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
VRF ?= 0x5FbDB2315678afecb367f032d93F642f64180aa3
ENTRANCE_FEE ?= 0.01ether
REQUEST_ID ?= 1

# anvil's well-known test keys (accounts #0, #1, #2), never use them on a real network
PLAYER1_KEY ?= 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
PLAYER2_KEY ?= 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
PLAYER3_KEY ?= 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

.PHONY: enter-raffle enter-raffle-2 enter-raffle-3 advance-time perform-upkeep fulfill play-round

deploy:
	forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --broadcast --account <your-account>

deploy-anvil:
	forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url http://127.0.0.1:8545 --broadcast --private-key $(ANVIL_PRIVATE_KEY)

enter-raffle:
	cast send $(RAFFLE) "enterRaffle()" --value $(ENTRANCE_FEE) --private-key $(PLAYER1_KEY) --rpc-url $(RPC_URL)

enter-raffle-2:
	cast send $(RAFFLE) "enterRaffle()" --value $(ENTRANCE_FEE) --private-key $(PLAYER2_KEY) --rpc-url $(RPC_URL)

enter-raffle-3:
	cast send $(RAFFLE) "enterRaffle()" --value $(ENTRANCE_FEE) --private-key $(PLAYER3_KEY) --rpc-url $(RPC_URL)

# interval is 30s, so jump 31s ahead and mine a block
advance-time:
	cast rpc evm_increaseTime 31 --rpc-url $(RPC_URL)
	cast rpc evm_mine --rpc-url $(RPC_URL)

perform-upkeep:
	cast send $(RAFFLE) "performUpkeep(bytes)" 0x --private-key $(PLAYER1_KEY) --rpc-url $(RPC_URL)

# the mock plays the role of the Chainlink VRF node
fulfill:
	cast send $(VRF) "fulfillRandomWords(uint256,address)" $(REQUEST_ID) $(RAFFLE) --private-key $(PLAYER1_KEY) --rpc-url $(RPC_URL)

# full round with 3 players
play-round: enter-raffle enter-raffle-2 enter-raffle-3 advance-time perform-upkeep fulfill

winner:
	cast call $(RAFFLE) "getRecentWinner()(address)" --rpc-url $(RPC_URL)