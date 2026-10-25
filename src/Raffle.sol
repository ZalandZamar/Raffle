// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {
    AutomationCompatibleInterface
} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__RaffleNotOpen();
    error Raffle__UpKeedNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
    error Raffle__TransferFailed();

    event RaffleEnter(address indexed player);
    event RaffleWinner(uint256 indexed raffleWinner);
    event WinnerPicked(address indexed recentWinner);

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    address payable[] private s_players;

    constructor(
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit,
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public {
        if (address(msg.sender).balance < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        if (s_raffleState == RaffleState.CALCULATING) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        emit RaffleEnter(msg.sender);
    }

    // ...existing code...
    function checkUpkeep(bytes calldata)
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /**
                          * performData
                          */
        )
    {
        bool isRaffleOpen = s_raffleState == RaffleState.OPEN;
        bool enoughTimeHasPassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isRaffleOpen && enoughTimeHasPassed && hasPlayers && hasBalance);

        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata performData) public override {
        (bool upKeepNeeded,) = checkUpkeep(performData);

        if (!upKeepNeeded) {
            revert Raffle__UpKeedNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        emit RaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256,
        /**
         * requestId
         */
        uint256[] calldata randomWords
    )
        internal
        virtual
        override
    {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        delete s_players;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);
        (bool success,) = recentWinner.call{value: address(this).balance}("");

        if (!success) {
            revert Raffle__TransferFailed();
        }
    }
}
