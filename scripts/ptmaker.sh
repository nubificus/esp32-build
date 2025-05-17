#!/bin/bash

show_help() {
    cat <<EOF
Usage: $(basename "$0") [--help] flash-size

The flash size should be provided in bytes, kilobytes, megabytes or
gigabytes. For example, for 1MB flash size:

$(basename "$0") 1073741824
or
$(basename "$0") 1024KB
or
$(basename "$0") 1MB

This script calculates the maximum equal size for 3 app partitions and
generate a partition table based on the given flash size.

Each image starts at a 64KB-aligned offset.

Output:
  - Optimal partition table (apps aligned)
EOF
}

if [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Default to 8MB if no argument is provided
input="${1:-8MB}"

if ! echo "$input" | grep -E -qi '^[0-9]+([KMG]?B)?$'; then
    >&2 echo "# Error: Invalid flash size format. Use formats like 8, 4KB, 2MB, 1GB"
    exit 1
fi

value=$(echo "$input" | grep -o -E '^[0-9]+')

unit=$(echo "$input" | grep -o -E '[KMG]?B' | tr '[:lower:]' '[:upper:]')
if [[ -z "$unit" ]]; then
    unit="B"
fi

# Determine multiplier
case "$unit" in
    B)
        multiplier=1
        ;;
    KB)
        multiplier=$((1024))
        ;;
    MB)
        multiplier=$((1024 * 1024))
        ;;
    GB)
        multiplier=$((1024 * 1024 * 1024))
        ;;
    *)
        >&2 echo "# Error: Unknown unit '$unit'"
        exit 1
        ;;
esac

flash_size=$((value * multiplier))

align=$((0x10000))
ota_off=$(($flash_size-$align))
ota_size=$((0x2000))

app_off=$((0x20000))

avail=$(($ota_off - $app_off))

max_image_size=$((avail / 3))

aligned_image_size=$(( (max_image_size / align) * align ))

image1_off=$app_off
image2_off=$((app_off + aligned_image_size))
image3_off=$((app_off + 2 * aligned_image_size))

for addr in $image1_off $image2_off $image3_off; do
    if (( addr % align != 0 )); then
        echo "Error: Image start offset $addr is not 64KB aligned."
        exit 1
    fi
done

apps_size=$(printf "0x%X" "$aligned_image_size")
app_off=$(printf "0x%X" "$image1_off")
ota0_off=$(printf "0x%X" "$image2_off")
ota1_off=$(printf "0x%X" "$image3_off")
ota_off=$(printf "0x%X" "$ota_off")
ota_size=$(printf "0x%X" "$ota_size")

comments="# Name,       Type, SubType, Offset,   Size,    Flags"
nvs_entry="nvs,          data, nvs,     0x11000,  0x6000,"
phy_entry="phy_init,     data, phy,     0x17000,  0x1000,"
app_entry="factory,      app,  factory, $app_off,  $apps_size,"
ota0_entry="ota_0,        app,  ota_0,   $ota0_off, $apps_size,"
ota1_entry="ota_1,        app,  ota_1,   $ota1_off, $apps_size,"
ota_entry="otadata,      data, ota,     $ota_off, $ota_size,"

echo $comments
echo $nvs_entry
echo $phy_entry
echo $app_entry
echo $ota0_entry
echo $ota1_entry
echo $ota_entry
