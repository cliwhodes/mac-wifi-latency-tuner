#!/usr/bin/env bash
set -euo pipefail

gateway="$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2; exit}')"
script_dir="$(cd "$(dirname "$0")" && pwd)"
log_file="${script_dir}/network-retune-results.csv"
timestamp="$(date '+%Y-%m-%d %H:%M:%S %z')"
wifi_summary="$(mktemp)"
router_ping="$(mktemp)"
internet_ping="$(mktemp)"
quality_output="$(mktemp)"
trap 'rm -f "${wifi_summary}" "${router_ping}" "${internet_ping}" "${quality_output}"' EXIT

echo "== Wi-Fi link =="
system_profiler SPAirPortDataType 2>/dev/null \
  | awk '/Current Network Information:/,/Other Local Wi-Fi Networks:|awdl0:/' \
  | awk '/PHY Mode:|Channel:|Signal \/ Noise:|Transmit Rate:/ {print}' \
  | tee "${wifi_summary}"

echo
echo "== Router latency =="
if [[ -n "${gateway}" ]]; then
  ping -c 30 -i 0.2 "${gateway}" | tee "${router_ping}" | tail -n 2
else
  echo "No default gateway found."
fi

echo
echo "== Internet latency =="
ping -c 30 -i 0.2 8.8.8.8 | tee "${internet_ping}" | tail -n 2

echo
echo "== DNS response =="
for server in 1.1.1.1 8.8.8.8 9.9.9.9; do
  printf "%-15s " "${server}"
  dig @"${server}" +time=2 +tries=1 google.com \
    | awk '/Query time/ {print $4 " ms"; found=1} END {if (!found) print "timeout"}'
done

echo
echo "== Apple network quality =="
networkQuality -v | tee "${quality_output}"

if [[ ! -f "${log_file}" ]]; then
  echo "timestamp,channel,signal_dbm,tx_rate_mbps,router_min_ms,router_avg_ms,router_max_ms,internet_min_ms,internet_avg_ms,internet_max_ms,down_mbps,up_mbps,responsiveness_ms,idle_latency_ms" > "${log_file}"
fi

channel="$(awk -F': ' '/Channel:/ {print $2; exit}' "${wifi_summary}" | tr ',' ';')"
signal="$(awk '/Signal \/ Noise:/ {print $4; exit}' "${wifi_summary}")"
tx_rate="$(awk '/Transmit Rate:/ {print $3; exit}' "${wifi_summary}")"
router_stats="$(awk -F' = ' '/round-trip/ {split($2,a,"/"); print a[1] "," a[2] "," a[3]; exit}' "${router_ping}")"
internet_stats="$(awk -F' = ' '/round-trip/ {split($2,a,"/"); print a[1] "," a[2] "," a[3]; exit}' "${internet_ping}")"
down="$(awk -F': ' '/Downlink capacity:/ {print $2; exit}' "${quality_output}" | awk '{print $1}')"
up="$(awk -F': ' '/Uplink capacity:/ {print $2; exit}' "${quality_output}" | awk '{print $1}')"
resp="$(awk -F'[()]' '/Responsiveness: Medium/ {value=$2} END {print value}' "${quality_output}" | awk '{print $1}')"
idle="$(awk -F'[()]' '
  /Idle Latency:/ {capture=1; next}
  capture && /\([0-9.]+ milliseconds\)/ {print $2; exit}
' "${quality_output}" | awk '{print $1}')"

echo "${timestamp},${channel},${signal},${tx_rate},${router_stats},${internet_stats},${down},${up},${resp},${idle}" >> "${log_file}"

echo
echo "Logged result to ${log_file}"
