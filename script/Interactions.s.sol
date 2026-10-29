// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {HelperConfig} from "./HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MyVRFCoordinatorV2_5Mock} from "../test/mock/MyVRFCoordinatorV2_5Mock.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {CodeConstants} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mock/LinkToken.sol";

contract CreateSubscription is Script, CodeConstants {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinatorV2_5 = helperConfig.getConfigByChainId(block.chainid).vrfCoordinatorV2_5;
        address account = helperConfig.getConfigByChainId(block.chainid).account;

        return createSubscription(vrfCoordinatorV2_5, account);
    }

    function createSubscription(address vrfCoordinatorV2_5, address account) public returns (uint256, address) {
        vm.startBroadcast(account);
        uint256 subId;
        if (block.chainid == LOCAL_CHAIN_ID) {
            subId = MyVRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).deterministicCreateSubscription();
        } else {
            subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).createSubscription();
        }
        vm.stopBroadcast();
        return (subId, vrfCoordinatorV2_5);
    }

    function run() public returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address contractToAddToVRF, address vrfCoordinator, uint256 subId, address account) public {
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVRF);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        address account = helperConfig.getConfig().account;

        addConsumer(mostRecentlyDeployed, vrfCoordinatorV2_5, subId, account);
    }

    function run() public {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}

contract FundSubscription is Script, CodeConstants {
    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vRFCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        address account = helperConfig.getConfig().account;
        address link = helperConfig.getConfig().link;

        if (subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (uint256 updatedSubId, address updatedVrf) = createSubscription.run();
            subId = updatedSubId;
            vRFCoordinatorV2_5 = updatedVrf;
        }

        fundSubscription(vRFCoordinatorV2_5, subId, link, account);
    }

    function fundSubscription(address vRFCoordinatorV2_5, uint256 subId, address link, address account) public {
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vRFCoordinatorV2_5).fundSubscription(subId, 100 ether);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(link).transferAndCall(vRFCoordinatorV2_5, 3 ether, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}
