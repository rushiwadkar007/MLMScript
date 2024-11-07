// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
contract BloomFilter {
    uint256[] public bitArray;
    uint256 public size;
    uint8 public numHashes;

    constructor(uint256 _size, uint8 _numHashes) {
        size = _size;
        numHashes = _numHashes;
        bitArray = new uint256[]((_size + 255) / 256); // each uint256 can store 256 bits
    }

    function _hash(bytes32 data, uint8 i) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(data, i)));
    }

    function add(bytes32 item) external {
        for (uint8 i = 0; i < numHashes; i++) {
            uint256 hashVal = _hash(item, i) % size;
            uint256 index = hashVal / 256;
            uint256 bitPos = hashVal % 256;
            bitArray[index] |= (1 << bitPos); // Set the bit at bitPos 
        }
    }

    function contains(bytes32 item) external view returns (bool) {
        for (uint8 i = 0; i < numHashes; i++) {
            uint256 hashVal = _hash(item, i) % size;
            uint256 index = hashVal / 256;
            uint256 bitPos = hashVal % 256;
            if ((bitArray[index] & (1 << bitPos)) == 0) {
                return false; // if any bit is 0, the item is definitely not in the set
            }
        }
        return true; // all bits are 1, so the item is probably in the set
    }
}
pragma solidity ^0.8.0;

contract BinaryTree {
    struct Node {
        address userAddress;
        uint256 leftChild;
        uint256 rightChild;
    }

    Node[] public nodes;
    mapping(address => uint256) public addressToIndex;

    event UserAdded(address indexed user, uint256 indexed nodeIndex);

    constructor() {
        // Initialize root node (index 0) as a placeholder
        nodes.push(Node(address(0), 0, 0));
    }

    function addUser(address userAddress) external returns (uint256) {
        require(userAddress != address(0), "Invalid address");
        require(addressToIndex[userAddress] == 0, "User already exists");

        uint256 newIndex = nodes.length+1;
        nodes.push(Node(userAddress, 0, 0));
        addressToIndex[userAddress] = newIndex;

        if (newIndex >= 1) {
            uint256 parentIndex = (newIndex - 1) / 2;
            if (nodes[parentIndex].leftChild == 0) {
                nodes[parentIndex].leftChild = newIndex;
            } else {
                nodes[parentIndex].rightChild = newIndex;
            }
        }

        emit UserAdded(userAddress, newIndex);
        return newIndex;
    }

    function getNode(uint256 index) external view returns (address userAddress) {
        require(index <= nodes.length, "Node does not exist");
        Node memory node = nodes[index];
        return node.userAddress;
    }

    function getParent(uint256 index) external view returns (uint256) {
        require(index >= 1 && index <= nodes.length, "Invalid node index");
        return (index - 1) / 2;
    }

    function getLeftChild(uint256 index) external view returns (uint256) {
        require(index <= nodes.length, "Invalid node index");
        return nodes[index].leftChild;
    }

    function getRightChild(uint256 index) external view returns (uint256) {
        require(index <= nodes.length, "Invalid node index");
        return nodes[index].rightChild;
    }

    function getTreeSize() external view returns (uint256) {
        return nodes.length;
    }
}


contract MLMWithBloomFilter {
    MyToken public mtkn;
    BinaryTree public bTree;
    uint256 public NUM_LEVELS;
    uint256 public constant BASE_REWARD = 100000;
    address public owner;

    struct User {
        address referrer;
        uint256 myBalance;
        uint256 level;
    }

    mapping(address => User) public users;
    mapping(uint256 => BloomFilter) public levelFilters;
    uint256 public bloomFilterSize;
    uint8 public _numHashes = 5;
    bool public bloomFiltersInitialized;
    uint256 public currentLevel;

    event NewUser(address indexed user, address indexed referrer, uint256 level);
    event RewardDistributed(address indexed user, uint256 amount, uint256 level);

    constructor(uint256 _initialLevels, MyToken _token, BinaryTree _bTree) {
        owner = msg.sender;
        bTree = _bTree;
        NUM_LEVELS = _initialLevels;
        bloomFilterSize = NUM_LEVELS;
        users[owner] = User({referrer: address(0), myBalance: 0, level: 0});
        mtkn = _token;        
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Invalid Admin");
        _;
    }

    function initializeBloomFilters(uint256 startLevel, uint256 batchSize) external onlyOwner {
        
         currentLevel = startLevel + batchSize - 1;

         if(!bloomFiltersInitialized){
            bloomFiltersInitialized = true;
         }

        for (uint256 i = startLevel; i <= currentLevel; i++) {
            levelFilters[i] = new BloomFilter(bloomFilterSize, _numHashes);
        }
    }

    function register(address requester) external {
        bTree.addUser(requester);
        require(bloomFiltersInitialized, "Bloom filters not initialized yet");
        require(users[requester].referrer == address(0), "Already registered");
        require(users[bTree.getNode(bTree.getParent(bTree.addressToIndex(requester)))].level + 1 <= NUM_LEVELS, "Referrer level exceeds limit");

        uint256 level = users[bTree.getNode(bTree.getParent(bTree.addressToIndex(requester)))].level + 1;
        require(!levelFilters[level].contains(keccak256(abi.encodePacked(requester))), "Already in this level");

        users[requester] = User({referrer: bTree.getNode(bTree.getParent(bTree.addressToIndex(requester))), myBalance: mtkn.balanceOf(requester), level: level});
        levelFilters[level].add(keccak256(abi.encodePacked(requester)));

        emit NewUser(requester, bTree.getNode(bTree.getParent(bTree.addressToIndex(requester))), level);

        // _distributeRewards(bTree.getNode(bTree.getParent(bTree.addressToIndex(requester))), users[bTree.getNode(bTree.getParent(bTree.addressToIndex(requester)))].level, owner);
    }

    function _distributeRewards(address _user, uint256 level,  address admin) public {
        address currentReferrer = users[_user].referrer;
        // while (level <= currentLevel && currentReferrer != address(0)) {
            uint256 reward = BASE_REWARD / (2 ** (currentLevel - 1));
            users[currentReferrer].myBalance += reward;
            mtkn.transferFrom(admin, users[_user].referrer, reward);
            emit RewardDistributed(currentReferrer, reward, level);
            currentReferrer = users[currentReferrer].referrer;
        // }
    }

    function withdraw() external {
        uint256 amount = users[msg.sender].myBalance;
        require(amount > 0, "No balance to withdraw");
        users[msg.sender].myBalance = 0;
        payable(msg.sender).transfer(amount);
    }

    function checkMembership(address _user, uint256 level) external view returns (bool) {
        require(level <= NUM_LEVELS, "Level out of bounds");
        return levelFilters[level].contains(keccak256(abi.encodePacked(_user)));
    }

    receive() external payable {}
}

