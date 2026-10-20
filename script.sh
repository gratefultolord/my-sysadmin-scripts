#!/bin/bash

INTERVAL="${1:-5}"
if ! [[ "$INTERVAL" =~ ^[1-9][0-9]*$ ]]; then
	echo "Error: interval must be a positive integer without leading zeros" >&2
	exit 1
fi
LOG_FILE="monitor.log"

while true; do
    {
        echo "=== System Monitor ==="
        echo "Date: $(date)"

        echo
        echo "--- Uptime ---"
        uptime

        echo
        echo "--- Memory ---"
        free -h

        echo
        echo "--- Disk ---"
        df -h

        echo
        echo "======================"
    } >> "$LOG_FILE"

    sleep "$INTERVAL"
done



