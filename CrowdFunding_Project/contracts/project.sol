// SPDX-License-Identifier: GPL-3.0

/* Agenda: 
        A manager is asking for funds to different companies for crowdfunding from which his company will donate or invest 
        that money for different purpose. So, the companies who are going to give the amount that is in wei and that is 
        first send to a smart contract and if manager wants to transfer wei from the contract then he needs to ask 
        permission from majority of investors. In the Deadline of 10 days, if we didn't reached the target of wei then
        after 10 days, investors can be able to remove their own wei.
*/


pragma solidity >= 0.5.0 < 0.9.0;


contract CrowdFunding
{
    mapping (address => uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    constructor (uint _target, uint _deadline)
    {
        target = _target;
        deadline = block.timestamp + _deadline;     // 10 sec + 3600 sec means (1 hr)
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    function sendEth() public payable
    {
        require(block.timestamp < deadline, "Deadline has passed");
        require(minimumContribution <= msg.value, "Minimum contribution is not met");

        if(contributors[msg.sender] == 0)
        {
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        
    }

    function getContractBalance() public view returns(uint)
    {
        return address(this).balance;
    }

    function refund() public
    {
        require(block.timestamp > deadline && raisedAmount < target, "You are not eligible for refund");
        require(contributors[msg.sender] > 0);

        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    struct Request
    {
        string description;
        address payable recipient;
        uint value;
        bool votingResult;      
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public request;
    uint public numRequests;

    modifier onlyManager()
    {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager
    {
        Request storage newRequest = request[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;

        newRequest.votingResult = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public
    {
        require(contributors[msg.sender] > 0, "You should be a contributor");
        Request storage thisRequest = request[_requestNo];

        require(thisRequest.voters[msg.sender] == false, "You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }


    function makePayment(uint _requestNo) public onlyManager
    {
        require(raisedAmount >= target);
        Request storage thisRequest = request[_requestNo];
        require(thisRequest.votingResult == false, "The request has beein completed");
        require(thisRequest.noOfVoters > noOfContributors/2, "Majority is not there for transaction");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.votingResult = true;
    }


}

