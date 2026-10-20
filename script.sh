#!/bin/bash

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
