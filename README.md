# ResCred

Smart contract-based transparent certificate and credential issuance and verification tooling. Awaiting ResilientDB contract service support for cryptographic signature.

## Get Started

The instructions below require [ResilientDB](https://github.com/apache/incubator-resilientdb) and [devenv](https://devenv.sh/getting-started/).

```sh
# Clone ResilientDB and ResCred
cd $HOME
git clone https://github.com/ResilientApp/ResCred

# Install dependencies
cd ResCred
devenv shell # or direnv allow
cd cli
poetry install --no-root

cat <<'EOF' >>~/.bashrc
source $RESCRED_SOURCE/contracts/utils.sh
export ResDB_Home=$HOME/incubator-resilientdb # TODO: change
export RESCRED_SOURCE=$HOME/ResCred
export RESCRED_REGISTRY_COMPILED_PATH=$RESCRED_SOURCE/output.json
export RESCRED_CONTRACT_SVC_CONFIG=$ResDB_Home/service/tools/config/interface/service.config
EOF
exec $SHELL

# Start ResilientDB contract service
contract-service

# Run tests in a separate terminal
source $RESCRED_SOURCE/cli/tests/test.sh
test-all
```

## Issuing

```sh
issuer_owner=$(rescred.py create)
issuer=$(mktempfile)
cred=$(mktempfile)
grant=$(mktempfile)

# Create an issuer
rescred.py issuer create --json --sender $issuer_owner 'UC Davis' ucdavis.edu | tee $issuer

# Create a credential
rescred.py cred --issuer $ib_addr create --sender $ib_owner --name 'Bachelor Diploma' --json | tee $cred

# Grant the credential
cred_id=$(jq -r .id $cred)
rescred.py cred --issuer $ib_addr grant --sender $ib_owner --cred-id $cred_id --name 'Bachelor Diploma' --json | tee $grant

# List grantees
grantee=$(jq -r .grantee $grant)
grant_id$(jq -r .id $grant)
rescred.py cred --issuer $ib_addr list-grantee --sender $grantee --cred-id $cred_id --id $grant_id
```

## Sending Verification Request

```sh
# Create a verifier
verifier=$(mktempfile)
rescred.py verifier create -n 'Test Verifier' -d 'verifier.test' -j | tee $verifier

# Send a verification request
verifier_addr=$(jq -r .address $verifier)
verifier_owner=$(jq -r .owner $verifier)
req=$(mktempfile)
rescred.py verifier req --json --sender $verifier_owner --address $grant1_addr >  $req
```

## Approve or Reject

```sh
# List verification requests under a grant
grant_addr=$(jq -r .address $grant)
rescred.py req list --sender $grantee --grant-addr $grant_addr

# Approve request
# NOTE: You cannot undo this action.
req_addr=$(jq -r .address $req)

# Or reject request
# NOTE: You cannot undo this action.
rescred.py req reject --sender $grantee1 --address $req_addr

# Verifier checks request status
rescred.py verifier list-req --sender $verifier_owner --address $req_addr
```