#!/bin/sh

echo "========================================================"
echo " ⚡ HOMEBRIDGE UXC MASTER DEPLOYMENT ENGINE ⚡"
echo "========================================================"


# ========================================================
# Variables
# ========================================================

BUNDLE_DIR="/mnt/X6/UXC/homebridge/bundle"
DATA_DIR="/mnt/X6/UXC/homebridge/data"
ARCHIVE="/mnt/X6/homebridge-arm64.tar.gz"

UXC_NAME="homebridge"

RELEASE_URL="https://github.com/micpro7/test/releases/latest/download/homebridge-arm64.tar.gz"


# ========================================================
# Phase 1 - Dependencies
# ========================================================

echo ""
echo "🔄 [Phase 1] Checking dependencies..."

if ! mountpoint -q /mnt/X6; then
    echo "❌ /mnt/X6 is not mounted"
    exit 1
fi

echo "✅ /mnt/X6 mounted."


apk update

apk add \
    jq \
    tar \
    gzip \
    curl \
    ca-certificates


echo "========(+) DONE ✅ (+)========"



# ========================================================
# Phase 2 - Cleanup old container
# ========================================================

echo ""
echo "🧹 [Phase 2] Removing previous Homebridge runtime..."


uxc stop "$UXC_NAME" 2>/dev/null || true

uxc delete "$UXC_NAME" --force 2>/dev/null || true


echo "========(+) DONE ✅ (+)========"



# ========================================================
# Phase 3 - Prepare storage
# ========================================================

echo ""
echo "📂 [Phase 3] Preparing storage..."


rm -rf "$BUNDLE_DIR"

mkdir -p "$BUNDLE_DIR"
mkdir -p "$DATA_DIR"


chmod 755 "$DATA_DIR"


echo "Bundle:"
echo "$BUNDLE_DIR"

echo ""
echo "Persistent:"
echo "$DATA_DIR"


echo "========(+) DONE ✅ (+)========"



# ========================================================
# Phase 4 - Download ARM64 bundle
# ========================================================

echo ""
echo "📥 [Phase 4] Downloading Homebridge ARM64 bundle..."


rm -f "$ARCHIVE"


wget -O "$ARCHIVE" "$RELEASE_URL"


if [ ! -f "$ARCHIVE" ]; then

    echo "❌ Download failed"
    exit 1

fi


echo "📦 Extracting bundle..."

tar -xzf "$ARCHIVE" \
    -C /mnt/X6/UXC/homebridge


mv /mnt/X6/UXC/homebridge/bundle/* "$BUNDLE_DIR/" 2>/dev/null || true


echo ""
echo "Validating bundle..."


test -f "$BUNDLE_DIR/config.json" || exit 1

test -d "$BUNDLE_DIR/rootfs" || exit 1

jq empty "$BUNDLE_DIR/config.json"


echo "✅ OCI bundle valid"


echo "========(+) DONE ✅ (+)========"



# ========================================================
# Phase 5 - Register UXC
# ========================================================

echo ""
echo "🏗️ [Phase 5] Creating UXC container..."


uxc create "$UXC_NAME" \
    --bundle "$BUNDLE_DIR" \
    --mounts /mnt/X6


echo "========(+) DONE ✅ (+)========"



# ========================================================
# Phase 6 - Start
# ========================================================

echo ""
echo "🚀 [Phase 6] Starting Homebridge..."


uxc start "$UXC_NAME"


sleep 5


uxc list


echo "========(+) DONE ✅ (+)========"



# ========================================================
# Phase 7 - Install procd service
# ========================================================

echo ""
echo "🛠 Installing Homebridge service..."


cat > /etc/init.d/homebridge <<'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

NAME="homebridge"

start()
{
    uxc start "$NAME" 2>/dev/null || true
}

stop()
{
    uxc stop "$NAME" 2>/dev/null || true
}

restart()
{
    stop
    sleep 3
    start
}

status()
{
    uxc list | grep "$NAME"
}
EOF


chmod +x /etc/init.d/homebridge


/etc/init.d/homebridge enable


echo "========(+) DONE ✅ (+)========"



echo ""
echo "========================================================"
echo " 🎉 HOMEBRIDGE UXC DEPLOYMENT COMPLETE 🎉"
echo "========================================================"

echo ""
echo "Container:"
echo "$UXC_NAME"

echo ""
echo "Bundle:"
echo "$BUNDLE_DIR"

echo ""
echo "Persistent:"
echo "$DATA_DIR"

echo ""
echo "Web UI:"
echo "http://192.168.1.1:8581"

echo ""
echo "========================================================"
