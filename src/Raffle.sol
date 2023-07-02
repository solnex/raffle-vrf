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
//SPDX-Licenses-Identifier: MIT

pragma solidity ^0.8.18;
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/**
 * @title Raffle
 * @dev Implements chainlink VRFv2 to generate random numbers
 */
contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthSent();
    error Raffle__RaffleNotReady();
    error Raffle__PickWinnerNotReady();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );
    error Raffle__TransferFailed();
    // Type declarations
    enum RaffleState {
        OPEN,
        CALCULATING,
        CLOSED
    }

    uint256 private i_raffleFee;
    address payable[] private s_raffleParticipants;
    //@dev interval is the time between each raffle
    uint private immutable i_interval;
    uint256 private s_raffleLastTimestamp;
    VRFCoordinatorV2Interface private s_vrfCoordinator;
    bytes32 private s_keyHash;
    uint64 private immutable i_subId;
    uint16 private constant MINMUM_CONFIRMATIONS = 3;
    uint32 private s_callbackGasLimit;
    uint32 private constant NUM_WORD = 1;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    event RaffleEntered(address indexed participant);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 raffleFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_raffleFee = raffleFee;
        i_interval = interval;
        s_raffleLastTimestamp = block.timestamp;
        s_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        i_subId = subId;

        s_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_raffleFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotReady();
        }
        s_raffleParticipants.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    //Automation
    /**
     * @dev this is the function that chainlink keeper will automationly call
     * we want to check if the raffle is ready to pick a winner
     * 1.check the time
     * 2.check the state is open
     * 3.check the participants is not empty or balance is not zero
     * 4.link balance is enough for the automationly call fee
     * @return upkeepNeeded is true if the upkeep is needed
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isTimeToPickWinner = block.timestamp - s_raffleLastTimestamp >=
            i_interval;
        bool isRaffleOpen = s_raffleState == RaffleState.OPEN;
        bool isParticipantsNotEmpty = s_raffleParticipants.length > 0;
        bool isBalanceEnough = address(this).balance >= 0;
        upkeepNeeded =
            isTimeToPickWinner &&
            isRaffleOpen &&
            isParticipantsNotEmpty &&
            isBalanceEnough;
        return (upkeepNeeded, "0x0");

        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_raffleParticipants.length,
                uint256(s_raffleState)
            );
        }
        pickWinner();
    }

    //1.everyone can call this function(better call from chainlink automatically)
    //2.check if the raffle is time to pick a winner
    //3.get a random number from chainlink
    //4.pick a winner
    function pickWinner() internal {
        //check if the raffle is time to pick a winner
        s_raffleState = RaffleState.CALCULATING;
        //request a random number from chainlink
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            s_keyHash,
            i_subId,
            MINMUM_CONFIRMATIONS,
            s_callbackGasLimit,
            NUM_WORD
        );
        emit RequestedRaffleWinner(requestId);
    }

    //CEI principle: check-effect-interaction
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        //Checks
        if (s_raffleState != RaffleState.CALCULATING) {
            revert Raffle__PickWinnerNotReady();
        }
        //Effect
        //pick a winner
        uint256 winnnerIndex = randomWords[0] % s_raffleParticipants.length;
        address payable winner = s_raffleParticipants[winnnerIndex];
        //reset the raffle
        s_raffleParticipants = new address payable[](0);
        s_raffleLastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        s_recentWinner = winner;
        emit WinnerPicked(winner);
        //Interactions
        (bool success, ) = winner.call{value: address(this).balance}("");
        // require(success, "Transfer failed");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**Getter Function  */
    function getRaffleFee() external view returns (uint256) {
        return i_raffleFee;
    }

    function getRaffleParticipants()
        external
        view
        returns (address payable[] memory)
    {
        return s_raffleParticipants;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getRaffleLastTimestamp() external view returns (uint256) {
        return s_raffleLastTimestamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
