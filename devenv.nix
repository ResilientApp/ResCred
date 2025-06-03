{ pkgs, lib, config, inputs, ... }:

{
  packages = with pkgs; [
    jq
    solc
    poetry
  ];
}
