import { JsonRpcProvider, ethers } from "ethers"
import { config as dotenvConfig } from "dotenv";
import bindAbiObject from "../artifacts/contracts/BlindAuction.sol/BlindAuction.json";
const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
import { resolve } from "path";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) });
(() => {
    const contractAddress = ""
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY_2 as string, new JsonRpcProvider("https://testnet.inco.org"))
    const contract = new ethers.Contract(contractAddress, bindAbiObject.abi, wallet);
    //const bid = contract.bid(ethers.formatBytes32String("1"), { value: ethers.utils.parseEther("0.001") });
})()