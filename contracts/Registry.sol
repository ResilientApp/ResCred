// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {StructuredLinkedList} from "../node_modules/solidity-linked-list/contracts/StructuredLinkedList.sol";

contract IssuingBody {
    address public registry;
    uint public id;

    string public name;
    string public domain;
    address public owner;

    uint public nextId;
    mapping(uint => Credential) credentials;

    constructor(
        string memory _name,
        uint _id,
        string memory _domain,
        address _owner
    ) {
        registry = msg.sender;
        id = _id;

        name = _name;
        domain = _domain;
        // Can't use msg.sender since Registry contract is the caller
        owner = _owner;
        nextId = 1;
    }

    function addCredential(Credential cred) public returns (uint) {
        require(msg.sender == registry, "Expected caller to be Registry");
        credentials[nextId] = cred;
        uint credId = nextId;
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

    address public registry;
    address public issuingBody;
    address public credential;

    constructor(
        uint _id,
        address _grantee,
        string memory _name,
        uint _expiry,
        Registry _registry,
        IssuingBody _issuingBody,
        Credential _credential
    ) {
        require(
            msg.sender == address(_credential),
            "Credential grant must be created by Credential"
        );
        id = _id;
        grantee = _grantee;
        name = _name;
        expiry = _expiry;
        registry = address(_registry);
        issuingBody = address(_issuingBody);
        credential = address(_credential);
        pendingRequests.pushFront(0);
    }

    function getReqIds() public view returns (uint[] memory) {
        require(msg.sender == grantee);
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
        require(msg.sender == registry);
        return pendingRequests.sizeOf();
    }

    function getNextReq(uint node) public view returns (bool, uint) {
        require(msg.sender == registry);
        return pendingRequests.getNextNode(node);
    }

    function addReqId(uint reqId) public {
        require(msg.sender == registry);
        pendingRequests.pushBack(reqId);
    }

    function removeReqId(uint reqId) public {
        require(msg.sender == registry);
        pendingRequests.remove(reqId);
    }
}

contract Credential {
    struct HolderMetadata {
        bool granted;
        uint256 expiry; // 0 for never expire
        mapping(address => bool) requests;
    }

    uint public id;
    string public name;
    uint256 public verifyTimeout;
    uint256 public expiry;
    address public registry;
    address public issuingBody;

    uint public nextGrantId;

    mapping(address => CredentialGrant) grantByOwner; // holder address lookup
    mapping(uint => CredentialGrant) grantById; //

    // Set _expiry to 0 for never expire
    constructor(
        string memory _name,
        uint _id,
        Registry _registry,
        IssuingBody _body,
        uint256 _expiry
    ) {
        name = _name;
        issuingBody = address(_body);
        registry = address(_registry);
        expiry = _expiry;
        id = _id;
        nextGrantId = 1;
    }

    function getCredGrants() public view returns (CredentialGrant[] memory) {
        CredentialGrant[] memory creds = new CredentialGrant[](nextGrantId - 1);
        for (uint i = 1; i < nextGrantId; i++) {
            creds[i - 1] = grantById[i];
        }
        return creds;
    }

    function addGrant(CredentialGrant credGrant) private returns (uint) {
        grantByOwner[credGrant.grantee()] = credGrant;
        grantById[nextGrantId] = credGrant;
        uint grantId = nextGrantId;
        nextGrantId++;
        return grantId;
    }

    function grant(
        address grantee,
        string calldata granteeName
    ) public returns (bool) {
        if (msg.sender != registry) return false;
        uint credExpiry = 0;
        if (expiry != 0) credExpiry = block.timestamp + expiry;
        CredentialGrant credGrant = new CredentialGrant(
            nextGrantId,
            grantee,
            granteeName,
            credExpiry,
            Registry(registry),
            IssuingBody(issuingBody),
            this
        );
        addGrant(credGrant);
        return true;
    }
}

enum VerifyRequestStatus {
    PENDING, // 0
    APPROVED, // 1
    REJECTED // 2
}

contract VerifyRequest {
    uint public id;
    Verifier public verifier;
    CredentialGrant public credGrant;
    VerifyRequestStatus public status;

    constructor(uint _id, Verifier _verifier, CredentialGrant _credGrant) {
        require(msg.sender == _verifier.registry());
        id = _id;
        verifier = _verifier;
        credGrant = _credGrant;
        status = VerifyRequestStatus.PENDING;
    }

    function setStatus(VerifyRequestStatus _status) public returns (bool) {
        require(msg.sender == verifier.registry());
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
    address public registry;

    mapping(uint => VerifyRequest) requests;
    uint public nextReqIdx; // different from request ID!

    constructor(
        uint _id,
        string memory _name,
        string memory _domain,
        address _owner
    ) {
        id = _id;
        name = _name;
        domain = _domain;
        owner = _owner;
        registry = msg.sender;
        nextReqIdx = 0;
    }

    function addReq(VerifyRequest req) public {
        require(msg.sender == registry);
        requests[nextReqIdx] = req;
        nextReqIdx++;
    }

    function getReqByIdx(uint idx) public view returns (VerifyRequest) {
        require(msg.sender == registry);
        return requests[idx];
    }

    function getVerifyReqs() public view returns (VerifyRequest[] memory) {
        require(msg.sender == registry);

        VerifyRequest[] memory reqs = new VerifyRequest[](nextReqIdx);
        for (uint i = 0; i < nextReqIdx; i++) {
            reqs[i] = requests[i];
        }
        return reqs;
    }
}

// The Registry records all issuing bodies
contract Registry {
    address owner;

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
        string calldata name,
        string calldata domain
    ) public returns (IssuingBody) {
        require(address(ibByCreator[msg.sender]) == address(0));
        IssuingBody body = new IssuingBody(name, nextIbId, domain, msg.sender);
        ibByCreator[msg.sender] = body;
        ibById[nextIbId] = body;
        nextIbId++;
        return body;
    }

    function createCredential(
        string calldata name,
        uint expiry
    ) public returns (Credential) {
        require(
            ibByCreator[msg.sender].id() != 0,
            "Registered issuing body expected."
        );
        Credential cred = new Credential(
            name,
            nextIbId,
            this,
            ibByCreator[msg.sender],
            expiry
        );
        ibByCreator[msg.sender].addCredential(cred);
        return cred;
    }

    function getIssuingBody() public view returns (IssuingBody) {
        return ibByCreator[msg.sender];
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

    function grantCredential(
        Credential cred,
        address grantee,
        string calldata granteeName
    ) public returns (bool) {
        require(
            ibByCreator[msg.sender].id() != 0,
            "Registered issuing body expected."
        );
        require(address(this) == cred.registry());
        require(address(ibByCreator[msg.sender]) == cred.issuingBody());
        return cred.grant(grantee, granteeName);
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

    function registerVerifier(
        string calldata name,
        string calldata domain
    ) public returns (Verifier) {
        require(address(verifierByCreator[msg.sender]) == address(0));
        Verifier verifier = new Verifier(nextIbId, name, domain, msg.sender);
        verifierByCreator[msg.sender] = verifier;
        verifierById[nextVerifierId] = verifier;
        nextVerifierId++;
        return verifier;
    }

    function sendVerifyReq(
        CredentialGrant credGrant
    ) public returns (VerifyRequest) {
        Verifier verifier = verifierByCreator[msg.sender];
        require(verifier.id() != 0);
        VerifyRequest req = new VerifyRequest(nextReqId, verifier, credGrant);
        credGrant.addReqId(nextReqId);
        nextReqId++;
        requests[req.id()] = req;
        verifier.addReq(req);
        return req;
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
