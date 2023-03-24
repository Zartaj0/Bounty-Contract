// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Earn {
    //State variables
    address public owner;

    event BountyCreated(
        address indexed createdBy,
        uint indexed _bountyId,
        uint indexed EndTime,
        uint startTime
    );
    event NewSubmission(
        address indexed SubmittedBy,
        uint indexed SubmitIndex,
        uint indexed SubmitTime
    );
    event WinnersDeclared(
        uint indexed _bountyId,
        uint[] indexed _ids,
        uint[] indexed _amounts
    );
    //Mappings
    mapping(address => bool) internal AllowedOrganizer;
    mapping(address => bool) internal AllowedParticipant;
    mapping(uint256 => Bounty) public AllBounties;
    mapping(uint256 => uint256) public RemainingPoolPrize;
    mapping(address => uint) public ClaimablePrize;
    mapping(uint => Submission[]) public SubmittedBounties;
    mapping(uint => Application) public ApplicationList;

    //Enum
    enum ApplicationType {
        Organizer,
        Participant
    }

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

    struct Application {
        address Applicant;
        string LinkToId;
        ApplicationType ApplyType;
    }

    //Array
    uint256[] public IndexArrayForBounty;
    uint256[] public IndexArrayForApplication;

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyOrganizer() {
        require(AllowedOrganizer[msg.sender], "Only Organizer");
        _;
    }

    modifier onlyParticipant() {
        require(AllowedParticipant[msg.sender], "Only Participant");
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

    function addOrganizer(address _organizer) internal onlyOwner {
        AllowedOrganizer[_organizer] = true;
    }

    function addParticipant(address _organizer) internal onlyOwner {
        AllowedParticipant[_organizer] = true;
    }

    //APply to become an organizer or participant
    function getVerified(ApplicationType _type, string memory _link) external {
        uint _index = IndexArrayForApplication.length;
        IndexArrayForApplication.push(_index);

        ApplicationList[_index].Applicant = msg.sender;
        ApplicationList[_index].ApplyType = _type;
        ApplicationList[_index].LinkToId = _link;
    }

    function approveRequests(uint _id) external onlyOwner {
        require(_id < IndexArrayForApplication.length, "invalid id");
        if (ApplicationList[_id].ApplyType == ApplicationType.Organizer) {
            addOrganizer(ApplicationList[_id].Applicant);
        } else {
            addParticipant(ApplicationList[_id].Applicant);
        }
    }

    // Organizers will add bounties using this
    function addBounties(
        uint256 _durationInDays,
        string calldata _externalLink,
        uint256 _amountInPool
    ) external payable onlyOrganizer {
        require(
            msg.value == _amountInPool * 10 ** 18,
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
        AllBounties[_index].AmountInPool = _amountInPool * 10 ** 18;
        AllBounties[_index].ResultDeclared = false;

        emit BountyCreated(
            msg.sender,
            _index,
            block.timestamp + durationInseconds,
            block.timestamp
        );
    }

    //Participants will submit bounty solutions through this function
    function submitBounties(
        uint _bountyId,
        string calldata _solution
    ) external onlyParticipant {
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

        emit NewSubmission(msg.sender, _Id, block.timestamp);
    }

    //Organizer will declare winners using this function
    function chooseWinners(
        uint _bountyId,
        uint[] calldata _winners,
        uint[] calldata _prizes
    ) external onlyBountyOrganizer(_bountyId) {
        require(!isActive(_bountyId), "bounty is still running");
        require(_winners.length == _prizes.length, "different array length");
        require(
            !AllBounties[_bountyId].ResultDeclared,
            "winners already declared"
        );

        for (uint i; i < _winners.length; i++) {
            address _winner = SubmittedBounties[_bountyId][_winners[i]]
                .Participant;
            ClaimablePrize[_winner] += _prizes[i] * 10 ** 18;
            RemainingPoolPrize[_bountyId] -= _prizes[i] * 10 ** 18;
        }
        AllBounties[_bountyId].ResultDeclared = true;
        emit WinnersDeclared(_bountyId, _winners, _prizes);
    }

    //Participants will be able to claim their prizes from this function
    function claimPrize() external onlyParticipant {
        uint _toSend = ClaimablePrize[msg.sender];

        require(_toSend > 0, "No prizes to claim");
        ClaimablePrize[msg.sender] = 0;
        (bool result, ) = payable(msg.sender).call{value: _toSend}("");
        require(result, "call failed");
    }

    function withdrawRemainingAmount(
        uint _bountyId
    ) external onlyBountyOrganizer(_bountyId) {
        uint _amount = RemainingPoolPrize[_bountyId];
        if (_amount > 0) {
            RemainingPoolPrize[_bountyId] =0;
            (bool success, ) = payable(msg.sender).call{value: _amount}("");
            require(success, "call failed");
        } else{
            revert("No amount to claim");
        }
    }
}
