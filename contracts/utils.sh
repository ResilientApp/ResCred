#!/usr/bin/env bash

# Purpose: start or restart contract service, killing any existing contract service process
contract-service() {
    cd $ResDB_Home
    build //service/tools/contract/api_tools:contract_tools //service/contract:contract_service
    ./service/tools/contract/service_tools/start_contract_service.sh && tail -f contract-server0.log
}
