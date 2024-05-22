import hre, { ethers } from "hardhat";

import type { BlindAuction } from "../types";
import { TOKEN_IDS, BLIND_TIME } from "./config";
import { getSigners } from "./signers";

export async function deployBlindAuctionFixture(): Promise<BlindAuction> {
  const signers = await getSigners(ethers);
  const contractFactory = await ethers.getContractFactory("BlindAuction");
  const contract = await contractFactory.connect(signers.owner).deploy(TOKEN_IDS, BLIND_TIME);
  await contract.waitForDeployment();

  return contract;
}
