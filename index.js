const { ethers } = require("ethers");

// Base Sepolia RPC URL - replace with an actual RPC provider
const RPC_URL = "https://base-sepolia-rpc.publicnode.com";
const provider = new ethers.JsonRpcProvider(RPC_URL);

// Replace with your wallet private key
const PRIVATE_KEY =
  "69b6b4ce0909dcff850454e1606a33b354fd59169d8415b0c1c23ac718bd7f3e";
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Contract address and ABI
const CONTRACT_ADDRESS = "0x3C3d23466FEB30e9D2a7d2eFd213e819AA83B5a3";
const CONTRACT_ABI = [
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "referrer",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "level",
				"type": "uint256"
			}
		],
		"name": "NewUser",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "level",
				"type": "uint256"
			}
		],
		"name": "RewardDistributed",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "level",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "admin",
				"type": "address"
			}
		],
		"name": "_distributeRewards",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "startLevel",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "batchSize",
				"type": "uint256"
			}
		],
		"name": "initializeBloomFilters",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "requester",
				"type": "address"
			}
		],
		"name": "register",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"stateMutability": "payable",
		"type": "receive"
	},
	{
		"inputs": [],
		"name": "withdraw",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_initialLevels",
				"type": "uint256"
			},
			{
				"internalType": "contract MyToken",
				"name": "_token",
				"type": "address"
			},
			{
				"internalType": "contract BinaryTree",
				"name": "_bTree",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [],
		"name": "_numHashes",
		"outputs": [
			{
				"internalType": "uint8",
				"name": "",
				"type": "uint8"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "BASE_REWARD",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "bloomFiltersInitialized",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "bloomFilterSize",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "bTree",
		"outputs": [
			{
				"internalType": "contract BinaryTree",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "level",
				"type": "uint256"
			}
		],
		"name": "checkMembership",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "currentLevel",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"name": "levelFilters",
		"outputs": [
			{
				"internalType": "contract BloomFilter",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "mtkn",
		"outputs": [
			{
				"internalType": "contract MyToken",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "NUM_LEVELS",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "owner",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"name": "users",
		"outputs": [
			{
				"internalType": "address",
				"name": "referrer",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "myBalance",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "level",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
]

// Initialize the contract
const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, wallet);
// Function to generate a random Ethereum address
function generateRandomAddress() {
  const randomWallet = ethers.Wallet.createRandom();
  return randomWallet.address;
}

// Sleep function to add delay
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const TOTAL_LEVELS = 1000;
const BATCH_SIZE = 50; // Set an appropriate batch size based on gas limits
let startLevel = 1;

async function initializeBloomFiltersInBatches() {
    for (let startLevel = 1; startLevel < TOTAL_LEVELS; startLevel += BATCH_SIZE) {
        const endLevel = Math.min(startLevel + BATCH_SIZE, TOTAL_LEVELS);
        console.log(`Initializing bloom filters from level ${startLevel} to ${endLevel - 1}`);

        try {
            const tx = await contract.initializeBloomFilters(startLevel, BATCH_SIZE);
            console.log(`Transaction hash: ${tx.hash}`);

            // Wait for transaction to be mined
            const receipt = await tx.wait();
            console.log(`Gas used for initializing levels ${startLevel} to ${endLevel - 1}: ${receipt.gasUsed.toString()}`);
        } catch (error) {
            console.error(`Error initializing bloom filters for levels ${startLevel} to ${endLevel - 1}:`, error);
            break; // Exit loop on error to prevent further calls
        }
    }
}

async function registerUsers() {
  try {
    for (let i = 1; i <= 1000; i++) {
      // Adjust the loop count as needed
      const randomAddress = generateRandomAddress();
      console.log(`Registering user ${i}: ${randomAddress}`);

      // Call the register function with the random address as referrer
      const tx = await contract.register(randomAddress);
      console.log(`Transaction hash: ${tx.hash}`);
      const receipt = await tx.wait();

      // Get the gas used
      const gasUsed = receipt.gasUsed;
      console.log(`Gas used for addUser transaction: ${gasUsed.toString()}`);

    //   let level = await contract.users(randomAddress);

    //   console.log("level of this user is ", String(Number(level[1])+1));
    // //   console.log("params are for distribution", randomAddress, String(Number(level[1])+1), "0xE43A6D07b48cE60004918e584d6b8419E95aAD7c");
      
    // //   const rewardsTRX = await contract._distributeRewards(randomAddress, String(Number(level[1])+1), "0xE43A6D07b48cE60004918e584d6b8419E95aAD7c");
    // //   // Add a 10-second delay after every 10 registrations
    // //   const rewardReceipt = await rewardsTRX.wait();
    // //   const rewardsDistributionGasUsed = rewardReceipt.gasUsed;

    // //   console.log(`Gas used for rewardsDistributionGasUsed transaction: ${rewardsDistributionGasUsed.toString()}`);
      if (i % 10 === 0) {
        console.log("Pausing for 10 seconds...");
        await sleep(10000);
      }
    }
  } catch (error) {
    console.error("Error during registration:", error);
  }
}

async function distributeRewards(_user, level, admin){
    const tx = await contract._distributeRewards(randomAddress);
      console.log(`Transaction hash: ${tx.hash}`);
      const receipt = await tx.wait();

      // Get the gas used
      const gasUsed = receipt.gasUsed;
      console.log(`Gas used for addUser transaction: ${gasUsed.toString()}`);
    
}

// Run the registration function
registerUsers();
// initializeBloomFiltersInBatches();