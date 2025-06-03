#!/usr/bin/env python3
import click
from rescred.cli.cli import cli

if __name__ == "__main__":
    try:
        cli(obj={})
    except Exception as e:
        click.secho(f"Failed: {repr(e)}")
        exit(1)

"""
BOOTSTRAPPING & TROUBLESHOOTING
rescred init
rescred create
rescred deploy
rescred execute

ISSUER
rescred issuer create
rescred issuer list
rescred cred create
rescred cred list
rescred cred grant
rescred cred grantees

OWNER
rescred req list
rescred req accept
rescred req reject

VERIFIER
rescred verifier create
rescred verifier req
rescred verifier list-req
"""
