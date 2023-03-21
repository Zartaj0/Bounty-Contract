
const { expect } = require("chai");

describe("Lock", function () {

  let bounty;
  let owner;
  let bob;
  let organizer1;
  let organizer2;
  let participant1;
  let participant2;
  beforeEach(async function () {
    [owner, bob, organizer1, organizer2, participant1, participant2] = await ethers.getSigners();

    const Bounty = await ethers.getContractFactory("Earn");
    bounty = await Bounty.deploy();
  })

  describe("Deployment", () => {

    it("should assign the owner", async () => {
      expect(await bounty.owner()).to.be.equal(owner.address);
    })

    it("only owner can whitelist organizer", async () => {
      expect(bounty.addOrganizer(organizer1.address)).to.be.fulfilled;
      expect(bounty.connect(bob).addOrganizer(organizer1.address)).to.be.reverted;
    })

  })
  describe("Organizer & participants privilleges ", () => {
    beforeEach(async () => {
      await bounty.addOrganizer(organizer1.address);
      await bounty.addOrganizer(organizer2.address);
    })
    it("only organizer Can add bounty", async () => {
      await expect(bounty.connect(organizer1).addBounties(3, "link", 5, { value: ethers.utils.parseEther("5") })).to.be.fulfilled;
      await expect(bounty.connect(bob).addBounties(3, "link", 5, { value: ethers.utils.parseEther("5", "ether") })).to.be.revertedWith("Only Organizer");
      // console.log(await bounty.AllBounties(0)); 
    })

    it("participants can submit bounty", async () => {
      await expect(bounty.connect(organizer1).addBounties(3, "linkBounty", 5, { value: ethers.utils.parseEther("5") })).to.be.fulfilled;
      await expect(bounty.connect(participant1).submitBounties(0, "LinkSol")).to.be.fulfilled;
      await expect(bounty.connect(participant2).submitBounties(0, "Link2sol")).to.be.fulfilled;
      await expect(bounty.connect(bob).submitBounties(0, "Link3SOl")).to.be.fulfilled;
      await expect(bounty.connect(participant1).submitBounties(0, "Link4Sol")).to.be.fulfilled;
      // console.log(await bounty.SubmittedBounties(0, 0));

    })

    describe("Choosing Winners", async () => {
      beforeEach(async () => {
        await bounty.connect(organizer1).addBounties(3, "link2Bounty", 5, { value: ethers.utils.parseEther("5") })
        await bounty.connect(organizer2).addBounties(19, "link2Bounty", 5, { value: ethers.utils.parseEther("5") })
        await bounty.connect(participant1).submitBounties(1, "LinkSol")
        await bounty.connect(participant2).submitBounties(0, "Link2Sol")
        await bounty.connect(bob).submitBounties(1, "Link3SSOl")
        await bounty.connect(participant1).submitBounties(0, "Link4Sol")
        console.log(await bounty.SubmittedBounties(0,1));
      })

      it("respective organizers can only choose winners", async ()=>{
        // await expect(bounty.connect(organizer1).chooseWinner(0,[""]))
      })

    })

  })

});
