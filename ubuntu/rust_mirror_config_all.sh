set -e

MIRROR=https://mirrors.tuna.tsinghua.edu.cn

echo  "start creates-io mirror config"

mkdir -vp ${CARGO_HOME:-$HOME/.cargo}

cat << EOF | tee -a ${CARGO_HOME:-$HOME/.cargo}/config.toml
[source.crates-io]
replace-with = 'mirror'

[source.mirror]
registry = "sparse+$MIRROR/crates.io-index/"

[registries.mirror]
index = "sparse+$MIRROR/crates.io-index/"
EOF


echo "start rustup mirror config"

# for bash
echo "export RUSTUP_UPDATE_ROOT=$MIRROR/rustup/rustup" >> ~/.bashrc
echo "export RUSTUP_DIST_SERVER=$MIRROR/rustup" >> ~/.bashrc

echo  "must run source  ~/.bashrc  once"
