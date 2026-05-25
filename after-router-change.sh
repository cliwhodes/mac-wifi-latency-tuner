#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

echo "Waiting 60 seconds for Wi-Fi/router settings to settle..."
sleep 60

echo
echo "Running network retune check..."
"${script_dir}/network-retune-check.sh"

echo
echo "Comparing logged results..."
"${script_dir}/compare-network-results.sh"

echo
echo "If the latest row still shows 160 MHz, reconnect Wi-Fi or confirm the router saved the 80 MHz setting."
