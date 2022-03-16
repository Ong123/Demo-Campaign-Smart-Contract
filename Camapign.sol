// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

contract CampaignFactory is CloneFactory {
    address public _campaignManager;
    Campaign[] public campaignConducted;
    address public campaignContractAddress;

    event CampaignEvent(address _admin, Campaign _campaign);
    

    constructor(address _campaignContractAddress){
        _campaignManager = msg.sender;
        campaignContractAddress = _campaignContractAddress;
    }

    modifier onlyCampaignManager() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == _campaignManager;
    }
    
   
    function createCampaign(uint _minimum) public onlyCampaignManager {
        Campaign campaign = Campaign(createClone(campaignContractAddress));
        campaign.initialize(_minimum, payable(msg.sender));
        campaignConducted.push(campaign);
    }
    
    function getCampaign() public view returns(Campaign[] memory _campaignConducted) {
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

    function initialize( uint _minimum, address payable _creator) external {
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
