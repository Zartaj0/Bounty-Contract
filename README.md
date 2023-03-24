# Bounty Platform Contract

### This contract is being developed to handle organization of bounties in a automaed manner.
### where an authorized organizer will be starting any bounty and also staking the prize amount in the contract 

This works in the following way.
A user needs to apply to get verified as either an organzier or a participant, using the getVerified function and passing there link to identity. Only the owner can approve them.

After getting approved the Organizers get access to functions for adding a bounty, choosing winners for that particular bounty, and get the reamaining prizes back, if any.
 The participants gets access to functions, submitBounty, and claimPrizes. 
The clamable prizes are stored in a mapping, and the participant can claim them whenever they want. Even if they want to claim the prize for 10 bounties in one transaction.

In order to choose winners the chhoseWinner function accepts the parameters, bountyId, an array of winning Ids, an array of winning prizes in respect to the Ids array. (This can be simplified via frontend)
 
