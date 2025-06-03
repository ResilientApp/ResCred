import json
import click
from datetime import datetime
from enum import IntEnum, auto

from rescred.contract import ContractClient


class Registry:
    def __init__(self, client: ContractClient):
        self.client = client
        self.addr = client.registry_addr

    @staticmethod
    def deploy(client: ContractClient, sender: str):
        client.registry_addr = client.deploy("Registry", sender)
        return Registry(client)

    def __eq__(self, value: object) -> bool:
        if type(value) == type(self):
            return self.addr == value.addr
        elif type(value) == str:
            return self.addr == value
        else:
            return False

    def owner(self, sender: str) -> str:
        return self.client.exec_addr(sender, self.addr, "owner()")

    def next_ib_id(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "nextIbId()")

    def next_verifier_id(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "nextVerifierId()")

    def next_req_id(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "nextReqId()")

    def register_issuing_body(self, sender: str, body: str) -> int:
        return self.client.exec_int(
            sender, self.addr, "registerIssuingBody(address)", body
        )

    def get_issuing_body(self, sender: str) -> "IssuingBody":
        addr = self.client.exec_addr(sender, self.addr, "getIssuingBody()")
        return IssuingBody(self.client, addr)

    def get_issuing_body_by_id(self, sender: str, id: int) -> "IssuingBody":
        addr = self.client.exec_addr(
            sender, self.addr, "getIssuingBodyById(uint256)", id
        )
        return IssuingBody(self.client, addr)

    def get_owner_verify_req_by_id(self, sender: str, req_id: int) -> "VerifyRequest":
        addr = self.client.exec_addr(
            sender, self.addr, "getOwnerVerifyReqById(uint256)", req_id
        )
        return VerifyRequest(self.client, addr)

    def approve_verify_req(self, sender: str, req_id: int) -> bool:
        return self.client.exec_bool(
            sender, self.addr, "approveVerifyReq(uint256)", req_id
        )

    def reject_verify_req(self, sender: str, req_id: int) -> bool:
        return self.client.exec_bool(
            sender, self.addr, "rejectVerifyReq(uint256)", req_id
        )

    def register_verifier(self, sender: str, verifier: str) -> int:
        return self.client.exec_int(
            sender, self.addr, "registerVerifier(address)", verifier
        )

    def get_verifier_by_creator(self, sender: str) -> "Verifier":
        addr = self.client.exec_addr(sender, self.addr, "getVerifierByCreator()")
        return Verifier(self.client, addr)

    def send_verify_req(self, sender: str, cred_grant: str, verify_req: str) -> int:
        return self.client.exec_int(
            sender, self.addr, "sendVerifyReq(address,address)", cred_grant, verify_req
        )

    def get_verifier_verify_req(self, sender: str, id: int) -> "VerifyRequest":
        addr = self.client.exec_addr(
            sender, self.addr, "getVerifierVerifyReq(uint256)", id
        )
        return VerifyRequest(self.client, addr)


class IssuingBody:
    def __init__(self, client: ContractClient, addr: str):
        self.client = client
        self.addr = addr

    def __eq__(self, value: object) -> bool:
        if type(value) == type(self):
            return self.addr == value.addr
        elif type(value) == str:
            return self.addr == value
        else:
            return False

    @staticmethod
    def deploy(
        client: ContractClient, sender: str, name: str, domain: str
    ) -> "IssuingBody":
        ib = client.deploy("IssuingBody", sender, client.registry_addr, name, domain)
        return IssuingBody(client, ib)

    def _data(self, sender: str):
        return {
            "id": self.id(sender),
            "name": self.name(sender),
            "address": self.addr,
            "owner": self.owner(sender),
            "domain": self.domain(sender),
        }

    def display(self, sender: str, *, use_json=False) -> str:
        data = self._data(sender)
        if use_json:
            return json.dumps(data)
        out = f"Issuing Body #{data['id']}: {data['name']}\n"
        out += f"    Address: {self.addr}\n"
        out += f"    Owner: {data['owner']}\n"
        out += f"    Domain: {data['domain']}"
        return out

    def registry(self, sender: str) -> Registry:
        addr = self.client.exec_addr(sender, self.addr, "registry()")
        if addr != self.client.registry_addr:
            raise RuntimeError("mismatched registry address")
        return Registry(self.client)

    def id(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "id()")

    def next_id(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "nextId()")

    def name(self, sender: str) -> str:
        return self.client.exec_str(sender, self.addr, "name()")

    def domain(self, sender: str) -> str:
        return self.client.exec_str(sender, self.addr, "domain()")

    def owner(self, sender: str) -> str:
        return self.client.exec_addr(sender, self.addr, "owner()")

    def add_credential(self, sender: str, cred: str) -> int:
        return self.client.exec_int(sender, self.addr, "addCredential(address)", cred)

    def get_credential_by_id(self, sender: str, cred_id: int) -> "Credential":
        addr = self.client.exec_addr(
            sender, self.addr, "getCredentialById(uint256)", cred_id
        )
        return Credential(self.client, addr)


class CredentialGrant:
    def __init__(self, client: ContractClient, addr: str):
        self.client = client
        self.addr = addr

    def __eq__(self, value: object) -> bool:
        if type(value) == type(self):
            return self.addr == value.addr
        elif type(value) == str:
            return self.addr == value
        else:
            return False

    @staticmethod
    def deploy(
        client: ContractClient,
        sender: str,
        credential: str,
        grantee: str,
        name: str,
        expiry: datetime,
    ) -> "CredentialGrant":
        addr = client.deploy(
            "CredentialGrant", sender, credential, grantee, name, expiry
        )
        return CredentialGrant(client, addr)

    def _dump(self, sender: str):
        return {
            "id": self.id(sender),
            "name": self.name(sender),
            "expiry": int(self.expiry(sender).timestamp()),
            "address": self.addr,
            "grantee": self.grantee(sender),
            "credential": self.credential(sender).addr,
            "issuer": self.issuing_body(sender).addr,
        }

    def display(self, sender: str, *, use_json=False):
        data = self._dump(sender)
        if use_json:
            return json.dumps(data)
        out = f"Grantee #{data['id']}: {data['name']}"
        expiry = data["expiry"]
        if expiry != 0:
            expiry = datetime.fromtimestamp(expiry)
            out += f" (valid until {expiry.strftime('%Y-%m-%d')})"
        out += "\n"
        out += f"    Address: {self.addr}\n"
        out += f"    Grantee Address: {data['grantee']}\n"
        out += f"    Credential: {data['credential']}\n"
        out += f"    Issuer: {data['issuer']}"
        return out

    def id(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "id()")

    def grantee(self, sender: str) -> str:
        return self.client.exec_addr(sender, self.addr, "grantee()")

    def name(self, sender: str) -> str:
        return self.client.exec_str(sender, self.addr, "name()")

    def expiry(self, sender: str) -> datetime:
        return self.client.exec_datetime(sender, self.addr, "expiry()")

    def registry(self, sender: str) -> Registry:
        addr = self.client.exec_addr(sender, self.addr, "registry()")
        if addr != self.client.registry_addr:
            raise RuntimeError("mismatched registry address")
        return Registry(self.client)

    def issuing_body(self, sender: str) -> IssuingBody:
        addr = self.client.exec_addr(sender, self.addr, "issuingBody()")
        return IssuingBody(self.client, addr)

    def credential(self, sender: str) -> "Credential":
        addr = self.client.exec_addr(sender, self.addr, "credential()")
        return Credential(self.client, addr)

    def get_num_reqs(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "getNumReqs()")

    def has_req(self, sender: str) -> bool:
        return self.client.exec_bool(sender, self.addr, "hasReq")

    def get_req(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "getReq()")

    def get_next_req(self, sender: str, node: int) -> int:
        return self.client.exec_int(sender, self.addr, "getNextReq(uint256)", node)

    # def add_req_id(self, sender: str, req_id: int) -> bool:
    #     return self.client.exec_bool(sender, self.addr, "addReqId(uint256)", req_id)

    # def remove_req_id(self, sender: str, req_id: int) -> bool:
    #     return self.client.exec_bool(sender, self.addr, "removeReqId(uint256)", req_id)

    def req_ids(self, sender: str):
        num_ids = self.get_num_reqs(sender)
        if num_ids == 0:
            return
        node = 0
        for _ in range(num_ids):
            node = self.get_next_req(sender, node)
            if node:
                yield node
            else:
                return

    def all_req_ids(self, sender: str):
        return list(self.req_ids(sender))


class Credential:
    def __init__(self, client: ContractClient, addr: str):
        self.client = client
        self.addr = addr

    def __eq__(self, value: object) -> bool:
        if type(value) == type(self):
            return self.addr == value.addr
        elif type(value) == str:
            return self.addr == value
        else:
            return False

    def _dump(self, sender: str):
        return {
            "id": self.id(sender),
            "name": self.name(sender),
            "expiry": self.expiry(sender),
            "address": self.addr,
            "issuer": self.issuing_body(sender).addr,
        }

    def display(self, sender: str, *, use_json=False) -> str:
        data = self._dump(sender)
        if use_json:
            return json.dumps(data)
        e = int(self.expiry(sender) // 86400)
        out = f"Credential #{data['id']}: {data['name']}"
        if e != 0:
            out += f" (valid for {e} days)"
        out += "\n"
        out += f"    Address: {self.addr}\n"
        out += f"    Issuer: {data['issuer']}"
        return out

    @staticmethod
    def deploy(
        client: ContractClient,
        sender: str,
        issuing_body: str,
        name: str,
        expiry: datetime,
    ) -> "Credential":
        addr = client.deploy("Credential", sender, issuing_body, name, expiry)
        return Credential(client, addr)

    def id(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "id()")

    def name(self, sender: str) -> str:
        return self.client.exec_str(sender, self.addr, "name()")

    def expiry(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "expiry()")

    def registry(self, sender: str) -> Registry:
        addr = self.client.exec_addr(sender, self.addr, "registry()")
        if addr != self.client.registry_addr:
            raise RuntimeError("mismatched registry address")
        return Registry(self.client)

    def issuing_body(self, sender: str) -> IssuingBody:
        addr = self.client.exec_addr(sender, self.addr, "issuingBody()")
        return IssuingBody(self.client, addr)

    def next_grant_id(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "nextGrantId()")

    def get_grant_by_id(self, sender: str, grant_id: int) -> CredentialGrant:
        addr = self.client.exec_addr(
            sender, self.addr, "getGrantById(uint256)", grant_id
        )
        return CredentialGrant(self.client, addr)

    def get_my_grant(self, sender: str) -> CredentialGrant:
        addr = self.client.exec_addr(sender, self.addr, "getMyGrant()")
        return CredentialGrant(self.client, addr)

    def add_grant(self, sender: str, cred_grant: str) -> int:
        return self.client.exec_int(sender, self.addr, "addGrant(address)", cred_grant)

    def grantees(self, sender: str) -> "list[CredentialGrant]":
        max_id = self.next_grant_id(sender)
        grants: list[CredentialGrant] = []
        for cgid in range(1, max_id):
            grants.append(self.get_grant_by_id(sender, cgid))
        return grants


class VerifyRequestStatus(IntEnum):
    PENDING = 0
    APPROVED = auto()
    REJECTED = auto()


class VerifyRequest:
    def __init__(self, client: ContractClient, addr: str):
        self.client = client
        self.addr = addr

    def __eq__(self, value: object) -> bool:
        if type(value) == type(self):
            return self.addr == value.addr
        elif type(value) == str:
            return self.addr == value
        else:
            return False

    @staticmethod
    def deploy(
        client: ContractClient,
        sender: str,
        verifier: str,
        cred_grant: str,
    ) -> "VerifyRequest":
        addr = client.deploy("VerifyRequest", sender, verifier, cred_grant)
        return VerifyRequest(client, addr)

    def _dump(self, sender: str):
        return {
            "id": self.id(sender),
            "address": self.addr,
            "cred_grant": self.cred_grant(sender).addr,
            "verifier": self.verifier(sender).addr,
            "status": self.status(sender).value,
        }

    def display(self, sender: str, *, use_json=False):
        data = self._dump(sender)
        if use_json:
            return json.dumps(data)
        status = self.status(sender).name.lower()
        match status:
            case "approved":
                status = click.style(status, fg="green")
            case "pending":
                status = click.style(status, fg="yellow")
            case "rejected":
                status = click.style(status, fg="red")
        out = f"Verify Request #{data['id']} ({status})\n"
        out += f"    Address: {data['address']}\n"
        out += f"    Credential Grant: {data['cred_grant']}\n"
        out += f"    Verifier: {data['verifier']}"
        return out

    def id(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "id()")

    def registry(self, sender: str) -> Registry:
        addr = self.client.exec_addr(sender, self.addr, "registry()")
        if addr != self.client.registry_addr:
            raise RuntimeError("mismatched registry address")
        return Registry(self.client)

    def verifier(self, sender: str) -> "Verifier":
        addr = self.client.exec_addr(sender, self.addr, "verifier()")
        return Verifier(self.client, addr)

    def cred_grant(self, sender: str) -> CredentialGrant:
        addr = self.client.exec_addr(sender, self.addr, "credGrant()")
        return CredentialGrant(self.client, addr)

    def status(self, sender: str) -> VerifyRequestStatus:
        status = self.client.exec_int(sender, self.addr, "status()")
        return VerifyRequestStatus(status)


class Verifier:
    def __init__(self, client: ContractClient, addr: str):
        self.client = client
        self.addr = addr

    def __eq__(self, value: object) -> bool:
        if type(value) == type(self):
            return self.addr == value.addr
        elif type(value) == str:
            return self.addr == value
        else:
            return False

    @staticmethod
    def deploy(
        client: ContractClient,
        sender: str,
        registry: str,
        name: str,
        domain: str,
    ) -> "Verifier":
        addr = client.deploy("Verifier", sender, registry, name, domain)
        return Verifier(client, addr)

    def _dump(self, sender: str):
        return {
            "id": self.id(sender),
            "address": self.addr,
            "name": self.name(sender),
            "domain": self.domain(sender),
            "owner": self.owner(sender),
        }

    def display(self, sender: str, *, use_json=False):
        data = self._dump(sender)
        if use_json:
            return json.dumps(data)
        out = f"Verifier #{data['id']}: {data['name']}\n"
        out += f"    Address: {data['address']}"
        out += f"    Domain: {data['domain']}\n"
        out += f"    Owner: {data['owner']}"
        return out

    def id(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "id()")

    def name(self, sender: str) -> str:
        return self.client.exec_str(sender, self.addr, "name()")

    def domain(self, sender: str) -> str:
        return self.client.exec_str(sender, self.addr, "domain()")

    def owner(self, sender: str) -> str:
        return self.client.exec_addr(sender, self.addr, "owner()")

    def next_req_idx(self, sender: str) -> int:
        return self.client.exec_int(sender, self.addr, "nextReqIdx()")

    def get_req_by_idx(self, sender: str, id: int) -> VerifyRequest:
        addr = self.client.exec_addr(sender, self.addr, "getReqByIdx(uint256)", id)
        return VerifyRequest(self.client, addr)

    def reqs(self, sender: str) -> list[VerifyRequest]:
        max_id = self.next_req_idx(sender)
        rs: list[VerifyRequest] = []
        for i in range(1, max_id):
            rs.append(self.get_req_by_idx(sender, i))
        return rs
