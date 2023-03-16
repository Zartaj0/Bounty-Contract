// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Earn {
    address owner;

    mapping(address => bool) internal AllowedOrganizer;
    mapping(uint256 => Bounty) public AllBounties;
    mapping(uint256 => uint256) public RemainingPoolPrize;
    mapping(address => uint) public ClaimablePrize;

    struct Bounty {
        address Organizer;
        string ExternalLink;
        uint256 StartTime;
        uint256 EndTime;
        uint256 index;
        uint256 AmountInPool;
    }

    struct Submission{
        address Participant;
        string Soultion;
    }
    
    uint256[] IndexArrayForBounty;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyOrganizer() {
        require(AllowedOrganizer[msg.sender], "Only Organizer");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function isActive(uint256 _index) external view returns (bool) {
        return AllBounties[_index].EndTime > block.timestamp;
    }

    function changeOwner(address _owner) external onlyOwner {
        require(_owner != address(0), " Zero Adress");
        owner = _owner;
    }

    function addBountiesEXperiment(
        uint256 _duration,
        string calldata _externalLink,
        uint256 _amountInPool
    ) external payable onlyOrganizer {
        require(msg.value == _amountInPool, "Send valid ether amount");

        uint256 _index = IndexArrayForBounty.length;
        IndexArrayForBounty.push(_index);

        RemainingPoolPrize[_index] = msg.value;

        AllBounties[_index].Organizer = msg.sender;
        AllBounties[_index].ExternalLink = _externalLink;
        AllBounties[_index].StartTime = block.timestamp;
        AllBounties[_index].EndTime = block.timestamp + _duration;
        AllBounties[_index].index = _index;
        AllBounties[_index].AmountInPool = _amountInPool;
    } //160344


    function submitBounties(uint _bountyId, string calldata _solution) external {
       require(_bountyId < IndexArrayForBounty.length,"Invalid Bounty ID");


    }
}
