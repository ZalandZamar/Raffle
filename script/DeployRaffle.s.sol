// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        bool created = false;
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (uint256 subId, address vrfCoordinatorV2_5) =
                createSubscription.createSubscription(config.vrfCoordinatorV2_5, config.account);
            config.subscriptionId = subId;
            config.vrfCoordinatorV2_5 = vrfCoordinatorV2_5;
            helperConfig.setConfig(block.chainid, config);
            created = true;
        }

        if (created || block.chainid == helperConfig.LOCAL_CHAIN_ID()) {
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account
            );
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit,
            config.raffleEntranceFee,
            config.automationUpdateInterval,
            config.vrfCoordinatorV2_5
        );
        vm.stopBroadcast();

        addConsumer.addConsumer(address(raffle), config.vrfCoordinatorV2_5, config.subscriptionId, config.account);

        return (raffle, helperConfig);
    }
}
