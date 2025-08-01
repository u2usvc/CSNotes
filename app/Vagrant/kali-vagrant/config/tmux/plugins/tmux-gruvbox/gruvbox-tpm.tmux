#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
  tmux source-file "$CURRENT_DIR/tmux-gruvbox.conf"
}

main
