
const { expect } = require("chai");

describe("Lock", function () {

  let bounty;
  let owner;
  let organizer1;
  let organizer2;
  let participant1;
  let participant2;
  beforeEach(async function () {
    [owner, organizer1, organizer2, participant1, participant2] = await ethers.getSigners();

    const Bounty = await ethers.getContractFactory("Earn");
    bounty = await Bounty.deploy();
  })

  describe("Deployment", () => {

    it("should assign the owner", async () => {
      expect(await bounty.owner()).to.be.equal(owner.address);
    })
  })

  describe("owner can add organinzer and organizer gets privillege",()=>{
    
  })



 
});
