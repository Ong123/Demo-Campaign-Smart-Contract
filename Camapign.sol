// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CampaignFactory {
    address public _campaignManager;
    Campaign[] public campaignConducted;

    event CampaignEvent(address _admin, Campaign _campaign);
    

    constructor(){
        _campaignManager = msg.sender;
    }

    modifier onlyCampaignManager() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == _campaignManager;
    }
    
    function createCampaign (uint _minimum) public onlyCampaignManager {
        Campaign campaign = new Campaign(_minimum ,payable(msg.sender));
        campaignConducted.push(campaign);
        emit CampaignEvent(msg.sender,campaign);
    }
    
    function getElections() public view returns(Campaign[] memory _campaignConducted) {
        return campaignConducted;
    }    

}

contract Campaign {

    event ContributeEvent (address contributor);
    event CreateCampaignEvent(uint value, address _recipient);
    event ApproveReuestEvent(address approver, uint _index);
    event FinalizeReuestEvent(address _approver);

    address public manager;
    uint public minimumContribution;

    struct Request {
        uint id;
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }
    

    uint public countRequest;
    mapping(uint => bool) public requestExist;
    mapping(uint => Request) public requestData;

    uint public approversCount;
    mapping(address => bool) public approvers;
    mapping(address => uint) public contributeAmount;
    

    modifier restricted() {
        require(manager == manager);
        _;
    }

    constructor(uint _minimum, address payable _creator) public {
        manager = _creator;
        minimumContribution = _minimum;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);
        approvers[msg.sender] = true;
        approversCount++;
        emit ContributeEvent(msg.sender);
    }
    

    function createRequest(string memory _description, uint _value, address payable _recipient) public restricted {
        countRequest = countRequest + 1;
        require(!requestExist[countRequest],"Request id Already Exist!!!");
        requestExist[countRequest] = true;
        requestData[countRequest].id = countRequest;
        requestData[countRequest].description = _description;
        requestData[countRequest].value = _value;
        requestData[countRequest].recipient = _recipient;
        emit CreateCampaignEvent(_value,_recipient);
    }

    function approveRequest(uint _index) public {
        require(approvers[msg.sender]);
        require(!requestData[_index].approvals[msg.sender]);
        requestData[_index].approvals[msg.sender] = true;
        uint count = requestData[_index].approvalCount;
        requestData[_index].approvalCount = count + 1;
        emit ApproveReuestEvent(msg.sender, _index);
    }

    function finalizeRequest(uint _index) public restricted {
        require(requestData[_index].approvalCount > (approversCount/ 2));
        require(!requestData[_index].complete);
        uint amount = requestData[_index].value;
        requestData[_index].recipient.transfer(amount);
        requestData[_index].complete = true;
        requestData[_index].approvalCount = 0;
        emit FinalizeReuestEvent(msg.sender);
    }
    
    function getSummary() public view returns (
      uint, uint, uint, uint, address
      ) {
        return (
          minimumContribution,
          address(this).balance,
          countRequest,
          approversCount,
          manager
        );
    }
    
    function getRequestsCount() public view returns (uint) {
        return countRequest;
    }
}
