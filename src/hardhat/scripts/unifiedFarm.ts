import path from 'path';
const envPath = path.join(__dirname, '../../.env');
require('dotenv').config({ path: envPath });

import { ethers } from 'hardhat';
import { FraxUnifiedFarmERC20TempleFRAXTEMPLE, FraxUnifiedFarmERC20TempleFRAXTEMPLE__factory } from '../typechain';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { getRemoteContract } from './helpers';

// This is a clone of how the mainnet token is deployed. See
// https://etherscan.io/address/0x10460d02226d6ef7B2419aE150E6377BdbB7Ef16#code
async function deploy(owner: SignerWithAddress): Promise<FraxUnifiedFarmERC20TempleFRAXTEMPLE> {
    return await new FraxUnifiedFarmERC20TempleFRAXTEMPLE__factory(owner).deploy(
      // _owner
      owner.address,

      // _rewardTokens
      // FXS: https://etherscan.io/address/0x3432b6a60d23ca0dfca7761b7ab56459d9c964d0
      // TEMPLE: https://etherscan.io/address/0x470ebf5f030ed85fc1ed4c2d36b9dd02e77cf1b7
      ["0x3432b6a60d23ca0dfca7761b7ab56459d9c964d0", "0x470ebf5f030ed85fc1ed4c2d36b9dd02e77cf1b7"],

      // _rewardManagers
      // Frax Finance: Comptroller  (same as process.env.COMPTROLLER_MSIG_ADDRESS)
      // ?
      ["0xb1748c79709f4ba2dd82834b8c82d4a505003f27", "0x4d6175d58c5aceef30f546c0d5a557effa53a950"], 

      [11574074074074, 0], //_rewardRates

      // _gaugeControllers (null addresses often used for burn/mint)
      ["0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000"],

      // _rewardDistributors
      ["0x278dc748eda1d8efef1adfb518542612b49fcd34", "0x0000000000000000000000000000000000000000"], 

      // _stakingToken
      // Uniswap V2 (UNI-V2)
      "0x6021444f1706f15465bee85463bcc7d7cc17fc03",
    );
}

async function main() {
    const [owner] = await ethers.getSigners();
    console.log(owner);

    // Deployed locally to: 
    //    const token = await deploy(owner);
    // const address = "0x14718fbe39b6d90ad07f5f80578f681fee6fc1ea";
    // const token = FraxUnifiedFarmERC20TempleFRAXTEMPLE__factory.connect(address, owner);
    // console.log(token.functions);

    // Get the prod deployed contract (forked locally)
    const token = await getRemoteContract("0x10460d02226d6ef7B2419aE150E6377BdbB7Ef16");
    console.log(token.functions);

    // Just some random addr which recently called stakeLocked() on 
    // https://etherscan.io/address/0x10460d02226d6ef7B2419aE150E6377BdbB7Ef16
    // You'll likely need to find another more recent one.
    const sampleAddr = "0x5d71babf4f697c25cde72ddf4045d2ca4bdcfb32";
    console.log(await token.lockedStakesOf(sampleAddr))
    console.log(await token.calcCurCombinedWeight(sampleAddr));
}


// Questions:
// * Can we re-deploy the contract, but clone state from an older version (ie migrate the state)?
// * Operationally how would we track state/idx_id (rather than looping through to match kek_id)?
//        Would the idx_id be invalid when this is called? delete lockedStakes[staker_address][theArrayIndex];
//        Or pass in both as a hint...and then would need to have some process so client can re-fetch current indexes.
// * _withdrawLocked requires either the stake period to have ended (normal), or 
//       stakesUnlocked (emergency - onlyByOwnGov) or 
//       valid_migrators (onlyByOwnGov)
//    which doesn't really seem plausible? How would we use this?

// Sample lockedStakes:
// [
//   [
//     '0xcafed64df36f8aa9b465fde882b2c9f2a6eca8d17468fd801c57fb471338bc44',
//     BigNumber { value: "1648930060" },
//     BigNumber { value: "6081720914093912792550" },
//     BigNumber { value: "1649016460" },
//     BigNumber { value: "1001826484018264840" },
//     kek_id: '0xcafed64df36f8aa9b465fde882b2c9f2a6eca8d17468fd801c57fb471338bc44',
//     start_timestamp: BigNumber { value: "1648930060" },
//     liquidity: BigNumber { value: "6081720914093912792550" },
//     ending_timestamp: BigNumber { value: "1649016460" },
//     lock_multiplier: BigNumber { value: "1001826484018264840" }
//   ],
//   [
//     '0xe60e33d921202d45e6026454ddc4a80ab517ca3ea5d9cc9201c8d0ebb970e2e6',
//     BigNumber { value: "1649040525" },
//     BigNumber { value: "8648335221246315394617" },
//     BigNumber { value: "1649126925" },
//     BigNumber { value: "1001826484018264840" },
//     kek_id: '0xe60e33d921202d45e6026454ddc4a80ab517ca3ea5d9cc9201c8d0ebb970e2e6',
//     start_timestamp: BigNumber { value: "1649040525" },
//     liquidity: BigNumber { value: "8648335221246315394617" },
//     ending_timestamp: BigNumber { value: "1649126925" },
//     lock_multiplier: BigNumber { value: "1001826484018264840" }
//   ],
//   [
//     '0xe0e16ed06e502bde8a43cc530229ec126c05dc518cb66142e05d334719a26ddb',
//     BigNumber { value: "1649378060" },
//     BigNumber { value: "8982576664633711812168" },
//     BigNumber { value: "1649464460" },
//     BigNumber { value: "1001826484018264840" },
//     kek_id: '0xe0e16ed06e502bde8a43cc530229ec126c05dc518cb66142e05d334719a26ddb',
//     start_timestamp: BigNumber { value: "1649378060" },
//     liquidity: BigNumber { value: "8982576664633711812168" },
//     ending_timestamp: BigNumber { value: "1649464460" },
//     lock_multiplier: BigNumber { value: "1001826484018264840" }
//   ],
//   [
//     '0x51d6fc44ecbe1e3dd2da5a15d935dbea6a92e5855dfdebb75282c157d9158702',
//     BigNumber { value: "1649425018" },
//     BigNumber { value: "8509822245749271657222" },
//     BigNumber { value: "1649511418" },
//     BigNumber { value: "1001826484018264840" },
//     kek_id: '0x51d6fc44ecbe1e3dd2da5a15d935dbea6a92e5855dfdebb75282c157d9158702',
//     start_timestamp: BigNumber { value: "1649425018" },
//     liquidity: BigNumber { value: "8509822245749271657222" },
//     ending_timestamp: BigNumber { value: "1649511418" },
//     lock_multiplier: BigNumber { value: "1001826484018264840" }
//   ],
//   [
//     '0x35e9bfa3d93a2b844de14d9d0828288d2464804dc943d59399d2a4c31f4ff1fe',
//     BigNumber { value: "1650199611" },
//     BigNumber { value: "28705991835199336910502" },
//     BigNumber { value: "1650286011" },
//     BigNumber { value: "1001826484018264840" },
//     kek_id: '0x35e9bfa3d93a2b844de14d9d0828288d2464804dc943d59399d2a4c31f4ff1fe',
//     start_timestamp: BigNumber { value: "1650199611" },
//     liquidity: BigNumber { value: "28705991835199336910502" },
//     ending_timestamp: BigNumber { value: "1650286011" },
//     lock_multiplier: BigNumber { value: "1001826484018264840" }
//   ],
//   [
//     '0x318f7823b386728c38188ec47b0de92ff48af32558a21c8f3112d109d4d68463',
//     BigNumber { value: "1650496343" },
//     BigNumber { value: "55376132951420997581797" },
//     BigNumber { value: "1650582743" },
//     BigNumber { value: "1001826484018264840" },
//     kek_id: '0x318f7823b386728c38188ec47b0de92ff48af32558a21c8f3112d109d4d68463',
//     start_timestamp: BigNumber { value: "1650496343" },
//     liquidity: BigNumber { value: "55376132951420997581797" },
//     ending_timestamp: BigNumber { value: "1650582743" },
//     lock_multiplier: BigNumber { value: "1001826484018264840" }
//   ]
// ]
//
// Sample calcCurCombinedWeight
// [
//   BigNumber { value: "116516959008654910673680" },
//   BigNumber { value: "0" },
//   BigNumber { value: "116516957627744116068110" },
//   old_combined_weight: BigNumber { value: "116516959008654910673680" },
//   new_vefxs_multiplier: BigNumber { value: "0" },
//   new_combined_weight: BigNumber { value: "116516957627744116068110" }
// ]

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });