#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run wlogout using local configuration
wlogout \
    -b 5 \
    -c 0 \
    -r 0 \
    -p layer-shell \
    -l "$SCRIPT_DIR/layout" \
    -C "$SCRIPT_DIR/style.css"
