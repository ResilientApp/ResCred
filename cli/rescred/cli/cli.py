import os
from subprocess import DEVNULL, check_output

import click
from rescred.contract import ContractClient
from rescred.registry import Registry

from .issuer import issuer
from .cred import cred
from .req import req
from .verifier import verifier


@click.group(
    help="ResCred - ResilientDB-based credential issuance and verification tool"
)
@click.pass_context
@click.option(
    "--resdb-home",
    "resdb_home",
    envvar="ResDB_Home",
    required=True,
    help="Path to ResilientDB repository",
)
@click.option(
    "--svc-config",
    "svc_config",
    envvar="RESCRED_CONTRACT_SVC_CONFIG",
    required=True,
    help="Path to contract service configuration",
)
@click.option(
    "--source",
    "rescred_source",
    envvar="RESCRED_SOURCE",
    required=True,
    help="Path to ResCred source",
)
@click.option(
    "--registry-compiled-path",
    "registry_compiled_path",
    envvar="RESCRED_REGISTRY_COMPILED_PATH",
    help="Path to compiled registry contract",
)
@click.option(
    "--registry-addr",
    "registry_addr",
    envvar="RESCRED_REGISTRY_ADDR",
    help="Registry contract address",
)
def cli(
    ctx: click.Context,
    resdb_home: str,
    svc_config: str,
    rescred_source: str,
    registry_compiled_path: str,
    registry_addr: str,
):
    ctx.ensure_object(dict)
    ctx.obj["source"] = rescred_source
    ctx.obj["client"] = ContractClient(
        resdb_home,
        svc_config,
        registry_compiled_path,
        registry_addr,
    )
    if registry_addr:
        ctx.obj["registry"] = Registry(ctx.obj["client"])


@click.command(help="Create a new address")
@click.pass_context
def create(ctx: click.Context):
    client: ContractClient = ctx.obj["client"]
    print(client.create_account())


@click.command(help="Execute a contract function")
@click.option("-s", "--sender", "sender", help="Sender address")
@click.option("-c", "--contract", "contract", required=True, help="Contract address")
@click.option("-f", "--function", "function", required=True, help="Function name")
@click.argument("arguments", nargs=-1)
@click.pass_context
def execute(
    ctx: click.Context, sender: str, contract: str, function: str, arguments: list[str]
):
    client: ContractClient = ctx.obj["client"]
    if not sender:
        sender = client.create_account()
    print(client.execute(sender, contract, function, *arguments))


@click.command(help="Deploy a ResCred contract onto contract service")
@click.option("-s", "--sender", "sender", help="Sender address")
@click.option("-c", "--contract", "contract", required=True, help="Contract name")
@click.argument("arguments", nargs=-1)
@click.pass_context
def deploy(ctx: click.Context, sender: str, contract, arguments: list[str]):
    client: ContractClient = ctx.obj["client"]
    if not sender:
        sender = client.create_account()
    print(client.deploy(contract, sender, *arguments))


@click.command(help="Compile and deploy Registry onto ResilientDB contract service")
@click.option("-s", "--sender", "sender", help="Sender address")
@click.pass_context
def init(ctx: click.Context, sender: str):
    client: ContractClient = ctx.obj["client"]
    source: str = ctx.obj["source"]
    compiled_json = check_output(
        [
            "solc",
            "--evm-version",
            "homestead",
            "--combined-json",
            "bin,hashes",
            "--pretty-json",
            "--optimize",
            os.path.join(source, "contracts", "Registry.sol"),
        ],
        cwd=source,
        stderr=DEVNULL,
    )
    with open(client.registry_compiled_path, "wb") as f:
        f.write(compiled_json)
    if not sender:
        sender = client.create_account()
    registry = client.deploy("Registry", sender)
    print(f"export RESCRED_REGISTRY_OWNER={sender}")
    print(f"export RESCRED_REGISTRY_ADDR={registry}")


cli.add_command(init)
cli.add_command(create)
cli.add_command(execute)
cli.add_command(deploy)

cli.add_command(issuer)
cli.add_command(cred)
cli.add_command(req)
cli.add_command(verifier)
