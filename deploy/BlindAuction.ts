import hre, { ethers } from "hardhat";
import { TOKEN_IDS, BLIND_TIME } from "../test/config";

(async () => {
    const [owner] = await hre.ethers.getSigners();

    const contractFactory = await ethers.getContractFactory("BlindAuction");
    const contract = await contractFactory.connect(owner).deploy(TOKEN_IDS, BLIND_TIME);
    await contract.waitForDeployment();
    console.log("BlindAuction deployed to: ", await contract.getAddress());
})()