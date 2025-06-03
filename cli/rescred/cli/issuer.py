import click
from rescred.contract import ContractClient
from rescred.registry import IssuingBody, Registry


@click.group(help="Issuer creation and management")
def issuer():
    pass


@click.command(help="Create a new issuer")
@click.option("-s", "--sender", "sender", help="Sender address")
@click.option("-j", "--json", "use_json", is_flag=True, help="Output JSON")
@click.argument("name")
@click.argument("domain")
@click.pass_context
def create(ctx: click.Context, sender: str, name: str, domain: str, use_json: bool):
    client: ContractClient = ctx.obj["client"]
    registry: Registry = ctx.obj["registry"]
    if not sender:
        sender = client.create_account()
    ib = IssuingBody.deploy(client, sender, name, domain)
    registry.register_issuing_body(sender, ib.addr)
    print(ib.display(sender, use_json=use_json))


@click.command(help="List issuers")
@click.option("-s", "--sender", "sender", help="Sender address")
@click.option("-a", "--address", "address", help="Issuer address")
@click.option("-i", "--id", "ib_id", type=int, help="Issuer ID")
@click.option("-j", "--json", "use_json", is_flag=True, help="Output JSON")
@click.pass_context
def list(ctx: click.Context, sender: str, address: str, ib_id: int, use_json: bool):
    client: ContractClient = ctx.obj["client"]
    if not sender:
        sender = client.create_account()
    if not address and ib_id:
        address = client.exec_addr(
            sender, client.registry_addr, "getIssuingBodyById(uint256)", ib_id
        )
    if not ib_id and address:
        ib_id = client.exec_int(sender, address, "getId()")
    if address:
        print(IssuingBody(client, address).display(sender, use_json=use_json))
        return
    registry = Registry(client)
    max_id = registry.next_ib_id(sender)
    for i in range(1, max_id):
        print(
            registry.get_issuing_body_by_id(sender, i).display(
                sender, use_json=use_json
            )
        )


issuer.add_command(create)
issuer.add_command(list)
