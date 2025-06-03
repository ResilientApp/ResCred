from datetime import datetime, timedelta

import click
from rescred.contract import ContractClient
from rescred.registry import (
    Credential,
    CredentialGrant,
    IssuingBody,
)


@click.group(help="Credential creation, issuance, and fetching")
@click.option("-I", "--issuer", "issuer", required=True, help="Issuing body address")
@click.pass_context
def cred(ctx: click.Context, issuer: str):
    ctx.obj["issuer"] = issuer
    client: ContractClient = ctx.obj["client"]
    ctx.obj["issuing_body"] = IssuingBody(client, issuer)


@click.command(help="Create a new credential")
@click.option("-s", "--sender", "sender", required=True, help="Sender address")
@click.option("-n", "--name", "name", required=True, help="Credential name")
@click.option("-j", "--json", "use_json", is_flag=True, help="Output JSON")
@click.option(
    "-e",
    "--expiry",
    "expiry",
    type=int,
    help="Credential expiry in days (default: none)",
    default=0,
)
@click.pass_context
def cred_create(
    ctx: click.Context, sender: str, name: str, expiry: int, use_json: bool
):
    client: ContractClient = ctx.obj["client"]
    ib: IssuingBody = ctx.obj["issuing_body"]
    DAY_IN_SECONDS = 86400
    c = Credential.deploy(
        client, sender, ib.addr, name, datetime.fromtimestamp(expiry * DAY_IN_SECONDS)
    )
    ib.add_credential(sender, c.addr)
    print(c.display(sender, use_json=use_json))


@click.command(help="List credentials")
@click.option("-i", "--id", "cred_id", type=int, help="Credential ID")
@click.option("-a", "--address", "address", help="Credential address")
@click.option("-s", "--sender", "sender", help="Sender address")
@click.option("-j", "--json", "use_json", is_flag=True, help="Output JSON")
@click.pass_context
def cred_list(
    ctx: click.Context, sender: str, cred_id: int, address: str, use_json: bool
):
    client: ContractClient = ctx.obj["client"]
    ib: IssuingBody = ctx.obj["issuing_body"]
    if not sender:
        sender = client.create_account()
    if cred_id:
        print(
            ib.get_credential_by_id(sender, cred_id).display(sender, use_json=use_json)
        )
    elif address:
        print(Credential(client, address).display(sender, use_json=use_json))
    else:
        max_id = ib.next_id(sender)
        for cid in range(1, max_id):
            print(
                ib.get_credential_by_id(sender, cid).display(sender, use_json=use_json)
            )


@click.command(help="Grant credential to existing or new address")
@click.pass_context
@click.option("-s", "--sender", "sender", required=True, help="Sender address")
@click.option("-i", "--id", "cred_id", type=int, help="Credential ID")
@click.option("-a", "--address", "cred_addr", help="Credential address")
@click.option("-g", "--grantee", "grantee_addr", help="Grantee address")
@click.option("-j", "--json", "use_json", is_flag=True, help="Output JSON")
@click.option("-n", "--name", "grantee_name", required=True, help="Grantee name")
def cred_grant(
    ctx: click.Context,
    sender: str,
    cred_id: int,
    cred_addr: str,
    grantee_addr: str,
    grantee_name: str,
    use_json: bool,
):
    client: ContractClient = ctx.obj["client"]
    ib: IssuingBody = ctx.obj["issuing_body"]
    if not cred_id and not cred_addr:
        raise RuntimeError("expected one of credential ID or address")
    cred = (
        Credential(client, cred_addr)
        if cred_addr
        else ib.get_credential_by_id(sender, cred_id)
    )
    cred_expiry = cred.expiry(sender)
    grant_expiry = datetime.fromtimestamp(0)
    if cred_expiry:
        grant_expiry = datetime.now() + timedelta(seconds=cred.expiry(sender))
    if not grantee_addr:
        grantee_addr = client.create_account()
    cred_grant = CredentialGrant.deploy(
        client, sender, cred.addr, grantee_addr, grantee_name, grant_expiry
    )
    cred.add_grant(sender, cred_grant.addr)
    print(cred_grant.display(sender, use_json=use_json))


@click.command(help="List credential grantees")
@click.pass_context
@click.option("-s", "--sender", "sender", required=True, help="Sender address")
@click.option("-I", "--cred-id", "cred_id", type=int, help="Credential ID")
@click.option("-A", "--cred-address", "cred_addr", help="Credential address")
@click.option("-i", "--id", "grant_id", type=int, help="Grantee ID")
@click.option("-a", "--address", "grant_addr", help="Grantee address")
@click.option("-j", "--json", "use_json", is_flag=True, help="Output JSON")
def cred_list_grantee(
    ctx: click.Context,
    sender: str,
    cred_id: int,
    cred_addr: str,
    grant_id: int,
    grant_addr: str,
    use_json: bool,
):
    client: ContractClient = ctx.obj["client"]
    ib: IssuingBody = ctx.obj["issuing_body"]
    if not cred_id and not cred_addr:
        raise RuntimeError("expected one of credential ID or address")
    cred = (
        Credential(client, cred_addr)
        if cred_addr
        else ib.get_credential_by_id(sender, cred_id)
    )
    if grant_id:
        print(cred.get_grant_by_id(sender, grant_id).display(sender, use_json=use_json))
        return
    elif grant_addr:
        print(CredentialGrant(client, grant_addr).display(sender, use_json=use_json))
        return
    for grantee in cred.grantees(sender):
        print(grantee.display(sender, use_json=use_json))


cred.add_command(cred_create, "create")
cred.add_command(cred_list, "list")
cred.add_command(cred_grant, "grant")
cred.add_command(cred_list_grantee, "list-grantee")
