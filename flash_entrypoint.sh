#!/bin/bash

# Runtime arguments: PORT CHIP FLASH_SIZE or
# --port /dev/ttyUSB0 --chip esp32s2 --flash_size 8MB
# => 6 arguments

if [ "$#" -lt 6 ]; then
  echo "You have to set --port, --chip and --flash_size [--baud]"
  exit 1
fi

BAUD=460800

# Parse arguments
while [ "$#" -gt 0 ]; do
  key="$1"
  value="$2"

  case "$key" in
    --port)
      PORT="$value"
      ;;
    --chip)
      CHIP="$value"
      ;;
    --flash_size)
      FLASH="$value"
      ;;
    --baud)
      BAUD="$value"
      ;;
    *)
      echo "Error: Unknown option '$key'"
      exit 1
      ;;
  esac

  shift 2
done

# Validate required values
if [ -z "$PORT" ] || [ -z "$CHIP" ] || [ -z "$FLASH" ]; then
  echo "Error: Missing one or more required arguments (--port, --chip, --flash_size)."
  exit 1
fi

ARTIFACTS_PATH=/firmware/$CHIP/artifacts

SDKCONFIG=$ARTIFACTS_PATH/sdkconfig
if [ ! -f "$SDKCONFIG" ]; then
	echo "No sdkconfig file at ${SDKCONFIG}"
	exit 1
else
	echo "sdkconfig: ${SDKCONFIG}"
fi

BOOTPATH=$ARTIFACTS_PATH/bootloader.bin
if [ ! -f "$BOOTPATH" ]; then
	echo "No bootloader file at ${BOOTPATH}"
	exit 1
else
	echo "Bootloader: ${BOOTPATH}"
fi

TABLEPATH=$ARTIFACTS_PATH/partition-table.bin
if [ ! -f "$TABLEPATH" ]; then
	echo "No partition table file at ${TABLEPATH}"
	exit 1
else
	echo "Partition table: ${TABLEPATH}"
fi

OTAPATH=$ARTIFACTS_PATH/ota_data_initial.bin
if [ ! -f "$OTAPATH" ]; then
	echo "No otadata file at ${OTAPATH}"
	exit 1
else
	echo "otadata file: ${OTAPATH}"
fi

# locate app binary
IMGNAME=$(ls "$ARTIFACTS_PATH/" | grep -v -e bootloader -e ota_data -e partition | grep "\\.bin$")
if [ -z "$IMGNAME" ]; then
	echo "Could not locate application binary"
	exit 1
fi

IMGPATH="$ARTIFACTS_PATH/${IMGNAME}"
if [ ! -f "$IMGPATH" ]; then
	echo "No binary app file at ${IMGPATH}"
	exit 1
else
	echo "App binary: ${IMGPATH}"
fi

if grep -qE '^CONFIG_SECURE_BOOT_FLASH_BOOTLOADER_DEFAULT=y' "${SDKCONFIG}"; then
	echo "The bootloader should be flashed along with the other artificats"
	BOOTOFF=$(grep -E '^CONFIG_BOOTLOADER_OFFSET_IN_FLASH=' "${SDKCONFIG}" | cut -d'=' -f2)
	if [ -z "$BOOTOFF" ]; then
		echo "CONFIG_BOOTLOADER_OFFSET_IN_FLASH is not set"
		exit 1
	fi
	echo "Bootloader to be flashed at offset $BOOTOFF"
	FLASHBOOT="true"
else
	FLASHBOOT="false"
	echo "The bootloader won't be flashed"
fi

TABLEOFF=$(grep -E '^CONFIG_PARTITION_TABLE_OFFSET=' "${SDKCONFIG}" | cut -d'=' -f2)
if [ -z "$TABLEOFF" ]; then
	echo "CONFIG_PARTITION_TABLE_OFFSET is not set"
	exit 1
fi
echo "Partition table to be flashed at offset $TABLEOFF"

if grep -qE '^CONFIG_PARTITION_TABLE_CUSTOM=y' "${SDKCONFIG}"; then
	echo "Custom partition table, parsing.."
	partitions=$(grep -E '^CONFIG_PARTITION_TABLE_FILENAME=' "${SDKCONFIG}" | cut -d'=' -f2 | sed 's/^"//; s/"$//')
	if [ -z "$partitions" ]; then
		echo "Custom partitions file is not set"
		exit 1
	fi
	partitions="$ARTIFACTS_PATH/${partitions}"
	if [ ! -f "$partitions" ]; then
		echo "Custom partition CSV does not exist"
		exit 1
	fi
	IMGOFF=$(awk -F',' ' $1 ~ /^[[:space:]]*factory[[:space:]]*$/ && $2 ~ /app/ && $3 ~ /factory/ { gsub(/[[:space:]]*/, "", $4); print $4; found=1 } END { if (!found) exit 1 }' "$partitions")
	if [ $? -ne 0 ] || [ -z "$IMGOFF" ]; then
		echo "Factory app partition not found in partitions CSV"
		exit 1
	fi
	OTAOFF=$(awk -F',' ' $1 ~ /^[[:space:]]*otadata[[:space:]]*$/ && $2 ~ /data/ && $3 ~ /ota/ { gsub(/[[:space:]]*/, "", $4); print $4; found=1 } END { if (!found) exit 1 } ' "$partitions")
	if [ $? -ne 0 ] || [ -z "$OTAOFF" ]; then
		echo "otadata partition not found in partitions CSV"
		exit 1
	fi
else
	echo "No custom partition table, parsing sdkconfig"
	if grep -qE '^CONFIG_PARTITION_TABLE_TWO_OTA=y' "${SDKCONFIG}"; then
		IMGOFF=0x20000
		OTAOFF=0x15000
	else
		echo "No OTA partitions defined in sdkconfig, exit"
		exit 1
	fi
fi

echo "PORT              = $PORT"
echo "CHIP              = $CHIP"
echo "FLASH             = $FLASH"
echo "BAUD              = $BAUD"
echo "PARTITION OFFSET  = $TABLEOFF"
echo "APP OFFSET        = $IMGOFF"
echo "OTADATA OFFSET    = $OTAOFF"


if [ "$FLASHBOOT" = "true" ]; then
	echo "BOOTLOADER OFFSET = $BOOTOFF"
	esptool.py --port "$PORT" --chip "$CHIP" --baud $BAUD --no-stub write_flash --flash_size "$FLASH" "$TABLEOFF" "$TABLEPATH" "$IMGOFF" "$IMGPATH" "$OTAOFF" "$OTAPATH" "$BOOTOFF" "$BOOTPATH"
else
	esptool.py --port "$PORT" --chip "$CHIP" --baud $BAUD --no-stub write_flash --flash_size "$FLASH" "$TABLEOFF" "$TABLEPATH" "$IMGOFF" "$IMGPATH" "$OTAOFF" "$OTAPATH"
fi
