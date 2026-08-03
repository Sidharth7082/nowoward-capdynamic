#!/bin/bash
# Helper script to list cliphist entries, generate image previews, and copy with correct MIME type

TMP_DIR="$HOME/.cache/quickshell/cliphist-imgs"
mkdir -p "$TMP_DIR"

if [[ -z "$1" ]]; then
    if ! command -v cliphist &>/dev/null; then
        echo "0	cliphist is not installed. Install via: sudo pacman -S cliphist"
        exit 0
    fi

    cliphist list | while IFS=$'\t' read -r id rest; do
        if [[ "$rest" == *"[[ binary data"* ]]; then
            img_path="$TMP_DIR/$id.png"
            [[ ! -f "$img_path" ]] && cliphist decode <<<"$id"$'\t'"$rest" > "$img_path" 2>/dev/null
            printf "%s\t%s\000icon\x1f%s\n" "$id" "$rest" "$img_path"
        else
            printf "%s\t%s\n" "$id" "$rest"
        fi
    done
else
    if command -v cliphist &>/dev/null; then
        img_tmp="/tmp/cliphist_copy_tmp.bin"
        cliphist decode <<<"$1" > "$img_tmp" 2>/dev/null
        if [[ -s "$img_tmp" ]]; then
            mime=$(file -b --mime-type "$img_tmp" 2>/dev/null)
            if [[ "$mime" == image/* ]]; then
                wl-copy -t "$mime" < "$img_tmp"
            else
                wl-copy < "$img_tmp"
            fi
            rm -f "$img_tmp"
        else
            cliphist decode <<<"$1" | wl-copy
        fi
    fi
fi
