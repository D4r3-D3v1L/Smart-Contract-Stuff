// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MultisignatureWallet {
	event Deposit(address indexed sender , uint amount, uint balance);
	event SubmitTransaction(address indexed owner ,uint indexed transactionId, address indexed transactionTo ,uint value,bytes data);
	event ConfirmationTransaction(address indexed owner,uint indexed transactionId);
	event RevokeConfirmation(address indexed owner,uint indexed transactionId);
	event ExecuteTransaction(address indexed owner,uint indexed transactionId);

	address[] owners;

	mapping (address => bool) public isOwner;

	uint public numofConfirmationsRequired;

	struct Transcation {
		address to;
		uint value;
		bytes data;
		bool executed;
		uint numofConfirmations;
	}

	mapping (uint => mapping (address => bool)) public isConfirmed;

	Transcation[] public transactions;

	modifier onlyOwner {
		require(isOwner[msg.sender] , "Only Owner allowed");
		_;
	}

	modifier transactionExists(uint _transactionId) {
		require(_transactionId < transactions.length,"Transaction Not Exist");
		_;		
	}

	modifier notExecuted(uint _transcationId) {
		require(!transactions[_transcationId].executed ,"Transaction already Executed");
		_;
	}

	modifier alreadyConfirmed(uint _transcationid) {
		require(!isConfirmed[_transcationid][msg.sender] ,"Transcation already Confiremd");
		_;
	}

	constructor(address[] memory _owners, uint _numofConfirmationsRequired) {
		require(_owners.length > 0,"Owners Required");

		require(_numofConfirmationsRequired > 0 && _numofConfirmationsRequired <= _owners.length,"Invalid number of required confirmations");
		
		for(uint i =0 ;i < _owners.length ; i++){
			address owner = _owners[i];
			require(owner != address(0) ,"Invalid Owner");
			require(!isOwner[owner],"Already Existed Owner");
			isOwner[owner] = true;
			owners.push(owner);
			numofConfirmationsRequired = _numofConfirmationsRequired;
		}

	}

	receive() external payable {
		emit Deposit(msg.sender, msg.value, address(this).balance);
	}

	function submitTransaction(address _to, uint _value,bytes memory _data) public onlyOwner {
		uint transactionId = transactions.length;

		transactions.push(Transcation({
			to : _to,
			value : _value,
			data : _data,
			executed : false,
			numofConfirmations : 0

		}));

		emit SubmitTransaction(msg.sender, transactionId, _to, _value, _data);
	}

	function confirmationTranscation(uint _txIndex) public onlyOwner transactionExists(_txIndex) alreadyConfirmed(_txIndex) notExecuted(_txIndex) {
		Transcation storage transaction = transactions[_txIndex];
		transaction.numofConfirmations += 1 ;
		isConfirmed[_txIndex][msg.sender] = true;
		emit ConfirmationTransaction(msg.sender, _txIndex);
	}

	function executeTransaction(uint _txIndex) public onlyOwner transactionExists(_txIndex) notExecuted(_txIndex) {
		Transcation storage transaction = transactions[_txIndex];
		require(transaction.numofConfirmations >= numofConfirmationsRequired ,"Don't have enough confirmations to Execute transcation ");
		transaction.executed = true;
		(bool success, ) = transaction.to.call{value : transaction.value}(
			transaction.data
		);

		require(success,"Transacion Failed");

		emit ExecuteTransaction(msg.sender, _txIndex);
	}

	function revokeConfirmation(uint _txIndex) public onlyOwner transactionExists(_txIndex) notExecuted(_txIndex) {
		Transcation storage transaction = transactions[_txIndex];
		require(isConfirmed[_txIndex][msg.sender] , "Transaction Not Confirmed");
		transaction.numofConfirmations -= 1;
		isConfirmed[_txIndex][msg.sender] = false;
		emit RevokeConfirmation(msg.sender, _txIndex);

	}

	function getOwners() public view returns(address[] memory){
		return owners;		
	}

	function getTransactionCount() public view returns(uint){
		return transactions.length;
	}

	function getTransaction(uint _txIndex) public view returns (
		address to,
		uint value,
		bytes memory data ,
		bool executed,
		uint nunOfConfirmations
	){

		require(_txIndex < transactions.length , "Transaction Doesn't exist");
		Transcation storage transaction = transactions[_txIndex];
		to = transaction.to;
		value = transaction.value;
		data = transaction.data;
		executed = transaction.executed;
		nunOfConfirmations = transaction.numofConfirmations;

	}
}
