#!/bin/zsh

TARGET_DIR="/home/vagrant/.config/tmux/plugins/tpm"

while [ ! -d "$TARGET_DIR" ]; do
  echo "Cloning TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TARGET_DIR" || {
    echo "Clone failed. Retrying in 2 seconds..."
    sleep 2
  }
done

echo "TPM successfully installed at $TARGET_DIR"
