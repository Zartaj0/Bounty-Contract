const { expect } = require("chai");

describe("Lock", function () {

  let bounty;
  let owner;
  let bob;
  let organizer1;
  let organizer2;
  let participant1;
  let participant2;
  let participant3;
  beforeEach(async function () {
    [owner, bob, organizer1, organizer2, participant1, participant2, participant3] = await ethers.getSigners();

    const Bounty = await ethers.getContractFactory("Earn");
    bounty = await Bounty.deploy();
  })

  describe("Deployment", () => {

    it("should assign the owner", async () => {
      expect(await bounty.owner()).to.be.equal(owner.address);
    })

  })

  describe("users can apply and owner can approve", () => {
    it("organizer application should be stored and approved", async () => {
      await expect(bounty.connect(organizer1).getVerified(0, "link")).to.be.fulfilled;
      //console.log(await bounty.ApplicationList[0]);
      await expect(bounty.approveRequests(0)).to.be.fulfilled;
    })
    it("participants application should be stored and approved", async () => {
      await expect(bounty.connect(participant1).getVerified(1, "link")).to.be.fulfilled;
      //console.log(await bounty.ApplicationList(0));
      await expect(bounty.approveRequests(0)).to.be.fulfilled;
    })


  })

  describe("Organizer & participants privilleges ", () => {
    beforeEach(async () => {
      await bounty.connect(organizer1).getVerified(0, "link");
      await bounty.approveRequests(0)
      await bounty.connect(organizer2).getVerified(0, "link");
      await bounty.approveRequests(1)

      await bounty.connect(participant1).getVerified(1, "link");
      await bounty.approveRequests(2)
      await bounty.connect(participant2).getVerified(1, "link");
      await bounty.approveRequests(3)
      await bounty.connect(participant3).getVerified(1, "link");
      await bounty.approveRequests(4)

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
      await expect(bounty.connect(bob).submitBounties(0, "Link3SOl")).to.be.reverted;
      await expect(bounty.connect(participant1).submitBounties(0, "Link4Sol")).to.be.fulfilled;
      //console.log(await bounty.SubmittedBounties(0, 0));

    })

    describe("Choosing Winners", async () => {
      beforeEach(async () => {
     
        await bounty.connect(organizer1).addBounties(3, "link2Bounty", 5, { value: ethers.utils.parseEther("5") });
         await bounty.connect(organizer2).addBounties(19, "link2Bounty", 15, { value: ethers.utils.parseEther("15") });
        await bounty.connect(participant1).submitBounties(0, "LinkSol");
        await bounty.connect(participant2).submitBounties(0, "Link2Sol");
        await bounty.connect(participant3).submitBounties(0, "LinkSol");
        await bounty.connect(participant1).submitBounties(1, "Link3SSOl");
        await bounty.connect(participant2).submitBounties(1, "Link4Sol");
        await bounty.connect(participant3).submitBounties(1, "Link4Sol");
        // console.log(await bounty.SubmittedBounties(0, 1));
      console.log(await bounty.AllBounties(0)); 

      })

      it("contract should have equivallent funds", async () => {
        expect(await ethers.provider.getBalance(bounty.address)).to.be.equal(ethers.utils.parseEther("20"));
      })

      it("respective organizers can only choose winners and only after the bounty is over", async () => {
        await expect(bounty.connect(organizer1).chooseWinners(0, ["0", "2"], ["2", "1"])).to.be.revertedWith("bounty is still running");
        await expect(bounty.connect(organizer2).chooseWinners(1, ["1", "2"], ["4", "7"])).to.be.revertedWith("bounty is still running");

        await network.provider.send("evm_increaseTime", [3 * 24 * 3600]);

        await expect(bounty.connect(organizer1).chooseWinners(0, ["0", "2"], ["2", "1"])).to.be.fulfilled;
        await network.provider.send("evm_increaseTime", [16 * 24 * 3600]);

        await expect(bounty.connect(organizer2).chooseWinners(1, ["1", "2"], ["4", "7"])).to.be.fulfilled;

        // console.log(await bounty.ClaimablePrize(participant1.address));
        // console.log(await bounty.ClaimablePrize(participant2.address));
        // console.log(await bounty.ClaimablePrize(participant3.address));
      })

      it("Other organizers can't choose winners", async () => {
        await expect(bounty.connect(organizer2).chooseWinners(0, ["0", "2"], ["2", "1"])).to.be.revertedWith("you are not the organizer for this bounty");

        await network.provider.send("evm_increaseTime", [3 * 24 * 3600]);

        await expect(bounty.connect(organizer2).chooseWinners(0, ["0", "2"], ["2", "1"])).to.be.revertedWith("you are not the organizer for this bounty");
      })

      describe("After Choosing winners", async () => {
        beforeEach(async () => {
          await network.provider.send("evm_increaseTime", [3 * 24 * 3600]);
          await bounty.connect(organizer1).chooseWinners(0, ["0", "2"], ["2", "1"]);

          await network.provider.send("evm_increaseTime", [16 * 24 * 3600]);
          await bounty.connect(organizer2).chooseWinners(1, ["1", "2"], ["4", "7"]);
          // console.log(await bounty.ClaimablePrize(participant1.address));
          // console.log(await bounty.ClaimablePrize(participant2.address));
          // console.log(await bounty.ClaimablePrize(participant3.address));
        })


        it("user can withdraw their funds", async () => {

          console.log(await ethers.provider.getBalance(participant1.address)); 
          await bounty.connect(participant1).claimPrize();
          console.log(await ethers.provider.getBalance(participant1.address)); 

        })

        it("user1 can withdraw their funds", async () => {
          let balance1 = await ethers.provider.getBalance(participant1.address);
          let tx = await bounty.connect(participant1).claimPrize();
          let receipt = await tx.wait();
          let gasCost = receipt.gasUsed.mul(receipt.effectiveGasPrice);
          expect(await ethers.provider.getBalance(participant1.address)).to.be.equal(balance1.add(ethers.utils.parseEther("2")).sub(gasCost));
          console.log(await ethers.provider.getBalance(bounty.address))

        })
        it("user2 can withdraw their funds", async () => {
          let balance2 = await ethers.provider.getBalance(participant2.address);
          let tx = await bounty.connect(participant2).claimPrize();
          let receipt = await tx.wait();
          let gasCost = receipt.gasUsed.mul(receipt.effectiveGasPrice);
          expect(await ethers.provider.getBalance(participant2.address)).to.be.equal(balance2.add(ethers.utils.parseEther("4")).sub(gasCost));
        })
        it("user3 can withdraw their funds", async () => {
          let balance3 = await ethers.provider.getBalance(participant3.address);
          let tx = await bounty.connect(participant3).claimPrize();
          let receipt = await tx.wait();
          let gasCost = receipt.gasUsed.mul(receipt.effectiveGasPrice);

          expect(await ethers.provider.getBalance(participant3.address)).to.be.equal(balance3.add(ethers.utils.parseEther("8")).sub(gasCost));

        })
      })

    })

  })

});
