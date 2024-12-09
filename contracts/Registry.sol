// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {StructuredLinkedList} from "../node_modules/solidity-linked-list/contracts/StructuredLinkedList.sol";

contract IssuingBody {
    Registry public registry;
    uint public id;

    string public name;
    string public domain;
    address public owner;

    uint public nextId;
    mapping(uint => Credential) credentials;

    constructor(
        Registry _registry,
        string memory _name,
        string memory _domain
    ) {
        registry = _registry;
        name = _name;
        domain = _domain;
        owner = msg.sender;
    }

    function setId(uint _id) public {
        require(address(registry) == msg.sender);
        id = _id;
    }

    function addCredential(Credential cred) public returns (uint) {
        require(msg.sender == owner);
        require(cred.issuingBody() == this);
        credentials[nextId] = cred;
        uint credId = nextId;
        cred.setId(nextId);
        nextId++;
        return credId;
    }

    function getCredentialById(uint credId) public view returns (Credential) {
        return credentials[credId];
    }

    function getCredentials() public view returns (Credential[] memory) {
        Credential[] memory creds = new Credential[](nextId - 1);
        for (uint i = 1; i < nextId; i++) {
            creds[i - 1] = getCredentialById(i);
        }
        return creds;
    }
}

contract CredentialGrant {
    using StructuredLinkedList for StructuredLinkedList.List;
    StructuredLinkedList.List pendingRequests;

    uint public id;
    address public grantee;
    string public name;
    uint public expiry;

    Registry public registry;
    IssuingBody public issuingBody;
    Credential public credential;

    constructor(
        Credential _credential,
        address _grantee,
        string memory _name,
        uint _expiry
    ) {
        credential = _credential;
        issuingBody = _credential.issuingBody();
        registry = issuingBody.registry();
        require(msg.sender == issuingBody.owner());
        grantee = _grantee;
        name = _name;
        expiry = _expiry;
        pendingRequests.pushFront(0);
    }

    function setId(uint _id) public {
        require(msg.sender == address(credential));
        id = _id;
    }

    function checkPerms() private view {
        require(
            msg.sender == address(registry) ||
                msg.sender == address(issuingBody) ||
                msg.sender == issuingBody.owner() ||
                msg.sender == address(credential) ||
                msg.sender == grantee
        );
    }

    function getReqIds() public view returns (uint[] memory) {
        checkPerms();
        uint size = pendingRequests.sizeOf();

        uint[] memory reqIds = new uint[](size - 1);
        uint node = 0;
        uint idx = 0;
        while (true) {
            (bool nodeExists, uint value) = pendingRequests.getNextNode(node);
            if (!nodeExists) break;
            reqIds[idx] = value;
        }
        return reqIds;
    }

    function getNumReqs() public view returns (uint) {
        checkPerms();
        return pendingRequests.sizeOf();
    }

    function hasReq() public view returns (bool) {
        checkPerms();
        return pendingRequests.sizeOf() > 0;
    }

    function getReq() public view returns (uint) {
        checkPerms();
        (bool exists, uint value) = pendingRequests.getNextNode(0);
        return value;
    }

    function getNextReq(uint node) public view returns (bool, uint) {
        checkPerms();
        return pendingRequests.getNextNode(node);
    }

    function addReqId(uint reqId) public {
        checkPerms();
        pendingRequests.pushBack(reqId);
    }

    function removeReqId(uint reqId) public {
        checkPerms();
        pendingRequests.remove(reqId);
    }
}

contract Credential {
    uint public id;
    string public name;
    uint public expiry;
    Registry public registry;
    IssuingBody public issuingBody;

    uint public nextGrantId;

    mapping(address => CredentialGrant) grantByOwner; // holder address lookup
    mapping(uint => CredentialGrant) grantById; //

    // Set _expiry to 0 for never expire
    constructor(IssuingBody _body, string memory _name, uint256 _expiry) {
        name = _name;
        issuingBody = _body;
        registry = _body.registry();
        expiry = _expiry;
        nextGrantId = 1;
    }

    function setId(uint _id) public {
        require(msg.sender == address(issuingBody));
        id = _id;
    }

    function getCredGrants() public view returns (CredentialGrant[] memory) {
        CredentialGrant[] memory creds = new CredentialGrant[](nextGrantId - 1);
        for (uint i = 1; i < nextGrantId; i++) {
            creds[i - 1] = grantById[i];
        }
        return creds;
    }

    function addGrant(CredentialGrant credGrant) public returns (uint) {
        require(msg.sender == address(issuingBody.owner()));
        grantByOwner[credGrant.grantee()] = credGrant;
        grantById[nextGrantId] = credGrant;
        uint grantId = nextGrantId;
        nextGrantId++;
        return grantId;
    }

    // function grant(
    //     address grantee,
    //     string calldata granteeName
    // ) public returns (bool) {
    //     if (msg.sender != registry) return false;
    //     uint credExpiry = 0;
    //     if (expiry != 0) credExpiry = block.timestamp + expiry;
    //     CredentialGrant credGrant = new CredentialGrant(
    //         nextGrantId,
    //         grantee,
    //         granteeName,
    //         credExpiry,
    //         Registry(registry),
    //         IssuingBody(issuingBody),
    //         this
    //     );
    //     addGrant(credGrant);
    //     return true;
    // }
}

enum VerifyRequestStatus {
    PENDING, // 0
    APPROVED, // 1
    REJECTED // 2
}

contract VerifyRequest {
    uint public id;
    Registry public registry;
    Verifier public verifier;
    CredentialGrant public credGrant;
    VerifyRequestStatus public status;

    constructor(Verifier _verifier, CredentialGrant _credGrant) {
        require(msg.sender == _verifier.owner());
        verifier = _verifier;
        credGrant = _credGrant;
        registry = _verifier.registry();
        status = VerifyRequestStatus.PENDING;
    }

    function setId(uint _id) public {
        require(msg.sender == address(registry));
        id = _id;
    }

    function setStatus(VerifyRequestStatus _status) public returns (bool) {
        require(msg.sender == address(verifier.registry()));
        require(
            status == VerifyRequestStatus.PENDING,
            "Status can only be set once"
        );
        status = _status;
        return true;
    }
}

contract Verifier {
    uint public id;
    string public name;
    string public domain;
    address public owner;
    Registry public registry;

    mapping(uint => VerifyRequest) requests;
    uint public nextReqIdx; // different from request ID!

    constructor(
        Registry _registry,
        string memory _name,
        string memory _domain
    ) {
        registry = _registry;
        name = _name;
        domain = _domain;
        owner = msg.sender;
        nextReqIdx = 0;
    }

    function setId(uint _id) public {
        require(msg.sender == address(registry));
        id = _id;
    }

    function addReq(VerifyRequest req) public {
        require(
            msg.sender == address(registry) || msg.sender == address(owner)
        );
        requests[nextReqIdx] = req;
        nextReqIdx++;
    }

    function getReqByIdx(uint idx) public view returns (VerifyRequest) {
        require(
            msg.sender == address(registry) || msg.sender == address(owner)
        );
        return requests[idx];
    }

    function getVerifyReqs() public view returns (VerifyRequest[] memory) {
        require(
            msg.sender == address(registry) || msg.sender == address(owner)
        );
        VerifyRequest[] memory reqs = new VerifyRequest[](nextReqIdx);
        for (uint i = 0; i < nextReqIdx; i++) {
            reqs[i] = requests[i];
        }
        return reqs;
    }
}

// The Registry records all issuing bodies
contract Registry {
    address public owner;

    // Owner address to issuing body
    mapping(address => IssuingBody) ibByCreator;
    mapping(uint => IssuingBody) ibById;
    uint nextIbId;

    mapping(address => Verifier) verifierByCreator;
    mapping(uint => Verifier) verifierById;
    uint nextVerifierId;

    mapping(uint => VerifyRequest) requests;
    uint nextReqId;

    constructor() {
        owner = msg.sender;
        nextIbId = 1;
        nextVerifierId = 1;
        nextReqId = 1;
    }

    // === ISSUING BODY ===

    function registerIssuingBody(
        IssuingBody body
    ) public returns (IssuingBody) {
        require(address(ibByCreator[msg.sender]) == address(0));
        body.setId(nextIbId);
        ibByCreator[msg.sender] = body;
        ibById[nextIbId] = body;
        nextIbId++;
        return body;
    }

    function getIssuingBody() public view returns (IssuingBody) {
        return ibByCreator[msg.sender];
    }

    function getIssuingBodyById(uint ibId) public view returns (IssuingBody) {
        return ibById[ibId];
    }

    function getCredentials() public view returns (Credential[] memory) {
        IssuingBody ib = ibByCreator[msg.sender];
        require(ib.id() != 0, "Registered issuing body expected.");

        uint nextId = ib.nextId();
        Credential[] memory creds = new Credential[](nextId - 1);
        for (uint i = 1; i < ib.nextId(); i++) {
            creds[i - 1] = ib.getCredentialById(i);
        }
        return creds;
    }

    // === CREDENTIAL OWNER ===

    function getOwnerVerifyReqs(
        CredentialGrant grant
    ) public view returns (VerifyRequest[] memory) {
        require(msg.sender == grant.grantee());

        uint size = grant.getNumReqs();

        uint[] memory reqIds = new uint[](size - 1);
        uint node = 0;
        uint idx = 0;
        while (true) {
            (bool nodeExists, uint value) = grant.getNextReq(node);
            if (!nodeExists) break;
            reqIds[idx] = value;
        }

        // uint[] memory reqIds = grant.getReqIds();
        VerifyRequest[] memory reqs = new VerifyRequest[](reqIds.length);
        for (uint i = 0; i < reqIds.length; i++) {
            reqs[i] = requests[reqIds[i]];
        }
        return reqs;
    }

    function getOwnerVerifyReqById(
        uint id
    ) public view returns (VerifyRequest) {
        VerifyRequest req = requests[id];
        require(req.credGrant().grantee() == msg.sender);
        return req;
    }

    function approveVerifyReq(uint id) public returns (bool) {
        VerifyRequest req = requests[id];
        require(req.credGrant().grantee() == msg.sender);
        req.setStatus(VerifyRequestStatus.APPROVED);
        req.credGrant().removeReqId(id);
        return true;
    }

    function rejectVerifyReq(uint id) public returns (bool) {
        VerifyRequest req = requests[id];
        require(req.credGrant().grantee() == msg.sender);
        req.setStatus(VerifyRequestStatus.REJECTED);
        req.credGrant().removeReqId(id);
        return true;
    }

    // === VERIFIER ===

    function registerVerifier(Verifier verifier) public returns (Verifier) {
        require(address(verifierByCreator[msg.sender]) == address(0));
        require(verifier.registry() == this);
        verifier.setId(nextVerifierId);
        verifierByCreator[msg.sender] = verifier;
        verifierById[nextVerifierId] = verifier;
        nextVerifierId++;
        return verifier;
    }

    function getVerifierByCreator() public view returns (Verifier) {
        return verifierByCreator[msg.sender];
    }

    function sendVerifyReq(
        CredentialGrant credGrant,
        VerifyRequest req
    ) public returns (uint) {
        Verifier verifier = verifierByCreator[msg.sender];
        require(verifier.id() != 0);
        // VerifyRequest req = new VerifyRequest(nextReqId, verifier, credGrant);
        req.setId(nextReqId);
        credGrant.addReqId(nextReqId);
        nextReqId++;
        requests[req.id()] = req;
        verifier.addReq(req);
        return req.id();
    }

    function getVerifierVerifyReqs()
        public
        view
        returns (VerifyRequest[] memory)
    {
        Verifier verifier = verifierByCreator[msg.sender];
        require(verifier.id() != 0);

        uint nextReqIdx = verifier.nextReqIdx();
        VerifyRequest[] memory reqs = new VerifyRequest[](nextReqIdx);
        for (uint i = 0; i < nextReqIdx; i++) {
            reqs[i] = verifier.getReqByIdx(i);
        }
        return reqs;
    }
}
