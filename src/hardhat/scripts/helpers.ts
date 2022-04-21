import { ethers } from 'hardhat';
import { Contract } from 'ethers';
import fetch from 'node-fetch';

// Grabs the ABI using etherscan
async function getAbi(address: string): Promise<string> {
    const contractAbiUrl = 'https://api.etherscan.io/api?module=contract&action=getabi&address=' + address + '&apikey=' + process.env.ETHERSCAN_API_KEY;
    const response = await fetch(contractAbiUrl);
    const data = await response.json();
    console.log(data);
    console.log(typeof data.result);
    return data.result;
}

// Get the contract handle from the network using etherscan's ABI API
export async function getRemoteContract(address: string): Promise<Contract> {
    const abi = await getAbi(address);
    const [owner] = await ethers.getSigners();
    return new ethers.Contract(address, abi, owner);
}
