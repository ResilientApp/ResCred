// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {StructuredLinkedList} from "../node_modules/solidity-linked-list/contracts/StructuredLinkedList.sol";

// Some dumb workarounds are needed to circumvent eEVM quirks
// (Don't be grossed out by assertEq, assertTrue, etc)

contract IssuingBody {
    Registry public registry;
    uint public id;

    uint public name;
    uint public domain;
    address public owner;

    uint public nextId;
    mapping(uint => Credential) credentials;

    constructor(Registry _registry, uint _name, uint _domain) {
        registry = _registry;
        id = 0;
        name = _name;
        domain = _domain;
        owner = msg.sender;
        nextId = 1;
    }

    function setId(uint _id) public returns (uint) {
        assertEq(address(registry), msg.sender);
        id = _id;
        return id;
    }

    function assertEq(address a, address b) public pure {
        require(a == b);
    }

    function addCredential(Credential cred) public returns (uint) {
        assertEq(msg.sender, owner);
        assertEq(address(cred.issuingBody()), address(this));
        credentials[nextId] = cred;
        uint credId = nextId;
        cred.setId(nextId);
        nextId++;
        return credId;
    }

    function getCredentialById(uint credId) public view returns (Credential) {
        return credentials[credId];
    }

    // function getCredentials() public view returns (Credential[] memory) {
    //     Credential[] memory creds = new Credential[](nextId - 1);
    //     for (uint i = 1; i < nextId; i++) {
    //         creds[i - 1] = getCredentialById(i);
    //     }
    //     return creds;
    // }
}

contract CredentialGrant {
    using StructuredLinkedList for StructuredLinkedList.List;
    StructuredLinkedList.List pendingRequests;

    uint public id;
    address public grantee;
    uint public name;
    uint public expiry;

    Registry public registry;
    IssuingBody public issuingBody;
    Credential public credential;

    constructor(
        Credential _credential,
        address _grantee,
        uint _name,
        uint _expiry
    ) {
        credential = _credential;
        issuingBody = _credential.issuingBody();
        registry = issuingBody.registry();
        assertEq(msg.sender, issuingBody.owner());
        grantee = _grantee;
        name = _name;
        expiry = _expiry;
        pendingRequests.pushFront(0);
    }

    function assertEq(address a, address b) public pure {
        require(a == b);
    }

    function setId(uint _id) public {
        assertEq(msg.sender, address(credential));
        id = _id;
    }

    function checkPerms(address sender) private view {
        require(
            sender == address(registry) ||
                sender == address(issuingBody) ||
                sender == issuingBody.owner() ||
                sender == address(credential) ||
                sender == grantee
        );
    }

    // function getReqIds() public view returns (uint[] memory) {
    //     checkPerms();
    //     uint size = pendingRequests.sizeOf();

    //     uint[] memory reqIds = new uint[](size - 1);
    //     uint node = 0;
    //     uint idx = 0;
    //     while (true) {
    //         (bool nodeExists, uint value) = pendingRequests.getNextNode(node);
    //         if (!nodeExists) break;
    //         reqIds[idx] = value;
    //     }
    //     return reqIds;
    // }

    function getNumReqs() public returns (uint) {
        checkPerms(msg.sender);
        uint s = pendingRequests.sizeOf();
        return s;
    }

    function hasReq() public view returns (bool) {
        checkPerms(msg.sender);
        return pendingRequests.sizeOf() > 0;
    }

    function getReq() public view returns (uint) {
        checkPerms(msg.sender);
        (bool exists, uint value) = pendingRequests.getNextNode(0);
        return value;
    }

    function getNextReq(uint node) public view returns (uint) {
        checkPerms(msg.sender);
        (bool exists, uint value) = pendingRequests.getNextNode(node);
        return value;
    }

    function addReqId(uint reqId) public returns (bool) {
        checkPerms(msg.sender);
        pendingRequests.pushBack(reqId);
        return true;
    }

    function removeReqId(uint reqId) public returns (bool) {
        checkPerms(msg.sender);
        pendingRequests.remove(reqId);
        return true;
    }
}

contract Credential {
    uint public id;
    uint public name;
    uint public expiry;
    Registry public registry;
    IssuingBody public issuingBody;

    uint public nextGrantId;

    mapping(address => CredentialGrant) grantByOwner; // holder address lookup
    mapping(uint => CredentialGrant) grantById; //

    // Set _expiry to 0 for never expire
    constructor(IssuingBody _body, uint _name, uint256 _expiry) {
        name = _name;
        issuingBody = _body;
        registry = _body.registry();
        expiry = _expiry;
        nextGrantId = 1;
    }

    function assertEq(address a, address b) public pure {
        require(a == b);
    }

    function setId(uint _id) public {
        assertEq(msg.sender, address(issuingBody));
        id = _id;
    }

    // function getCredGrants() public view returns (CredentialGrant[] memory) {
    //     CredentialGrant[] memory creds = new CredentialGrant[](nextGrantId - 1);
    //     for (uint i = 1; i < nextGrantId; i++) {
    //         creds[i - 1] = grantById[i];
    //     }
    //     return creds;
    // }

    function getGrantById(uint _id) public view returns (CredentialGrant) {
        CredentialGrant grant = grantById[_id];
        assertTrue(
            msg.sender == address(issuingBody.owner()) ||
                msg.sender == address(grant.grantee())
        );
        return grant;
    }

    function assertTrue(bool b) public pure {
        require(b);
    }

    function getMyGrant() public view returns (CredentialGrant) {
        return grantByOwner[msg.sender];
    }

    function addGrant(CredentialGrant credGrant) public returns (uint) {
        assertEq(msg.sender, address(issuingBody.owner()));
        uint grantId = nextGrantId;
        grantById[grantId] = credGrant;
        grantByOwner[credGrant.grantee()] = credGrant;
        credGrant.setId(grantId);
        nextGrantId++;
        return grantId;
    }
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
        assertEq(msg.sender, _verifier.owner());
        verifier = _verifier;
        credGrant = _credGrant;
        registry = _verifier.registry();
        status = VerifyRequestStatus.PENDING;
    }

    function assertEq(address a, address b) public pure {
        require(a == b);
    }

    function assertStatusEq(
        VerifyRequestStatus a,
        VerifyRequestStatus b
    ) public pure {
        require(a == b);
    }

    function setId(uint _id) public {
        assertEq(msg.sender, address(registry));
        id = _id;
    }

    function setStatus(VerifyRequestStatus _status) public returns (bool) {
        assertEq(msg.sender, address(verifier.registry()));
        assertStatusEq(status, VerifyRequestStatus.PENDING);
        status = _status;
        return true;
    }
}

contract Verifier {
    uint public id;
    uint public name;
    uint public domain;
    address public owner;
    Registry public registry;
    uint public nextReqIdx; // different from request ID!

    mapping(uint => VerifyRequest) requests;

    constructor(Registry _registry, uint _name, uint _domain) {
        id = 0;
        name = _name;
        domain = _domain;
        owner = msg.sender;
        registry = _registry;
        nextReqIdx = 1;
    }

    function assertEq(address a, address b) public pure {
        require(a == b);
    }

    function setId(uint _id) public {
        assertEq(msg.sender, address(registry));
        id = _id;
    }

    function addReq(VerifyRequest req) public returns (uint) {
        assertEq(msg.sender, address(registry));
        uint idx = nextReqIdx;
        requests[idx] = req;
        nextReqIdx++;
        return idx;
    }

    function getReqByIdx(uint idx) public view returns (VerifyRequest) {
        assertEq(msg.sender, address(registry));
        return requests[idx];
    }
}

// The Registry records all issuing bodies
contract Registry {
    address public owner;
    uint public nextIbId;
    uint public nextVerifierId;
    uint public nextReqId;

    // Owner address to issuing body
    mapping(address => IssuingBody) ibByCreator;
    mapping(uint => IssuingBody) ibById;
    mapping(address => Verifier) verifierByCreator;
    mapping(uint => Verifier) verifierById;
    mapping(uint => VerifyRequest) requests;

    constructor() {
        owner = msg.sender;
        nextIbId = 1;
        nextVerifierId = 1;
        nextReqId = 1;
    }

    // === ISSUING BODY ===

    function registerIssuingBody(IssuingBody body) public returns (uint256) {
        assertTrue(address(ibByCreator[msg.sender]) == address(0));
        uint id = nextIbId;
        newIb(body, id);
        nextIbId++;
        return id;
    }

    function newIb(IssuingBody body, uint id) private {
        body.setId(id);
        ibByCreator[msg.sender] = body;
        ibById[id] = body;
    }

    function checkIbDoesNotExist(address sender) public view {
        require(address(ibByCreator[sender]) == address(0));
    }

    function getIssuingBody() public view returns (IssuingBody) {
        return ibByCreator[msg.sender];
    }

    function getIssuingBodyById(uint ibId) public view returns (IssuingBody) {
        return ibById[ibId];
    }

    // function getCredentials() public view returns (Credential[] memory) {
    //     IssuingBody ib = ibByCreator[msg.sender];
    //     assertTrue(ib.id() != 0);

    //     uint nextId = ib.nextId();
    //     Credential[] memory creds = new Credential[](nextId - 1);
    //     for (uint i = 1; i < ib.nextId(); i++) {
    //         creds[i - 1] = ib.getCredentialById(i);
    //     }
    //     return creds;
    // }

    function assertTrue(bool b) public pure {
        require(b);
    }

    // === CREDENTIAL OWNER ===

    // function getOwnerVerifyReqs(
    //     CredentialGrant grant
    // ) public view returns (VerifyRequest[] memory) {
    //     assertTrue(msg.sender == grant.grantee());

    //     uint size = grant.getNumReqs();

    //     uint[] memory reqIds = new uint[](size - 1);
    //     uint node = 0;
    //     uint idx = 0;
    //     while (true) {
    //         (bool nodeExists, uint value) = grant.getNextReq(node);
    //         if (!nodeExists) break;
    //         reqIds[idx] = value;
    //     }

    //     // uint[] memory reqIds = grant.getReqIds();
    //     VerifyRequest[] memory reqs = new VerifyRequest[](reqIds.length);
    //     for (uint i = 0; i < reqIds.length; i++) {
    //         reqs[i] = requests[reqIds[i]];
    //     }
    //     return reqs;
    // }

    function getOwnerVerifyReqById(
        uint id
    ) public view returns (VerifyRequest) {
        VerifyRequest req = requests[id];
        assertTrue(req.credGrant().grantee() == msg.sender);
        return req;
    }

    function approveVerifyReq(uint id) public returns (bool) {
        VerifyRequest req = requests[id];
        assertTrue(req.credGrant().grantee() == msg.sender);
        req.setStatus(VerifyRequestStatus.APPROVED);
        req.credGrant().removeReqId(id);
        return true;
    }

    function rejectVerifyReq(uint id) public returns (bool) {
        VerifyRequest req = requests[id];
        assertTrue(req.credGrant().grantee() == msg.sender);
        req.setStatus(VerifyRequestStatus.REJECTED);
        req.credGrant().removeReqId(id);
        return true;
    }

    // === VERIFIER ===

    function registerVerifier(Verifier verifier) public returns (uint) {
        assertTrue(address(verifierByCreator[msg.sender]) == address(0));
        assertTrue(verifier.registry() == this);
        uint id = nextVerifierId;
        verifier.setId(nextVerifierId);
        verifierByCreator[msg.sender] = verifier;
        verifierById[nextVerifierId] = verifier;
        nextVerifierId++;
        return id;
    }

    function getVerifierByCreator() public view returns (Verifier) {
        return verifierByCreator[msg.sender];
    }

    function sendVerifyReq(
        CredentialGrant credGrant,
        VerifyRequest req
    ) public returns (uint) {
        Verifier verifier = verifierByCreator[msg.sender];
        assertTrue(verifier.id() != 0);
        req.setId(nextReqId);
        credGrant.addReqId(nextReqId);
        nextReqId++;
        requests[req.id()] = req;
        verifier.addReq(req);
        return req.id();
    }

    function getVerifierVerifyReq(uint id) public view returns (VerifyRequest) {
        Verifier verifier = verifierByCreator[msg.sender];
        assertTrue(verifier.id() != 0);
        VerifyRequest req = requests[id];
        assertTrue(req.verifier() == verifier);
        return req;
    }

    // function getVerifierVerifyReqs()
    //     public
    //     view
    //     returns (VerifyRequest[] memory)
    // {
    //     Verifier verifier = verifierByCreator[msg.sender];
    //     assertTrue(verifier.id() != 0);

    //     uint nextReqIdx = verifier.nextReqIdx();
    //     VerifyRequest[] memory reqs = new VerifyRequest[](nextReqIdx);
    //     for (uint i = 0; i < nextReqIdx; i++) {
    //         reqs[i] = verifier.getReqByIdx(i);
    //     }
    //     return reqs;
    // }
}
