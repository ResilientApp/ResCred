import os

import click


def loglevel() -> str:
    env = os.getenv("RESCRED_LOGLEVEL") or ""
    return env.lower()


def debug(data: str, fg="yellow"):
    if loglevel() in ["debug", "verbose"]:
        click.secho(data, fg=fg, err=True)


def verbose(data: str, fg="blue"):
    if loglevel() == "verbose":
        click.secho(data, fg=fg, err=True)
