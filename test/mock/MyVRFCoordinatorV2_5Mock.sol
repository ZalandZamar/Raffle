// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {
    EnumerableSet
} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";

contract MyVRFCoordinatorV2_5Mock is VRFCoordinatorV2_5Mock {
    using EnumerableSet for EnumerableSet.UintSet;

    constructor(uint96 _baseFee, uint96 _gasPrice, int256 _weiPerUnitLink)
        VRFCoordinatorV2_5Mock(_baseFee, _gasPrice, _weiPerUnitLink)
    {}

    function deterministicCreateSubscription() external nonReentrant returns (uint256 subId) {
        uint64 currentSubNonce = s_currentSubNonce;
        subId = uint256(keccak256(abi.encodePacked(msg.sender, currentSubNonce)));
        s_currentSubNonce = currentSubNonce + 1;

        address[] memory consumers = new address[](0);
        s_subscriptions[subId] = Subscription({balance: 0, nativeBalance: 0, reqCount: 0});
        s_subscriptionConfigs[subId] =
            SubscriptionConfig({owner: msg.sender, requestedOwner: address(0), consumers: consumers});
        s_subIds.add(subId);

        emit SubscriptionCreated(subId, msg.sender);
        return subId;
    }
}
