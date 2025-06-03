import json
import os
import re
from binascii import hexlify, unhexlify
from datetime import datetime
from subprocess import STDOUT, check_output
from tempfile import NamedTemporaryFile

from rescred.cli.utils import debug, verbose

arg_type = str | int | bool | datetime


def to_func_args(*args: arg_type) -> str:
    str_args: list[str] = []
    for arg in args:
        if type(arg) is str and arg.startswith("0x"):
            str_args.append(arg)
        elif type(arg) is str:
            if len(arg) > 32:
                raise RuntimeError(
                    "due to eEVM and contract service limitations, strings longer than 32 bytes are not supported"
                )
            str_args.append("0x" + hexlify(arg.encode()).decode())
        elif type(arg) is int:
            str_args.append(hex(arg))
        elif type(arg) is bool:
            str_args.append("0x1" if arg else "0x0")
        elif type(arg) is datetime:
            str_args.append(hex(int(arg.timestamp())))
    return ",".join(str_args)


class ContractClient:
    def __init__(
        self,
        resdb_home: str,
        svc_config: str,
        registry_compiled_path: str,
        registry_addr: str,
    ) -> None:
        self.resdb_home = resdb_home
        self.svc_config = svc_config
        self.registry_source_path = "contracts/Registry.sol"
        self.registry_compiled_path = registry_compiled_path
        self.registry_addr = registry_addr

    def contract_tools(self, cmd: str, **kwargs: str) -> str:
        kwargs["command"] = cmd
        tool_path = os.path.join(
            self.resdb_home,
            "bazel-bin",
            "service",
            "tools",
            "contract",
            "api_tools",
            "contract_tools",
        )
        debug(json.dumps(kwargs))
        with NamedTemporaryFile() as tmp:
            tmp.write(json.dumps(kwargs).encode())
            tmp.flush()
            args = [tool_path, "-c", self.svc_config, "-f", tmp.name]
            output = check_output(args, stderr=STDOUT)
            verbose(output.decode())
        return output.decode()

    def create_account(self) -> str:
        output = self.contract_tools("create_account")
        if "address:" not in output:
            raise RuntimeError("could not create address")
        match = re.search(r'(?<=address: ")[^"]+', output)
        if not match:
            raise RuntimeError("could not create address")
        return match.group(0)

    def execute(
        self, caller_addr: str, contract_addr: str, function_name: str, *args: arg_type
    ) -> str:
        output = self.contract_tools(
            "execute",
            caller_address=caller_addr,
            contract_address=contract_addr,
            func_name=function_name,
            params=to_func_args(*args),
        )
        if "execute result:" not in output:
            raise RuntimeError(f"failed to invoke contract function `{function_name}'")
        lines = output.splitlines()
        exec_result_line_id = 0
        for idx, line in enumerate(lines):
            if "execute result" in line:
                # click.secho(line, fg="blue")
                exec_result_line_id = idx
                break
        line = lines[exec_result_line_id + 1]
        # click.secho(line, fg="red")
        return line

    def exec_addr(
        self, caller_addr: str, contract_addr: str, function_name: str, *args: arg_type
    ) -> str:
        addr = self.execute(caller_addr, contract_addr, function_name, *args)
        stripped = addr[2:].lstrip("0")
        return f"0x{stripped}"

    def exec_int(
        self, caller_addr: str, contract_addr: str, function_name: str, *args: arg_type
    ) -> int:
        result = self.execute(caller_addr, contract_addr, function_name, *args)
        return int(result, 16)

    def exec_bool(
        self, caller_addr: str, contract_addr: str, function_name: str, *args: arg_type
    ) -> bool:
        result = self.exec_int(caller_addr, contract_addr, function_name, *args)
        return result == 1

    def exec_datetime(
        self, caller_addr: str, contract_addr: str, function_name: str, *args: arg_type
    ) -> datetime:
        result = self.exec_int(caller_addr, contract_addr, function_name, *args)
        return datetime.fromtimestamp(result)

    def exec_str(
        self, caller_addr: str, contract_addr: str, function_name: str, *args: arg_type
    ) -> str:
        return unhexlify(
            self.execute(caller_addr, contract_addr, function_name, *args)[2:].lstrip(
                "0"
            )
        ).decode()

    def registry_execute(
        self, sender_addr: str, function_name: str, *args: arg_type
    ) -> str:
        return self.execute(sender_addr, self.registry_addr, function_name, *args)

    def deploy(self, contract: str, caller_addr: str, *args: arg_type) -> str:
        output = self.contract_tools(
            "deploy",
            contract_path=self.registry_compiled_path,
            contract_name=f"{self.registry_source_path}:{contract}",
            contract_address=caller_addr,
            init_params=to_func_args(*args),
        )
        if "contract_address:" not in output:
            raise RuntimeError(f"could not deploy contract `{contract}'")
        match = re.search(r'(?<=contract_address: ")[^"]+', output)
        if not match:
            raise RuntimeError(f"could not deploy contract `{contract}'")
        return match.group(0)
