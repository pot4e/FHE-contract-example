import { expect } from "chai";
import { ethers } from "hardhat";
import { deployBlindAuctionFixture } from "./BlindAuction.fixture";
import { getSigners } from "./signers";
import { createInstances } from "./instance";

describe("BlindAuction", function () {
  before(async function () {
    this.signers = await getSigners(ethers);
  });
  beforeEach(async function () {
    const contract = await deployBlindAuctionFixture();
    this.contractAddress = await contract.getAddress();
    this.blindAuctionContract = contract
    this.instances = await createInstances(this.contractAddress, ethers, this.signers);
  });

  it("Should set the right contract owner", async function () {
    expect(await this.blindAuctionContract.owner()).to.equal(this.signers.owner.address);
  });

  it("Should Blind valid NFT", async function () {
    const encryptedTokenId = this.instances.account1.encrypt32(1);
    const contract = this.blindAuctionContract.connect(this.signers.account1);
    const transaction = await contract.bid(encryptedTokenId, { value: ethers.parseEther("0.001") });
    await transaction.wait();
    console.log("Blind success", transaction.hash);
    // Call the method
    const token = this.instances.account1.getTokenSignature(this.contractAddress) || {
      signature: "",
      publicKey: "",
    };
    const balance = (await contract.getBid(encryptedTokenId, token.publicKey, token.signature)).amount;
    expect(balance).to.equal(ethers.parseEther("0.001"));
  });
});
