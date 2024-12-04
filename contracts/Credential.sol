// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

struct IssuingBody {
    uint createTime;
    string name;
    string domain;
    address owner;
    uint numCredentials;
    mapping(uint => Credential) credentials;
}

// TODO: figure out memory vs calldata vs storage for return type
abstract contract Credential {
    struct HolderMetadata {
        bool granted;
        uint256 expiry; // 0 for never expire
        mapping(address => bool) requests;
    }

    string public name;
    address public owner;
    uint256 createTime;
    uint256 verifyTimeout;
    uint256 expiry;
    mapping(address => HolderMetadata) holders; // holder address -> expiry timestamp or 1 for never expires

    // Set _expiry to 0 for never expire
    constructor(
        string memory _name,
        IssuingBody storage _body,
        uint256 _expiry
    ) {
        name = _name;
        owner = _body.owner;
        createTime = block.timestamp;
        expiry = _expiry;
    }

    // Issuing Body grants a credential to a qualifying person
    // The Issuing Body is responsible for transmitting the key pair of the grantee account securely.
    event Grant(address grantee, uint256 expiry);
    // A Verifier sends a verify request to the grantee.
    event VerifyRequest(address verifier, address grantee);
    // Given their credential is still valid, a grantee can approve the request with their keys.
    event ApproveVerification(address verifier, address grantee);

    function grant(address grantee) public returns (bool) {
        if (msg.sender == owner) {
            HolderMetadata storage holder = holders[grantee];
            holder.granted = true;
            if (expiry != 0) holder.expiry = block.timestamp + expiry;
            emit Grant(grantee, holder.expiry);
            return true;
        }
        return false;
    }

    function sendVerifyRequest(address grantee) public returns (bool) {
        // Confirm grantee has credential
        HolderMetadata storage holder = holders[grantee];
        if (!holder.granted) return false;
        if (holder.expiry < block.timestamp && holder.expiry != 0) {
            return false;
        }

        if ()
        for (uint idx = 0; idx < holder.requests.length; idx++) {
            // Reject due to existing request from same sender
            if (holder.requests[idx] == msg.sender) return false;
        }
        holder.requests.push(msg.sender);
        emit VerifyRequest(msg.sender, grantee);
        return true;
    }

    function getVerifyRequests() public view returns (address[] memory) {
        return holders[msg.sender].requests;
    }

    function approveVerifyRequest(address verifier) public returns (bool) {
        // Confirm msg.sender still holds valid credential
        HolderMetadata storage holder = holders[msg.sender];
        if (holder.expiry < block.timestamp && holder.expiry != 0) {
            return false;
        }
        if (holder.requests.length == 0) return false;
        // Confirm verification request exists
        for (uint idx = 0; idx < holder.requests.length; idx++) {
            if (holder.requests[idx] == verifier) {
                // Delete request from requests
                delete holder.requests[idx];
                emit ApproveVerification(verifier, msg.sender);
                return true;
            }
        }
        return false;
    }
}
