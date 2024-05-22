// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "fhevm/lib/TFHE.sol";
import "fhevm/abstracts/EIP712WithModifier.sol";

contract BlindAuction is EIP712WithModifier {
    // Contract owner
    address public owner;

    struct BidData {
        uint256 amount;
        uint256 timstamp;
    }
    // NFT tokenIds for Bid
    euint32[] public tokenIds;
    // nftId => (bidder => amount)
    mapping(euint32 => mapping(address => BidData)) public bidsByTokenId;
    // nfId => highestBidder
    mapping(euint32 => address) public highestBidder;
    // nftId => amount
    mapping(euint32 => uint256) public highestBid;

    uint public endTime;

    bool public manuallyStopped = false;

    // The function has been called too early.
    // Try again at `time`.
    error TooEarly(uint time);
    // The function has been called too late.
    // It cannot be called after `time`.
    error TooLate(uint time);

    event Winner(address who);

    constructor(
        uint[] memory _tokenIds,
        uint _biddingTime
    ) EIP712WithModifier("Authorization token", "1") {
        tokenIds = new euint32[](_tokenIds.length);
        for (uint i = 0; i < _tokenIds.length; i++) {
            tokenIds[i] = TFHE.asEuint32(_tokenIds[i]);
        }
        owner = msg.sender;
        endTime = block.timestamp + _biddingTime;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    modifier onlyBeforeEnd() {
        if (block.timestamp >= endTime || manuallyStopped == true)
            revert TooLate(endTime);
        _;
    }

    modifier onlyAfterEnd() {
        if (block.timestamp <= endTime && manuallyStopped == false)
            revert TooEarly(endTime);
        _;
    }

    function bid(
        bytes calldata encryptedTokenId
    ) external payable onlyBeforeEnd {
        require(msg.value != 0, "Bid amount must be greater than 0");
        euint32 tokenId = TFHE.asEuint32(encryptedTokenId);
        require(TFHE.decrypt(checkValidTokenId(tokenId)), "Invalid token id");
        BidData memory existingBid = bidsByTokenId[tokenId][msg.sender];
        // Add bid
        existingBid.amount = existingBid.amount + msg.value;
        existingBid.timstamp = block.timestamp;
        bidsByTokenId[tokenId][msg.sender] = existingBid;
        // Update highest bidder
        if (highestBid[tokenId] < bidsByTokenId[tokenId][msg.sender].amount) {
            highestBid[tokenId] = bidsByTokenId[tokenId][msg.sender].amount;
            highestBidder[tokenId] = msg.sender;
        }
        // Mint proofNFT.mintProof(msg.sender, tokenId, msg.value);
    }

    function stopBidding() external onlyOwner onlyBeforeEnd {
        manuallyStopped = true;
    }

    function checkValidTokenId(euint32 tokenId) private view returns (ebool) {
        ebool isValidTokenId = TFHE.asEbool(false);
        for (uint i = 0; i < tokenIds.length; i++) {
            if (TFHE.decrypt(TFHE.eq(tokenIds[i], tokenId))) {
                isValidTokenId = TFHE.asEbool(true);
                break;
            }
        }
        return isValidTokenId;
    }

    function getBid(
        bytes calldata encryptedTokenId,
        bytes32 publicKey,
        bytes calldata signature
    )
        public
        view
        onlySignedPublicKey(publicKey, signature)
        returns (BidData memory)
    {
        euint32 tokenId = TFHE.asEuint32(encryptedTokenId);
        return bidsByTokenId[tokenId][msg.sender];
    }

    function getBids(
        bytes32 publicKey,
        bytes calldata signature
    )
        public
        view
        onlySignedPublicKey(publicKey, signature)
        returns (bytes[] memory, BidData[] memory)
    {
        bytes[] memory _tokenIds = new bytes[](tokenIds.length);
        BidData[] memory bids = new BidData[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            _tokenIds[i] = TFHE.reencrypt(tokenIds[i], publicKey, 0);
            bids[i] = bidsByTokenId[tokenIds[i]][msg.sender];
        }
        return (_tokenIds, bids);
    }
}
