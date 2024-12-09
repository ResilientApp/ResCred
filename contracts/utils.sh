#!/usr/bin/env bash
export CONFIG_PATH=${ResDB_HOME:-$HOME/resilientdb}/service/tools/config/interface/service.config
export REPO=ecs189f
export REPO_PATH=$HOME/$REPO
export OUTPUT_PATH=$REPO_PATH/output.json

setrepo() {
    export REPO=$1
    export REPO_PATH=$HOME/$1
    export OUTPUT_PATH=$REPO_PATH/output.json
}

rescreate() {
    rescontract create --config $CONFIG_PATH 2>&1 | grep -Po 'address: "\K[^"]+' --color=never
}

rescompile() {
    rescontract compile --sol $REPO_PATH/contracts/Registry.sol --output $OUTPUT_PATH
    cp $OUTPUT_PATH ~/smart-contracts-graphql/compiled_contracts
}

resdeploy() {
    rescontract deploy --config $CONFIG_PATH --contract $OUTPUT_PATH --name $REPO/contracts/Registry.sol:Registry --arguments "" --owner $1
}

resdeploy_() {
    resdeploy $1 2>&1| grep -Po 'contract_address: "\K[^"]+'
}

# owner
resmkib() {
    rescontract deploy --config $CONFIG_PATH --contract $OUTPUT_PATH --name $REPO/contracts/Registry.sol:IssuingBody --arguments "$2,'example','example.com'" --owner $1
}

resmkib_() {
    resmkib $@ 2>&1 | grep -Po 'contract_address: "\K[^"]+'
}

# owner, ibaddress
resmkcred() {
    rescontract deploy --config $CONFIG_PATH --contract $OUTPUT_PATH \
        --name $REPO/contracts/Registry.sol:Credential \
        --arguments "$2,'example',0" --owner $1
}

resmkcred_() {
    resmkcred $@ 2>&1| grep -Po 'contract_address: "\K[^"]+'
}

# owner, credential address, grantee addr
resmkgrant() {
    rescontract deploy --config $CONFIG_PATH --contract $OUTPUT_PATH \
        --name $REPO/contracts/Registry.sol:CredentialGrant \
        --arguments "$2,$3,'John Smith',0" --owner $1
}

resmkgrant_() {
    resmkgrant $@ 2>&1| grep -Po 'contract_address: "\K[^"]+'
}

# owner, registry
resmkver() {
    rescontract deploy --config $CONFIG_PATH --contract $OUTPUT_PATH \
        --name $REPO/contracts/Registry.sol:Verifier \
        --arguments "$2,'example','example.com'" --owner $1
}

resmkver_() {
    resmkver $@ 2>&1| grep -Po 'contract_address: "\K[^"]+'
}

# owner=verifier, reg, grant
resmkreq() {
    rescontract deploy --config $CONFIG_PATH --contract $OUTPUT_PATH \
        --name $REPO/contracts/Registry.sol:VerifyRequest \
        --arguments "$2,$3" --owner $1
}

resmkreq_() {
    resmkreq $@ 2>&1| grep -Po 'contract_address: "\K[^"]+'
}

resexec() {
    rescontract execute --config $CONFIG_PATH $@
}

restest1() {
    echo
}

restest2() {
    echo
}

restest() {
    EXEC_OUTPUT="\033[0;37m"
    EXEC_OUTPUT=`tput setaf 3` # yellow
    ATTN=`tput setaf 6` # cyan
    DONE=`tput setaf 2` # green
    # NC="\033[0m" # No Color
    NC=`tput sgr0`

    echo -e "Compiling...${EXEC_OUTPUT}"
    rescompile
    echo -e "${NC}Compiling... ${DONE}done${NC}"
    echo

    echo -n "Registry address: "
    reg=$(resdeploy_ $(rescreate))
    echo $reg
    echo

    echo -n "IssuingBody owner address: "
    ibOwner=$(rescreate)
    echo $ibOwner
    echo

    echo -n "IssuingBody address: "
    ib=$(resmkib_ $ibOwner $reg)
    echo $ib
    echo

    echo -e "(IB) Registering IssuingBody... ${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $ibOwner --contract $reg \
        --function-name 'registerIssuingBody(address)' --arguments $ib | grep "fail"
    echo -e "${NC}(IB) Registering IssuingBody... ${DONE}done${NC}"
    echo

    echo -n "Credential address: "
    cred=$(resmkcred_ $ibOwner $ib)
    echo $cred
    echo

    echo -e "(IB) Registering Credential with IssuingBody...${EXEC_OUTPUT} "
    rescontract execute --config $CONFIG_PATH \
        --sender $ibOwner --contract $ib \
        --function-name 'addCredential(address)' --arguments $cred | grep "fail"
    echo -e "${NC}(IB) Registering Credential with IssuingBody... ${DONE}done${NC}"
    echo

    echo -n "Grantee address: "
    grantee=$(rescreate)
    echo $grantee
    echo

    echo -n "CredentialGrant address: "
    grant=$(resmkgrant_ $ibOwner $cred $grantee)
    echo $grant
    echo

    echo -e "(IB) Registering CredentialGrant with Credential...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $ibOwner --contract $cred \
        --function-name 'addGrant(address)' --arguments $grant | grep fail
    echo -e "${NC}(IB) Registering CredentialGrant with Credential... ${DONE}done${NC}"
    echo

    echo -n "Verifier owner address: "
    verOwner=$(rescreate)
    echo $verOwner
    echo

    echo -n "Verifier address: "
    ver=$(resmkver_ $verOwner $reg)
    echo $ver
    echo

    echo -e "(VE) Registering verifier...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $reg \
        --function-name 'registerVerifier(address)' --arguments $ver | grep fail
    echo -e "${NC}Registering verifier... ${DONE}done${NC}"
    echo

    echo -n "(VE) VerifyRequest address: "
    req=$(resmkreq_ $verOwner $ver $grant)
    echo $req
    echo

    echo -e "(VE) Sending verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $reg \
        --function-name 'sendVerifyReq(address,address)' --arguments $grant,$req | grep fail
    echo -e "${NC}(VE) Sending verify request... ${DONE}done${NC}"
    echo

    echo -e "(CO) Getting current verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $grantee --contract $grant \
        --function-name 'getReq()' --arguments "" | grep fail
    echo -e "${ATTN}Output should be equal to 0x1${NC}"
    echo -e "${NC}(CO) Getting current verify request... ${DONE}done${NC}"
    echo

    echo -e "(VE) Retrieve VerifyRequest by index...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $ver \
        --function-name 'getReqByIdx(uint256)' --arguments 0x0 | grep fail
    echo -e "${ATTN}Output should be equal to $req${NC}"
    echo -e "${NC}(VE) Retrieve VerifyRequest by index... ${DONE}done${NC}"
    echo

    echo -e "(VE) Retrieve status of pending verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $req \
        --function-name 'status()' --arguments "" | grep fail
    echo -e "${ATTN}Output should be equal to 0x0${NC}"
    echo -e "${NC}(VE) Retrieve status of verify request... ${DONE}done${NC}"
    echo

    echo -e "(CO) Approving verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $grantee --contract $reg \
        --function-name 'approveVerifyReq(uint256)' --arguments 0x1 | grep fail
    echo -e "${NC}(CO) Approving verify request... ${DONE}done${NC}"
    echo

    echo -e "(VE) Retrieve status of approved verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $req \
        --function-name 'status()' --arguments "" | grep fail
    echo -e "${ATTN}Output should be equal to 0x1${NC}"
    echo -e "${NC}(VE) Retrieve status of verify request... ${DONE}done${NC}"
    echo
}

restestrej() {
    EXEC_OUTPUT="\033[0;37m"
    EXEC_OUTPUT=`tput setaf 3` # yellow
    ATTN=`tput setaf 6` # cyan
    DONE=`tput setaf 2` # green
    # NC="\033[0m" # No Color
    NC=`tput sgr0`

    echo -e "Compiling...${EXEC_OUTPUT}"
    rescompile
    echo -e "${NC}Compiling... ${DONE}done${NC}"
    echo

    echo -n "Registry address: "
    reg=$(resdeploy_ $(rescreate))
    echo $reg
    echo

    echo -n "IssuingBody owner address: "
    ibOwner=$(rescreate)
    echo $ibOwner
    echo

    echo -n "IssuingBody address: "
    ib=$(resmkib_ $ibOwner $reg)
    echo $ib
    echo

    echo -e "(IB) Registering IssuingBody... ${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $ibOwner --contract $reg \
        --function-name 'registerIssuingBody(address)' --arguments $ib | grep "fail"
    echo -e "${NC}(IB) Registering IssuingBody... ${DONE}done${NC}"
    echo

    echo -n "Credential address: "
    cred=$(resmkcred_ $ibOwner $ib)
    echo $cred
    echo

    echo -e "(IB) Registering Credential with IssuingBody...${EXEC_OUTPUT} "
    rescontract execute --config $CONFIG_PATH \
        --sender $ibOwner --contract $ib \
        --function-name 'addCredential(address)' --arguments $cred | grep "fail"
    echo -e "${NC}(IB) Registering Credential with IssuingBody... ${DONE}done${NC}"
    echo

    echo -n "Grantee address: "
    grantee=$(rescreate)
    echo $grantee
    echo

    echo -n "CredentialGrant address: "
    grant=$(resmkgrant_ $ibOwner $cred $grantee)
    echo $grant
    echo

    echo -e "(IB) Registering CredentialGrant with Credential...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $ibOwner --contract $cred \
        --function-name 'addGrant(address)' --arguments $grant | grep fail
    echo -e "${NC}(IB) Registering CredentialGrant with Credential... ${DONE}done${NC}"
    echo

    echo -n "Verifier owner address: "
    verOwner=$(rescreate)
    echo $verOwner
    echo

    echo -n "Verifier address: "
    ver=$(resmkver_ $verOwner $reg)
    echo $ver
    echo

    echo -e "(VE) Registering verifier...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $reg \
        --function-name 'registerVerifier(address)' --arguments $ver | grep fail
    echo -e "${NC}Registering verifier... ${DONE}done${NC}"
    echo

    echo -n "(VE) VerifyRequest address: "
    req=$(resmkreq_ $verOwner $ver $grant)
    echo $req
    echo

    echo -e "(VE) Sending verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $reg \
        --function-name 'sendVerifyReq(address,address)' --arguments $grant,$req | grep fail
    echo -e "${NC}(VE) Sending verify request... ${DONE}done${NC}"
    echo

    echo -e "(CO) Getting current verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $grantee --contract $grant \
        --function-name 'getReq()' --arguments "" | grep fail
    echo -e "${ATTN}Output should be equal to 0x1${NC}"
    echo -e "${NC}(CO) Getting current verify request... ${DONE}done${NC}"
    echo

    echo -e "(VE) Retrieve VerifyRequest by index...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $ver \
        --function-name 'getReqByIdx(uint256)' --arguments 0x0 | grep fail
    echo -e "${ATTN}Output should be equal to $req${NC}"
    echo -e "${NC}(VE) Retrieve VerifyRequest by index... ${DONE}done${NC}"
    echo

    echo -e "(VE) Retrieve status of pending verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $req \
        --function-name 'status()' --arguments "" | grep fail
    echo -e "${ATTN}Output should be equal to 0x0${NC}"
    echo -e "${NC}(VE) Retrieve status of verify request... ${DONE}done${NC}"
    echo

    echo -e "(CO) Rejecting verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $grantee --contract $reg \
        --function-name 'rejectVerifyReq(uint256)' --arguments 0x1 | grep fail
    echo -e "${NC}(CO) Rejecting verify request... ${DONE}done${NC}"
    echo

    echo -e "(VE) Retrieve status of approved verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $req \
        --function-name 'status()' --arguments "" | grep fail
    echo -e "${ATTN}Output should be equal to 0x2${NC}"
    echo -e "${NC}(VE) Retrieve status of verify request... ${DONE}done${NC}"
    echo
}

restestsec() {
    EXEC_OUTPUT="\033[0;37m"
    EXEC_OUTPUT=`tput setaf 3` # yellow
    ATTN=`tput setaf 6` # cyan
    DONE=`tput setaf 2` # green
    # NC="\033[0m" # No Color
    NC=`tput sgr0`

    echo -e "Compiling...${EXEC_OUTPUT}"
    rescompile
    echo -e "${NC}Compiling... ${DONE}done${NC}"
    echo

    echo -n "Registry address: "
    reg=$(resdeploy_ $(rescreate))
    echo $reg
    echo

    echo -n "IssuingBody owner address: "
    ibOwner=$(rescreate)
    echo $ibOwner
    echo

    echo -n "IssuingBody address: "
    ib=$(resmkib_ $ibOwner $reg)
    echo $ib
    echo

    echo -e "(IB) Registering IssuingBody... ${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $ibOwner --contract $reg \
        --function-name 'registerIssuingBody(address)' --arguments $ib | grep "fail"
    echo -e "${NC}(IB) Registering IssuingBody... ${DONE}done${NC}"
    echo

    echo -n "Credential address: "
    cred=$(resmkcred_ $ibOwner $ib)
    echo $cred
    echo

    echo -e "(IB) Registering Credential with IssuingBody...${EXEC_OUTPUT} "
    rescontract execute --config $CONFIG_PATH \
        --sender $ibOwner --contract $ib \
        --function-name 'addCredential(address)' --arguments $cred | grep "fail"
    echo -e "${NC}(IB) Registering Credential with IssuingBody... ${DONE}done${NC}"
    echo

    echo -n "Grantee address: "
    grantee=$(rescreate)
    echo $grantee
    echo

    echo -n "CredentialGrant address: "
    grant=$(resmkgrant_ $ibOwner $cred $grantee)
    echo $grant
    echo

    echo -e "(IB) Registering CredentialGrant with Credential...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $ibOwner --contract $cred \
        --function-name 'addGrant(address)' --arguments $grant | grep fail
    echo -e "${NC}(IB) Registering CredentialGrant with Credential... ${DONE}done${NC}"
    echo

    echo -n "Verifier owner address: "
    verOwner=$(rescreate)
    echo $verOwner
    echo

    echo -n "Verifier address: "
    ver=$(resmkver_ $verOwner $reg)
    echo $ver
    echo

    echo -e "(VE) Registering verifier...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $reg \
        --function-name 'registerVerifier(address)' --arguments $ver | grep fail
    echo -e "${NC}Registering verifier... ${DONE}done${NC}"
    echo

    echo -n "(VE) VerifyRequest address: "
    req=$(resmkreq_ $verOwner $ver $grant)
    echo $req
    echo

    echo -e "(VE) Sending verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $reg \
        --function-name 'sendVerifyReq(address,address)' --arguments $grant,$req | grep fail
    echo -e "${NC}(VE) Sending verify request... ${DONE}done${NC}"
    echo

    echo -e "(CO) Getting current verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $grantee --contract $grant \
        --function-name 'getReq()' --arguments "" | grep fail
    echo -e "${ATTN}Output should be equal to 0x1${NC}"
    echo -e "${NC}(CO) Getting current verify request... ${DONE}done${NC}"
    echo

    echo -e "(VE) Retrieve VerifyRequest by index...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $ver \
        --function-name 'getReqByIdx(uint256)' --arguments 0x0 | grep fail
    echo -e "${ATTN}Output should be equal to $req${NC}"
    echo -e "${NC}(VE) Retrieve VerifyRequest by index... ${DONE}done${NC}"
    echo

    echo -e "(VE) Retrieve status of pending verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $req \
        --function-name 'status()' --arguments "" | grep fail
    echo -e "${ATTN}Output should be equal to 0x0${NC}"
    echo -e "${NC}(VE) Retrieve status of verify request... ${DONE}done${NC}"
    echo

    echo -e "(CO) Rejecting verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $grantee --contract $reg \
        --function-name 'rejectVerifyReq(uint256)' --arguments 0x1 | grep fail
    echo -e "${NC}(CO) Rejecting verify request... ${DONE}done${NC}"
    echo

    echo -e "(VE) Retrieve status of approved verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $verOwner --contract $req \
        --function-name 'status()' --arguments "" | grep fail
    echo -e "${ATTN}Output should be equal to 0x2${NC}"
    echo -e "${NC}(VE) Retrieve status of verify request... ${DONE}done${NC}"
    echo
    
    echo -e "(CO) Attempt to approve rejected verify request...${EXEC_OUTPUT}"
    rescontract execute --config $CONFIG_PATH \
        --sender $grantee --contract $reg \
        --function-name 'approveVerifyReq(uint256)' --arguments 0x1 | grep fail
    echo "Failing is EXPECTED"
    echo -e "${NC}(CO) Attempt to approve rejected verify request... ${DONE}done${NC}"
    echo
}

ressvc() {
    cd $ResDB_Home
    killall -9 contract_service
    ./service/tools/contract/service_tools/start_contract_service.sh && tail -f contract-server0.log
}