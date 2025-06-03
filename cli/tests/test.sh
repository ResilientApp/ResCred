#!/usr/bin/env bash
set -euo pipefail

mktempfile() {
    mktemp --suffix .rescredtest
}
trap "rm -f /tmp/tmp.*.rescredtest" EXIT

# Compile & deploy Registry
setup() {
    init_sh=$(mktempfile)
    rescred.py init >  $init_sh
    source $init_sh
}

# Create issuer
issuer() {
    issuer_owner=$(rescred.py create)
    issuer=$(mktempfile)
    rescred.py issuer create -j -s $issuer_owner Stanford stanford.edu >  $issuer
    ib_addr=$(jq -r .address $issuer)
    ib_owner=$(jq -r .owner $issuer)
}
# Create and grant credential
creds() {
    cred=$(mktempfile)
    grant1=$(mktempfile)
    grant2=$(mktempfile)
    rescred.py cred -I $ib_addr create -s $ib_owner -n 'Bachelor Diploma' -j >  $cred
    rescred.py cred -I $ib_addr grant -s $ib_owner -i 1 -n 'Bachelor Diploma' -j >  $grant1
    rescred.py cred -I $ib_addr grant -s $ib_owner -i 1 -n 'Bachelor Diploma' -j >  $grant2
    grant1_addr=$(jq -r .address $grant1)
    grantee1=$(jq -r .grantee $grant1)
    rescred.py cred -I $ib_addr list-grantee -s $grantee1 -I 1 -i 1
    rescred.py req list -s $grantee1 -A $grant1_addr
}

# Create verifier and send verify request to grantee 1
send-verify-req() {
    verifier=$(mktempfile)
    rescred.py verifier create -n 'Test Verifier' -d 'verifier.test' -j >  $verifier
    verifier_addr=$(jq -r .address $verifier)
    verifier_owner=$(jq -r .owner $verifier)
    req=$(mktempfile)
    rescred.py verifier req -j -s $verifier_owner -a $grant1_addr >  $req
    rescred.py req list -s $grantee1 -A $grant1_addr
    req_addr=$(jq -r .address $req)
}

# Approve request
approve() {
    rescred.py req approve -s $grantee1 -a $req_addr
    rescred.py verifier list-req -s $verifier_owner -a $req_addr
}

# Reject request
reject() {
    rescred.py req reject -s $grantee1 -a $req_addr
    rescred.py verifier list-req -s $verifier_owner -a $req_addr
}

test-approve() {
    issuer
    creds
    send-verify-req
    approve | grep Approved && echo "Approval Test Passed" || return 1
}

test-reject() {
    issuer
    creds
    send-verify-req
    reject | grep Rejected && echo "Rejection Test Passed" || return 1
}

test-immutable() {
    issuer
    creds
    send-verify-req
    approve
    reject | grep Failed && echo "Immutability Test Passed" || return 1
}


test-all() {
    setup
    test-approve && test-reject && test-immutable && echo "ALL TESTS PASSED"
}

test-debug() {
    set -x
    export RESCRED_LOGLEVEL=debug
    test-all
    unset RESCRED_LOGLEVEL
    set +x
}

test-verbose() {
    set -x
    export RESCRED_LOGLEVEL=debug
    test-all
    unset RESCRED_LOGLEVEL
    set +x
}
