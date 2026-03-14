#!/bin/bash

# Install yazi file manager with smart-enter plugin

ARCH="${YAZI_ARCH:-x86_64-unknown-linux-musl}"
YAZI_CONFIG_DIR="$HOME/.config/yazi"
TMP_DIR="$(mktemp -d)"

echo "→ Installing yazi ($ARCH)"

# Dependencies
sudo apt install -y unzip

# Download and extract
DOWNLOAD_URL="https://github.com/sxyazi/yazi/releases/latest/download/yazi-${ARCH}.zip"
curl -L --progress-bar -o "$TMP_DIR/yazi.zip" "$DOWNLOAD_URL"
unzip -q "$TMP_DIR/yazi.zip" -d "$TMP_DIR"

# Install binaries
sudo cp "$TMP_DIR/yazi-${ARCH}/yazi" /usr/local/bin/
sudo chmod +x /usr/local/bin/yazi

sudo cp "$TMP_DIR/yazi-${ARCH}/ya" /usr/local/bin/
sudo chmod +x /usr/local/bin/ya

# Cleanup
rm -rf "$TMP_DIR"

echo "→ Configuring yazi"

mkdir -p "$YAZI_CONFIG_DIR"

# Install smart-enter plugin
ya pkg add diff-hub/yazi-plugins:smart-enter

# Write keymap config
cat > "$YAZI_CONFIG_DIR/keymap.toml" << 'EOF'
# Yazi keymap configuration

[[mgr.prepend_keymap]]
on = "<Enter>"
run = "plugin smart-enter"
desc = "Enter the child directory, or open the file"
EOF

# Write yazi configuration
cat > "$YAZI_CONFIG_DIR/yazi.toml" << 'EOF'
[opener]

[[opener.edit]]
run = 'nano "$@"'
block = true
EOF

echo "✓ yazi installed: $(yazi --version)"
echo "✓ Config written to $YAZI_CONFIG_DIR/keymap.toml"