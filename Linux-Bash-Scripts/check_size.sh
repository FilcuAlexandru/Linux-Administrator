#!/bin/bash

# Check if a path argument was provided
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/directory"
    exit 1
fi

BASE_PATH="$1"
OUTPUT_FILE="output.txt"
LOG_FILE="check_status.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Script started. Scanning: $BASE_PATH" >> "$LOG_FILE"

# Check if the directory exists
if [ ! -d "$BASE_PATH" ]; then
    echo "Directory $BASE_PATH does not exist." | tee -a "$LOG_FILE"
    exit 1
fi

# Clear the output file
> "$OUTPUT_FILE"

# Loop through subdirectories
for dir in "$BASE_PATH"/*/; do
    if [ -d "$dir" ]; then
        echo "Checking size for: $dir" | tee -a "$LOG_FILE"
        echo "Checking size for: $dir" >> "$OUTPUT_FILE"

        size=$(du -s --block-size=1G "$dir" 2>>"$LOG_FILE" | cut -f1)
        echo " → $(basename "$dir"): ${size} GB" | tee -a "$OUTPUT_FILE" "$LOG_FILE"
    fi
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Script finished." >> "$LOG_FILE"
