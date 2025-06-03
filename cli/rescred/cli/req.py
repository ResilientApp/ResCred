import click
from rescred.contract import ContractClient
from rescred.registry import (
    Credential,
    CredentialGrant,
    IssuingBody,
    Registry,
    VerifyRequest,
)


@click.group(help="Grantee verification request creation and management")
@click.pass_context
@click.option("-I", "--issuer-id", "issuer_id", type=int, help="Issuer ID")
@click.option("-A", "--issuer-addr", "issuer_addr", help="Issuer address")
@click.option("-i", "--cred-id", "cred_id", type=int, help="Credential ID")
@click.option("-a", "--cred-address", "cred_addr", help="Credential address")
def req(
    ctx: click.Context, cred_id: int, cred_addr: str, issuer_id: int, issuer_addr: str
):
    client: ContractClient = ctx.obj["client"]
    ctx.obj["cred_id"] = cred_id
    ctx.obj["cred_addr"] = cred_addr

    def get_cred(sender: str):
        if not cred_id and not cred_addr:
            raise RuntimeError("expected one of credential ID or address")
        if cred_addr:
            return Credential(client, cred_addr)
        if not issuer_id and not issuer_addr:
            raise RuntimeError("expected one of credential ID or address")
        ib = (
            IssuingBody(client, issuer_addr)
            if issuer_addr
            else Registry(client).get_issuing_body_by_id(sender, issuer_id)
        )
        return ib.get_credential_by_id(sender, cred_id)

    ctx.obj["get_cred"] = get_cred


@click.command(help="List a verification request or all requests under a grant")
@click.pass_context
@click.option("-s", "--sender", "sender", required=True, help="Sender address")
@click.option("-I", "--grant-id", "grant_id", type=int, help="Grantee ID")
@click.option("-A", "--grant-address", "grant_addr", help="Grantee address")
@click.option("-i", "--id", "req_id", type=int, help="Request ID")
@click.option("-a", "--address", "req_addr", help="Request address")
@click.option("-j", "--json", "use_json", is_flag=True, help="Output JSON")
def req_list(
    ctx: click.Context,
    sender: str,
    grant_id: int,
    grant_addr: str,
    req_id: int,
    req_addr: str,
    use_json: bool,
):
    client: ContractClient = ctx.obj["client"]

    if req_addr:
        print(VerifyRequest(client, req_addr).display(sender, use_json=use_json))
        return
    if req_id:
        req = Registry(client).get_owner_verify_req_by_id(sender, req_id)
        print(req.display(sender, use_json=use_json))
        return

    if not grant_id and not grant_addr:
        raise RuntimeError("expected one of grant ID or address")

    if grant_addr:
        grant = CredentialGrant(client, grant_addr)
    else:
        get_cred = ctx.obj["get_cred"]
        cred: Credential = get_cred(sender)
        grant = cred.get_grant_by_id(sender, grant_id)

    for i in grant.req_ids(sender):
        req = Registry(client).get_owner_verify_req_by_id(sender, i)
        print(req.display(sender, use_json=use_json))


@click.command("Approve a verification request")
@click.pass_context
@click.option("-s", "--sender", "sender", required=True, help="Sender address")
@click.option("-i", "--id", "req_id", type=int, help="Request ID")
@click.option("-a", "--address", "req_addr", help="Request address")
def req_approve(
    ctx: click.Context,
    sender: str,
    req_id: int,
    req_addr: str,
):
    client: ContractClient = ctx.obj["client"]
    if not req_id and not req_addr:
        raise RuntimeError("expected one of request ID and address")
    if not req_id:
        req_id = VerifyRequest(client, req_addr).id(sender)

    if Registry(client).approve_verify_req(sender, req_id):
        click.secho("Approved", fg="green")
    else:
        click.secho("Failed to approve", fg="yellow")


@click.command(help="Reject a verification request")
@click.pass_context
@click.option("-s", "--sender", "sender", required=True, help="Sender address")
@click.option("-i", "--id", "req_id", type=int, help="Request ID")
@click.option("-a", "--address", "req_addr", help="Request address")
def req_reject(
    ctx: click.Context,
    sender: str,
    req_id: int,
    req_addr: str,
):
    client: ContractClient = ctx.obj["client"]
    if not req_id and not req_addr:
        raise RuntimeError("expected one of request ID and address")
    if not req_id:
        req_id = VerifyRequest(client, req_addr).id(sender)

    try:
        Registry(client).reject_verify_req(sender, req_id)
        click.secho("Rejected", fg="red")
    except RuntimeError:
        click.secho("Failed to reject", fg="yellow")


req.add_command(req_list, "list")
req.add_command(req_approve, "approve")
req.add_command(req_reject, "reject")
