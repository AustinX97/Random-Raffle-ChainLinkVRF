// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

//**
//* @title Raffle Lottery SRC
//* @author Zayn / AustinX97
/* @notice This contract is a simple raffle lottery contract
 * @dev Implements Chainlink VRFv2 for random number generation
 */
contract Raffle is VRFConsumerBaseV2 {
    //custom errors, use ContractName__ErrorName for refrence and debugging
    error Raffle__notEnoughFee();
    error Raffle__WinnerTransferFailed();
    error Raffle__EntryClosed();
    error Raffle__upkeepNotNeeded(
        uint256 balance,
        uint256 numOfPlayers,
        uint256 rafflestate,
        uint256 timePassed
    );

    /** Type Decleration */
    enum RaffleState {
        OPEN, // = 0 Open for Participants
        CALCULATING_WINNER // 1 = Calculating Winner | Closed for Participants
    }

    /** State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_enteranceFee;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_interval; //@dev - Interval for the Lottery in Seconds before drawing a winner
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint256 private s_lastTimeStamp;

    address payable[] private s_participants;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    constructor(
        uint256 _enteranceFee,
        uint256 interval,
        uint256 lastTimeStamp,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_enteranceFee = _enteranceFee;
        i_interval = interval;
        s_lastTimeStamp = lastTimeStamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    /** Events Emit - For Logging and Saving Gas */
    event participantsEnteredRaffle(address indexed Participants);
    event theWinnerIs(address indexed winner);

    function enterRaffle() external payable {
        if (s_raffleState == RaffleState.CALCULATING_WINNER) {
            revert Raffle__EntryClosed();
        }
        // Check if the senders has sent the minimum fee required to enter the raffle
        // Require cost more gas so: require(msg.value >= i+i_enteranceFee, "Not Enough to Participate in Raffle");
        //with custom errors, it is
        if (msg.value < i_enteranceFee) {
            revert Raffle__notEnoughFee();
        }
        s_participants.push(payable(msg.sender));

        // Emit Event - Makes Migration Easier
        // Makes Frontend UI "Indexing" Easier
        emit participantsEnteredRaffle(msg.sender);
    }

    // Chainlink Automatation Functions from Chainlink Docs

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        // Check if these conditions are met
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool raffleIsOpen = RaffleState.OPEN == s_raffleState;
        bool lotteryHasBalance = address(this).balance > 0;
        bool lotteryHasPlayers = s_participants.length > 0;

        upkeepNeeded = (timeHasPassed &&
            raffleIsOpen &&
            lotteryHasBalance &&
            lotteryHasPlayers);

        return (upkeepNeeded, "0x0");
    }

    // 1. Get A Random Number
    // 2. Pick a Winner - Using Random Number
    // 3. Be Automatically Called after a certain time

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__upkeepNotNeeded(
                address(this).balance,
                s_participants.length,
                uint256(s_raffleState),
                block.timestamp - s_lastTimeStamp
            );
        }
        // Require that the time has passed
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert("The time has not passed yet");
        }

        s_raffleState = RaffleState.CALCULATING_WINNER;
        //uint256 requestId =
        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    //CEI Design Model
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // Pick a Winner
        //Checks
        //Effects
        uint256 indexOfWinner = randomWords[0] % s_participants.length;
        address payable winner = s_participants[indexOfWinner];
        s_recentWinner = winner;
        s_participants = new address payable[](0); //Logically, it makes sense to reset it after money is transferred, but for security
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        emit theWinnerIs(winner);

        //Interactions
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__WinnerTransferFailed();
        }
    }

    // Get the enterance fee - for Public to check fee
    function getEnteranceFee() public view returns (uint256) {
        return i_enteranceFee;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getParticipants(
        uint256 indexOfPlayers
    ) public view returns (address) {
        return s_participants[indexOfPlayers];
    }
}
