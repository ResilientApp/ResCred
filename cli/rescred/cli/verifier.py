import click
from rescred.contract import ContractClient
from rescred.registry import CredentialGrant, Registry, Verifier, VerifyRequest


@click.group(help="Verifier creation and verification request management")
def verifier():
    pass


@click.command(help="Create a new verifier")
@click.pass_context
@click.option("-s", "--sender", "sender", help="Sender address")
@click.option("-n", "--name", "name", required=True, help="Verifier name")
@click.option("-d", "--domain", "domain", required=True, help="Verifier domain")
@click.option("-j", "--json", "use_json", is_flag=True, help="Output JSON")
def create(ctx: click.Context, sender: str, name: str, domain: str, use_json: bool):
    client: ContractClient = ctx.obj["client"]
    registry: Registry = ctx.obj["registry"]
    if not sender:
        sender = client.create_account()
    v = Verifier.deploy(client, sender, client.registry_addr, name, domain)
    registry.register_verifier(sender, v.addr)
    print(v.display(sender, use_json=use_json))


@click.command(help="Send a verification request")
@click.pass_context
@click.option("-s", "--sender", "sender", required=True, help="Sender address")
@click.option("-a", "--address", "address", required=True, help="Grant address")
@click.option("-j", "--json", "use_json", is_flag=True, help="Output JSON")
def req(ctx: click.Context, sender: str, address: str, use_json: bool):
    client: ContractClient = ctx.obj["client"]
    registry: Registry = ctx.obj["registry"]
    verifier = registry.get_verifier_by_creator(sender)
    vr = VerifyRequest.deploy(client, sender, verifier.addr, address)
    registry.send_verify_req(sender, address, vr.addr)
    print(vr.display(sender, use_json=use_json))


@click.command(help="List verification requests")
@click.pass_context
@click.option("-s", "--sender", "sender", required=True, help="Sender address")
@click.option("-i", "--id", "req_id", type=int, help="Request ID")
@click.option("-a", "--address", "req_addr", help="Request address")
@click.option("-j", "--json", "use_json", is_flag=True, help="Output JSON")
def list_req(
    ctx: click.Context, sender: str, req_id: int, req_addr: str, use_json: bool
):
    client: ContractClient = ctx.obj["client"]
    registry: Registry = ctx.obj["registry"]
    if req_id:
        vr = registry.get_verifier_verify_req(sender, req_id)
        print(vr.display(sender, use_json=use_json))
        return
    if req_addr:
        print(VerifyRequest(client, req_addr).display(sender, use_json=use_json))
        return
    verifier = registry.get_verifier_by_creator(sender)
    for vr in verifier.reqs(sender):
        print(vr.display(sender, use_json=use_json))


verifier.add_command(create)
verifier.add_command(req)
verifier.add_command(list_req, "list-req")
