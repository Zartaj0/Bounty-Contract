// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Earn {
    //State variables
    address public owner;
    uint decimals = 10 ** 18;

    //Mappings
    mapping(address => bool) internal AllowedOrganizer;
    mapping(uint256 => Bounty) public AllBounties;
    mapping(uint256 => uint256) public RemainingPoolPrize;
    mapping(address => uint) public ClaimablePrize;
    mapping(uint => Submission[]) public SubmittedBounties;
    //Structs
    struct Bounty {
        address Organizer;
        string ExternalLink;
        uint256 StartTime;
        uint256 EndTime;
        uint256 index;
        uint256 AmountInPool;
        bool ResultDeclared;
    }

    struct Submission {
        uint BountyIndex;
        address Participant;
        string Soultion;
        uint Id;
    }

    //Array
    uint256[] public IndexArrayForBounty;

    //Modifiers
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

    //Constructor
    constructor() {
        owner = msg.sender;
    }

    //View functions
    function isActive(uint256 _index) internal view returns (bool) {
        return AllBounties[_index].EndTime > block.timestamp;
    }

    //functions basic functions
    function changeOwner(address _owner) external onlyOwner {
        require(_owner != address(0), " Zero Adress");
        owner = _owner;
    }

    function addOrganizer(address _organizer) external onlyOwner {
        AllowedOrganizer[_organizer] = true;
    }

    // Organizers will add bounties using this
    function addBounties(
        uint256 _durationInDays,
        string calldata _externalLink,
        uint256 _amountInPool
    ) external payable onlyOrganizer {
        require(
            msg.value == _amountInPool * decimals,
            "Send valid ether amount"
        );

        uint256 _index = IndexArrayForBounty.length;
        uint durationInseconds = _durationInDays * 1 days;
        IndexArrayForBounty.push(_index);

        RemainingPoolPrize[_index] = msg.value;

        AllBounties[_index].Organizer = msg.sender;
        AllBounties[_index].ExternalLink = _externalLink;
        AllBounties[_index].StartTime = block.timestamp;
        AllBounties[_index].EndTime = block.timestamp + durationInseconds;
        AllBounties[_index].index = _index;
        AllBounties[_index].AmountInPool = _amountInPool * decimals;
        AllBounties[_index].ResultDeclared = false;
    }

    //Participants will submit bounty solutions through this function
    function submitBounties(
        uint _bountyId,
        string calldata _solution
    ) external {
        require(_bountyId < IndexArrayForBounty.length, "Invalid Bounty ID");
        require(isActive(_bountyId), "Bounty deadline reached");
        // isParticipantOfBounty[msg.sender][_bountyId] = true;

        uint _Id = SubmittedBounties[_bountyId].length;

        SubmittedBounties[_bountyId].push(
            Submission({
                BountyIndex: _bountyId,
                Participant: msg.sender,
                Soultion: _solution,
                Id: _Id
            })
        );
    }

    //Organizer will declare winners using this function
    function chooseWinners(
        uint _bountyId,
        uint[] calldata _winners,
        uint[] calldata _prizes
    ) external onlyBountyOrganizer(_bountyId) {
        require(!isActive(_bountyId), "bounty is still running");
        require(_winners.length == _prizes.length, "different array length");
        require(!AllBounties[_bountyId].ResultDeclared,"winners already declared" );

        for (uint i; i < _winners.length; i++) {
            address _winner = SubmittedBounties[_bountyId][_winners[i]]
                .Participant;
            ClaimablePrize[_winner] += _prizes[i] *decimals;
        }
        AllBounties[_bountyId].ResultDeclared = true;

    }

    //Participants will be able to claim their prizes from this function
    function claimPrize() external {
        uint _toSend = ClaimablePrize[msg.sender];

        require(_toSend >= 0, "No prizes to claim");

        (bool result, ) = payable(msg.sender).call{value: _toSend}("");
        require(result, "call failed");
    }
}
