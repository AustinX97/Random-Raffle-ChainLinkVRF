// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        // paste the values from your Raffle Constructor here
        uint256 _enteranceFee;
        uint256 interval;
        uint256 lastTimeStamp;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address linkAdd;
    }
    //  Cusntructor to check the ChainID and set the NetworkConfig by calling the respective function

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // To Deploy on Sepolia, create FN that returns NetworkConfig Object
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            _enteranceFee: 0.1 ether,
            interval: 30,
            lastTimeStamp: 0,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 1893, // Will Update this!
            callbackGasLimit: 50000, // 50,000 Gas Limit
            linkAdd: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    // To Deploy on Anvil | Localchain: Create FN that returns NetworkConfig Object
    // Will not be a view/pure Fn bec we're sending a transaction to initiate a Mock Contract
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // IF to check if Mock VRF Exist, so we dont create new everytime
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        //if we don't have one, let's create one! | Or USE VRF MOCK from Chainlink, and deploy that

        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCordinatorMock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
        LinkToken linkAdd = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            _enteranceFee: 0.1 ether,
            interval: 30,
            lastTimeStamp: 0,
            vrfCoordinator: address(vrfCordinatorMock),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0, // Will Update this!
            callbackGasLimit: 50000, // 50,000 Gas Limit
            linkAdd: address(linkAdd)
        });
    }
}
