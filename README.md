# ResCred

Smart contract-based transparent certificate and credential issuance and verification tooling.

## Get Started

```sh
cd $HOME
git clone https://github.com/apache/incubator-resilientdb resilientdb
git clone https://github.com/ResilientApp/ResCred
cat <<'EOF' >>~/.bashrc
export ResDB_Home=$HOME/resilientdb
export REPO=ResCred
export CONFIG_PATH=${ResDB_HOME:-$HOME/resilientdb}/service/tools/config/interface/service.config
export REPO_PATH=$HOME/$REPO
export OUTPUT_PATH=$REPO_PATH/output.json
source $REPO_PATH/contracts/utils.sh
EOF
exec $SHELL

# Start ResilientDB contract service
ressvc

# Run tests in a separate terminal
test-approve
test-reject
test-immutable
```