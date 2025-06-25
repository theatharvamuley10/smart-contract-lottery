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
pragma solidity 0.8.30;

/* imports */
import {VRFConsumerBaseV2Plus} from "@chainlink-brownie-contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink-brownie-contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Lottery
 * @author Atharva Muley
 * @notice This is a simple smart contract for a lottery system
 * @dev Implements Chainlink VRFv2.5
 */

contract Lottery is VRFConsumerBaseV2Plus {
    // there are two main functions required for the lottery
    // 1. People should be able to enter
    // 2. A function that picks a winner

    /* Custom Errors */
    error Lottery__SendMoreToEnterLottery();
    error Lottery__MoneyTransferToWinnerFailed();
    error Lottery__NotOpenYet();
    error Lottery_UpkeepNotNeeded(uint256, uint256, LotteryState);

    /* Type Declarations */
    enum LotteryState {
        OPEN,
        CALCULATING_WINNER
    }

    /* State Variable */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address payable private s_recentWinner;
    LotteryState private s_lotteryState;

    /* Events */
    event LotteryEntered(address indexed player);
    event RecentWinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    /*  Functions */

    function enterLottery() external payable {
        if (s_lotteryState == LotteryState.CALCULATING_WINNER) {
            revert Lottery__NotOpenYet();
        }

        if (msg.value < i_entranceFee) {
            revert Lottery__SendMoreToEnterLottery();
        }
        s_players.push(payable(msg.sender));
        emit LotteryEntered(msg.sender);
    }

    //. 4 conditions should be met to actually pick the winner and those 4 conditions we are going to check in check upkeep
    // 1. Enough time has passed
    // 2. Contract has balance
    // 3. There are players to pick a winner from
    // 4. Lottery State is Open
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = block.timestamp - s_lastTimeStamp >= i_interval;
        bool contractHasBalance = address(this).balance > 0;
        bool thereArePlayers = s_players.length > 0;
        bool lotteryIsOpen = s_lotteryState == LotteryState.OPEN;
        upkeepNeeded = (timeHasPassed &&
            contractHasBalance &&
            thereArePlayers &&
            lotteryIsOpen);
        return (upkeepNeeded, "");
    }

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Be automatically called
    function pickWinner() external {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Lottery_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                s_lotteryState
            );
        }

        s_lotteryState = LotteryState.CALCULATING_WINNER;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash, // gas price were willing to pay
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit, // gas limit we're willing to use
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal virtual override {
        address payable[] memory players = s_players;
        uint256 winnerIndex = randomWords[0] % players.length;
        s_recentWinner = players[winnerIndex];
        s_lotteryState = LotteryState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit RecentWinnerPicked(s_recentWinner);
        (bool success, ) = s_recentWinner.call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert Lottery__MoneyTransferToWinnerFailed();
        }
    }

    /* Getter Functions */

    function getEntraceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
