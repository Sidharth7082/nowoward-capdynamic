#!/usr/bin/env bash
# High-speed parallel thumbnail generator for nowoward-capdynamic Wallpaper Picker

WALLPAPER_DIR="${1:-$HOME/Pictures/Wallpapers}"
CACHE_DIR="${2:-$HOME/.cache/quickshell/nowoward-capdynamic/wallpaper-picker}"

mkdir -p "$CACHE_DIR"

gen_one() {
    local src="$1"
    local cdir="$2"
    local fname
    fname=$(basename "$src")
    local dst="$cdir/$fname.jpg"

    if [ -f "$dst" ] && [ "$dst" -nt "$src" ]; then
        return 0
    fi

    local ext="${src##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    if [[ "$ext" == "mp4" || "$ext" == "webm" || "$ext" == "mkv" || "$ext" == "mov" ]]; then
        ffmpeg -y -loglevel error -i "$src" -frames:v 1 -vf "scale=560:-1" "$dst" 2>/dev/null
    else
        if command -v magick &>/dev/null; then
            magick "$src[0]" -resize 560x320^ -gravity center -extent 560x320 -quality 85 "$dst" 2>/dev/null
        elif command -v convert &>/dev/null; then
            convert "$src[0]" -resize 560x320^ -gravity center -extent 560x320 -quality 85 "$dst" 2>/dev/null
        else
            ffmpeg -y -loglevel error -i "$src" -frames:v 1 -vf "scale=560:-1" "$dst" 2>/dev/null
        fi
    fi
}

export -f gen_one

find "$WALLPAPER_DIR" -maxdepth 1 -type f | while read -r img; do
    ext="${img##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    case "$ext" in
        png|jpg|jpeg|webp|gif|mp4|webm|mkv|mov)
            gen_one "$img" "$CACHE_DIR" &
            ;;
    esac
done

wait
