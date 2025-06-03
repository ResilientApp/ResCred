#!/usr/bin/env bash
export CONFIG_PATH=${ResDB_HOME:-$HOME/resilientdb}/service/tools/config/interface/service.config
export REPO=ResCred
export REPO_PATH=$HOME/$REPO
export OUTPUT_PATH=$REPO_PATH/output.json

export RESCRED_REGISTRY_COMPILED_PATH=$OUTPUT_PATH
export RESCRED_CONTRACT_SVC_CONFIG=$CONFIG_PATH
export RESCRED_SOURCE=$REPO_PATH

# Purpose: start or restart contract service, killing any existing contract service process
contract-service() {
    cd $ResDB_Home
    ./service/tools/contract/service_tools/start_contract_service.sh && tail -f contract-server0.log
}
