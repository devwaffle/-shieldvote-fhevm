// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "fhevm/lib/TFHE.sol";

contract ShieldVote {
    address public admin;
    string public proposal;
    uint256 public deadline;
    bool public resultDecrypted;

    euint8 private encryptedYesCount;
    euint8 private encryptedNoCount;

    mapping(address => bool) public hasVoted;

    constructor(string memory _proposal, uint256 _durationMinutes) {
        admin = msg.sender;
        proposal = _proposal;
        deadline = block.timestamp + (_durationMinutes * 1 minutes);
        encryptedYesCount = TFHE.asEuint8(0);
        encryptedNoCount = TFHE.asEuint8(0);
        resultDecrypted = false;
    }

    function castVote(ebool encryptedVote) external {
        require(block.timestamp < deadline, "Voting has ended");
        require(!hasVoted[msg.sender], "Already voted");

        hasVoted[msg.sender] = true;

        ebool isYes = encryptedVote;
        ebool isNo = TFHE.not(isYes);

        encryptedYesCount = TFHE.cmux(isYes, TFHE.add(encryptedYesCount, TFHE.asEuint8(1)), encryptedYesCount);
        encryptedNoCount = TFHE.cmux(isNo, TFHE.add(encryptedNoCount, TFHE.asEuint8(1)), encryptedNoCount);
    }

    function getEncryptedYesCount() external view returns (euint8) {
        require(block.timestamp >= deadline, "Voting still active");
        return encryptedYesCount;
    }

    function getEncryptedNoCount() external view returns (euint8) {
        require(block.timestamp >= deadline, "Voting still active");
        return encryptedNoCount;
    }

    function decryptResults() external view returns (uint8 yesVotes, uint8 noVotes) {
        require(block.timestamp >= deadline, "Voting still active");
        yesVotes = TFHE.decrypt(encryptedYesCount);
        noVotes = TFHE.decrypt(encryptedNoCount);
    }
}
