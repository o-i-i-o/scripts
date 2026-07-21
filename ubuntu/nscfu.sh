#!/bin/bash
# nscfu.sh - Nginx Source Config For Ubuntu
# Strict follow official doc: mandatory fingerprint
# 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
# Usage:
#   sudo ./nscfu.sh -s  # stable repo
#   sudo ./nscfu.sh -m  # mainline repo

# Check root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: Must run with sudo / root!"
    exit 1
fi

# Parse args
REPO_TYPE=""
if [[ "$1" == "-s" ]]; then
    REPO_TYPE="stable"
elif [[ "$1" == "-m" ]]; then
    REPO_TYPE="mainline"
else
    echo "Usage:"
    echo "  sudo $0 -s   Install Nginx Stable official apt source"
    echo "  sudo $0 -m   Install Nginx Mainline official apt source"
    exit 1
fi

# Official required fingerprint
TARGET_FINGER="573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62"
KEY_PATH="/usr/share/keyrings/nginx-archive-keyring.gpg"
LIST_FILE="/etc/apt/sources.list.d/nginx.list"
PIN_FILE="/etc/apt/preferences.d/99nginx"

echo "============================================="
echo "Configuring Nginx $REPO_TYPE official APT repo"
echo "Target fingerprint to match: $TARGET_FINGER"
echo "============================================="

# Step1 Install prerequisites
echo "[1/5] Install required packages..."
apt update -qq
apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring

# Step2 Download key, fix permission denied with sudo tee
echo "[2/5] Download Nginx official signing key..."
curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee "$KEY_PATH" >/dev/null

# Check key file not empty
if [[ ! -s "$KEY_PATH" ]]; then
    echo "ERROR: Key file empty, download failed, check network!"
    rm -f "$KEY_PATH"
    exit 1
fi

# Step3 Full capture all fingerprints, cycle compare target
echo "[3/5] Extract all fingerprints & verify target..."
TMP_GNUPG=$(mktemp -d)

# Restore official original gpg command, remove --quiet to get full output
RAW_OUTPUT=$(GNUPGHOME="$TMP_GNUPG" gpg --dry-run --no-keyring --import --import-options import-show "$KEY_PATH" 2>/dev/null)
rm -rf "$TMP_GNUPG"

# Extract pure 40-digit hex fingerprints, remove all spaces, store into array
FINGER_ARRAY=()
while IFS= read -r line; do
    # Match line only contains 40 hex chars with possible spaces
    if [[ "$line" =~ [0-9A-Fa-f]{40} ]]; then
        CLEAN=$(echo "$line" | tr -d '[:space:]' | tr 'a-z' 'A-Z')
        FINGER_ARRAY+=("$CLEAN")
    fi
done <<< "$RAW_OUTPUT"

# Print all extracted fingerprints for debug
echo "All extracted fingerprints list:"
for f in "${FINGER_ARRAY[@]}"; do
    echo " - $f"
done
echo "---------------------------------------------"

# Cycle compare each fingerprint with target
MATCH_FOUND=0
for current in "${FINGER_ARRAY[@]}"; do
    if [[ "$current" == "$TARGET_FINGER" ]]; then
        MATCH_FOUND=1
        break
    fi
done

if [[ $MATCH_FOUND -ne 1 ]]; then
    echo "ERROR: Target fingerprint $TARGET_FINGER not exist in key file!"
    rm -f "$KEY_PATH"
    exit 1
fi
echo "✓ Target fingerprint matched, verification passed"

# Step4 Write apt source list
echo "[4/5] Generate nginx apt source file..."
CODENAME=$(lsb_release -cs)
> "$LIST_FILE"
if [[ "$REPO_TYPE" == "stable" ]]; then
    BASE_URL="https://nginx.org/packages/ubuntu"
else
    BASE_URL="https://nginx.org/packages/mainline/ubuntu"
fi
echo "deb [signed-by=$KEY_PATH] $BASE_URL $CODENAME nginx" >> "$LIST_FILE"

# Step5 Set apt pin priority
echo "[5/5] Configure APT pin to prefer nginx.org packages..."
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900" > "$PIN_FILE"

echo "============================================="
echo "All steps finished successfully!"
echo "Run command to install nginx:"
echo "  apt update && apt install nginx"
echo "============================================="
exit 0
