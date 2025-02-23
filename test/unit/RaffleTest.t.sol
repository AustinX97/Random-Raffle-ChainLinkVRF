// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console2} from "forge-std/Test.sol";

contract RaffleTest is Test {
    /* Events */
    event participantsEnteredRaffle(address indexed player);

    Raffle raffleObj;
    HelperConfig helperConfigObj;
    uint256 _enteranceFee;
    uint256 interval;
    uint256 lastTimeStamp;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address linkAdd;

    // Dummy Player with some ETH
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        //Deploy Raffle Contract with these configurations
        DeployRaffle deployer = new DeployRaffle();
        (raffleObj, helperConfigObj) = deployer.run();

        (
            _enteranceFee,
            interval,
            lastTimeStamp,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            linkAdd
        ) = helperConfigObj.activeNetworkConfig();
        //Assign some money to the Player
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleStartInOpenState() public view {
        assert(raffleObj.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRevertFeeNotMet() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__notEnoughFee.selector);
        raffleObj.enterRaffle{value: 0}();
    }

    function testPlayersGetUpdated() public {
        vm.prank(PLAYER);
        raffleObj.enterRaffle{value: _enteranceFee}();
        address playerRecorded = raffleObj.getParticipants(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnPlayerEntry() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffleObj));
        emit participantsEnteredRaffle(PLAYER);
        raffleObj.enterRaffle{value: _enteranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffleObj.enterRaffle{value: _enteranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffleObj.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__EntryClosed.selector);
        vm.prank(PLAYER);
        raffleObj.enterRaffle{value: _enteranceFee}();
    }

    //////////////////////////
    // Check Upkeep Tests   //
    //////////////////////////

    function testCheckUpkeepReturnsFalseOnNotEnoughBalance() public {
        //Arrange
        vm.prank(PLAYER);
        //raffleObj.enterRaffle{value: _enteranceFee}(); We don't want contract to have balance
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upkeepNeeded, ) = raffleObj.checkUpkeep("");

        //Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseOnRaffleClosed() public {
        vm.prank(PLAYER);
        raffleObj.enterRaffle{value: _enteranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffleObj.performUpkeep("");

        //Act
        (bool upkeepNeeded, ) = raffleObj.checkUpkeep("");

        //Assert
        assert(upkeepNeeded == false);
    }
}
