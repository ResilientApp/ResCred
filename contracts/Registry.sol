// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IssuingBody, Credential} from "./Credential.sol";

// The Registry records all issuing bodies
contract Registry {
    mapping(address => IssuingBody) registry;

    function register(string calldata name, string calldata domain) public {
        IssuingBody memory body = IssuingBody(
            block.timestamp,
            name,
            domain,
            msg.sender,
            new Credential[](0)
        );
        registry[msg.sender] = body;
    }

    function deregister() public {
        delete registry[msg.sender];
    }

    function createCredential(
        string calldata name
    ) public returns (Credential) {
        require(
            registry[msg.sender].createTime == 0,
            "Registered issuing body expected."
        );
        Credential cred = new Credential(name, registry[msg.sender]);
        registry[msg.sender].credentials.push(cred);
        return cred;
    }
}
