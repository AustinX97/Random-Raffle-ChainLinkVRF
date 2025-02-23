// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfigObj = new HelperConfig();
        (,,, address vrfCoordinator,,,,) = helperConfigObj.activeNetworkConfig();

        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64) {
        console.log("Creating subscription ID", block.chainid);

        // Will call createSubscription on VRFCoordinatorV2Mock
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription ID", subId);
        console.log("Update this SubID in HelperConfig.s.sol");
        return subId;
        // SubID:  Created using Chainlink VRFCoordinatorV2Mock contract and using fn "createSubscription"
    }

    function run() external returns (uint64) {
        return CreateSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_LINK_AMOUNT = 5e18;

    function fundsubScriptionUsingConfig() public {
        HelperConfig helperConfigObj = new HelperConfig();
        (,,, address vrfCoordinator,, uint64 subId,, address linkAdd) = helperConfigObj.activeNetworkConfig();
        fundSubscription(subId, vrfCoordinator, linkAdd);
    }

    function fundSubscription(uint64 subId, address vrfCoordinator, address linkAdd) public {
        console.log("Funding Subscription ID", subId);
        // Will call fundSubscription on VRFCoordinatorV2Mock
        console.log("Using VRF Coordinator", vrfCoordinator);
        console.log("Using LINK Token", linkAdd);
        console.log("On ChainID", block.chainid);

        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_LINK_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkAdd).transferAndCall(vrfCoordinator, FUND_LINK_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundsubScriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address raffle, address vrfCoordinator, uint64 subId) public {
        console.log("Adding Consumer to Raffle Contract", raffle);
        console.log("Using VRF Coordinator", vrfCoordinator);
        console.log("Using Subscription ID", subId);
        console.log("On ChainID", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfigObj = new HelperConfig();
        (
            ,
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subId, //address linkAdd "Dont need this| AddConsumer Fn in VRFMock takes only VRF Cordinator and SubID as input" "
            ,
        ) = helperConfigObj.activeNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subId);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Most Rrecent Raffle Contract", block.chainid);
        addConsumerUsingConfig(raffle);
    }
}
