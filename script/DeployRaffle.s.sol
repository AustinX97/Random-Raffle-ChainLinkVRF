// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfigObj = new HelperConfig();
        (
            uint256 _enteranceFee,
            uint256 interval,
            uint256 lastTimeStamp,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address linkAdd
        ) = helperConfigObj.activeNetworkConfig();

        if (subscriptionId == 0) {
            // We need to create a sub ID
            CreateSubscription creatrSubscriptionObj = new CreateSubscription();
            subscriptionId = creatrSubscriptionObj.createSubscription(
                vrfCoordinator
            );
            //Now we have the SubId, we need to fund it as well, that we do in Interactions.s.sol
            FundSubscription fundSubscriptionObj = new FundSubscription();
            fundSubscriptionObj.fundSubscription(
                subscriptionId,
                vrfCoordinator,
                linkAdd
            );
        }

        vm.startBroadcast();
        Raffle raffleObj = new Raffle(
            _enteranceFee,
            interval,
            lastTimeStamp,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumerObj = new AddConsumer();
        addConsumerObj.addConsumer(
            address(raffleObj),
            vrfCoordinator,
            subscriptionId
        );

        return (raffleObj, helperConfigObj);
    }
}
