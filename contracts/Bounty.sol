// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Earn {
    address public owner;
    uint decimals = 10 ** 18;

    mapping(address => bool) internal AllowedOrganizer;
    mapping(uint256 => Bounty) public AllBounties;
    mapping(uint256 => uint256) public RemainingPoolPrize;
    mapping(address => uint) public ClaimablePrize;
    mapping(address => mapping(uint => bool)) public isParticipantOfBounty;

    struct Bounty {
        address Organizer;
        string ExternalLink;
        uint256 StartTime;
        uint256 EndTime;
        uint256 index;
        uint256 AmountInPool;
    }

    struct Submission {
        uint BountyIndex;
        address Participant;
        string Soultion;
    }

    uint256[] IndexArrayForBounty;
    Submission[] submissions;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyOrganizer() {
        require(AllowedOrganizer[msg.sender], "Only Organizer");
        _;
    }

    modifier onlyBountyOrganizer(uint _bountyId) {
        address _organizer = AllBounties[_bountyId].Organizer;
        require(
            msg.sender == _organizer,
            "you are not the organizer for this bounty"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function isActive(uint256 _index) internal view returns (bool) {
        return AllBounties[_index].EndTime > block.timestamp;
    }

    function changeOwner(address _owner) external onlyOwner {
        require(_owner != address(0), " Zero Adress");
        owner = _owner;
    }

    function addBounties(
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
        AllBounties[_index].AmountInPool = _amountInPool * decimals;
    }

    function submitBounties(
        uint _bountyId,
        string calldata _solution
    ) external {
        require(_bountyId < IndexArrayForBounty.length, "Invalid Bounty ID");

        isParticipantOfBounty[msg.sender][_bountyId] = true;

        submissions.push(
            Submission({
                BountyIndex: _bountyId,
                Participant: msg.sender,
                Soultion: _solution
            })
        );
    }

    function chooseWinners(
        uint _bountyId,
        address[] calldata _winners,
        uint[] calldata _prizes
    ) external onlyBountyOrganizer(_bountyId) {
        require(!isActive(_bountyId), "bounty is still running ");
        require(_winners.length == _prizes.length, "different array length");

        for (uint i; i < _winners.length; i++) {
            require(
                isParticipantOfBounty[_winners[i]][_bountyId],
                "not a participant"
            );
            ClaimablePrize[_winners[i]] = _prizes[i];
        }
    }
}
