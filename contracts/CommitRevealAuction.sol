pragma solidity ^0.4.7;

import "../ethereum-api/oraclizeAPI.sol";
import "../solidity-stringutils/strings.sol";

/* This is a second price sealded-bid auction that uses the commit-reveal method. */

contract CommitRevealAuction is usingOraclize {

	using strings for *;

	address public auctioneer; // The address of the auctioneer
	address public leadingBidder; // The address of the bidder with the highest bid
	uint public leadingBid; // The value of the current highest bid
	uint public secondHighest; // The second highest bid (what the winner will pay)
	address public winner; // Address of the bidder with the highest bid
	string public item; // The item being auctioned
	uint public startingPrice; // The starting price for the auctioned item
	uint public commitPhaseEndTime; // The time at which the commit phase will end

	bytes32[] public bidCommits; // Array of all the bids committed
	mapping(bytes32 => string) bidStatuses; // Status of each bid: either 'committed' or 'revealed'

	event logString(string log); // Event for logging a 'print statement'
	event winnerUpdated(string update); // Event for when a new winner is found
	event newBidCommit(string bid, bytes32 commit); // Event for logging a new bid commit
	event winningBid(string bid); // Event for printing the auction-winning bid

	/* The constructor for the auction: takes in the commit phase length, name of the item being auctioned,
	as well as the starting price. */
	function CommitRevealAuction(uint _commitPhaseLengthInSeconds, string _item, uint _price) {

		// If the commit phase length is too short, throw an error
		if (_commitPhaseLengthInSeconds < 20) {
			throw;
		}

		// The commit phase end time is equivalent to now + the phase length
		commitPhaseEndTime = now + _commitPhaseLengthInSeconds * 1 seconds;
		item = _item; 
		leadingBid = _price; // Current leading bid will be the starting price itself
		startingPrice = _price; // The starting price as given in the constructor
		auctioneer = msg.sender;
	}

	/* This function is called when a bid is to be committed. The input is the hash of the bid. */
	function commitBid (bytes32 _bidCommit) {

		// Only commit during the commit phase
		if (now > commitPhaseEndTime) {
			throw;
		}

		// Check if the commit has been used before. 'bytes' is a dynamically-sized byte array.
		// 'memory' means the bytesBidCommit is stored in memory
		// We're casting the value of bidStatuses[_bidCommit] into a byte array to check if the commit has been used before
		// (probably because there's no direct way to check if there's a value mapped to this commit)
		bytes memory bytesBidCommit =  bytes(bidStatuses[_bidCommit]);
		if (bytesBidCommit.length != 0) {
			throw;
		}

		// Add this commit to the bidCommits array, update bidStatuses and log the event
		bidCommits.push(_bidCommit);
		bidStatuses[_bidCommit] = "Committed";
		newBidCommit("Bid committed with the following hash: ", _bidCommit);

	}

	function revealBid(string _bid, bytes32 _bidCommit) payable{
		// Only reveal after the commit phase is over
		if (now < commitPhaseEndTime) {
			throw;
		}

		// Index into _bidCommit in the bidStatuses mapping
		bytes memory bytesBidStatus = bytes(bidStatuses[_bidCommit]);
		// If there's no value mapped to this commit, then bid was not committed 
		if (bytesBidStatus.length == 0){
			logString("A bid with this commit was not cast.");
		}
		// If the bid was already committed
		else if (bytesBidStatus[0] != "C"){
			logString("This bid was already cast");
			return;
		}

		// Verify that the commit is the equivalent of the hash of original bid
		if (_bidCommit != keccak256(_bid)) {
			logString("Bid hash does not match bid commit.");
			return;
		}

		// Obtain the bid value by slicing the bid on the '-' character
		var bidString = _bid.toSlice();
		var bidValue = bidString.split('-'.toSlice());

		// When logging the bidValue, need to convert it into string from struct using toString()
		logString(bidValue.toString());

		// Cast the bid from string to integer, so that we can compare it with other values
		var bidInt = parseInt(bidValue.toString()); 

		// Cannot have a bid that's lower than or equal to starting price
		if (bidInt <= startingPrice){
			logString("Bid must be higher than starting price.");
			return;
		}

		// If the bid is higher than the current leading bid, update the leading bid.
		if (bidInt > leadingBid){

			// Do not refund if current bid is first price above starting price
			// In other words, if starting price was 100 and first bidder bids 120, do not refund anything.
			// Only refund first bidder if someone bids higher than their bid
			if (leadingBid != startingPrice) {
				// refund the previous winner before updating the winner and leadingBid
				winner.send(leadingBid);
			}
			// store the second highest bid 
			secondHighest = leadingBid;
			leadingBid = bidInt;
			winner = msg.sender;

			// logString("Leading bid updated.");
			winnerUpdated("Winner updated");
		}

		// if bid isn't higher than the leadingBid but higher than second, then replace second but don't take the "deposit"
		else if (bidInt < leadingBid && bidInt > secondHighest) {
			secondHighest = bidInt;
			msg.sender.send(msg.value);
		}

		logString("Bid counted.");
		bidStatuses[_bidCommit] = "Revealed"; 
	}

	/* Retrieves the winner of the auction */
	function getWinner() constant returns(address) {
		// Only get winner after the commit phase has ended
		if (now < commitPhaseEndTime) {
			throw;
		}

		return winner;

	}

	function getWinningBid() constant returns(uint) {
		if(now < commitPhaseEndTime) {
			throw;
		}

		return leadingBid;
	}

	function endAuction() {
		var difference = leadingBid - secondHighest;
		winner.send(difference);
	}
}