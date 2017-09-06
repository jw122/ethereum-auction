pragma solidity ^0.4.7;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "github.com/Arachnid/solidity-stringutils/strings.sol";

/* This is a second price sealded-bid auction that uses the commit-reveal method. */

contract CommitRevealAuction is usingOraclize {

	using strings for *;

	address public auctioneer; // The address of the auctioneer
	address public leadingBidder; // The address of the bidder with the highest bid
	uint public leadingBid; // The value of the current highest bid
	string public item; // The item being auctioned
	string public startingPrice; // The starting price for the auctioned item
	uint public commitPhaseEndTime; // The time at which the commit phase will end

	bytes32[] public bidCommits; // Array of all the bids committed
	mapping(bytes32 => string) bidStatuses; // Status of each bid: either 'committed' or 'revealed'

	event logString(string); // Event for logging a 'print statement'
	event newBidCommit(string, bytes32) // Event for logging a new bid commit
	event winningBid(string) // Event for printing the auction-winning bid

	/* The constructor for the auction: takes in the commit phase length, name of the item being auctioned,
	as well as the starting price. */
	function CommitRevealAuction(uint _commitPhaseLengthInSeconds, string _item, uint _price){

		// If the commit phase length is too short, throw an error
		if (_commitPhaseLengthInSeconds < 20) {
			throw;
		}

		// The commit phase end time is equivalent to now + the phase length
		commitPhaseEndTime = now + _commitPhaseLengthInSeconds * 1 seconds;
		item = _item; 
		leadingBid = _price; // Current leading bid will be the starting price itself
		startingPrice = _price; // The starting price as given in the constructor
	}

}