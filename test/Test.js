
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
  describe("Organizer privilleges", () => {
    beforeEach(async () => {
      await bounty.addOrganizer(organizer1.address);
    })
    it("only organizer Can add bounty", async () => {
      expect(await bounty.owner()).to.be.equal(owner.address);
    })

    it("only owner can whitelist organizer", async () => {
      expect(bounty.addOrganizer(organizer1.address)).to.be.fulfilled;
      expect(bounty.connect(bob).addOrganizer(organizer1.address)).to.be.reverted;
    })

  })

});
