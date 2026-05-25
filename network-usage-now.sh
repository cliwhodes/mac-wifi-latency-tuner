#!/usr/bin/env bash
set -euo pipefail

echo "== Top network users =="
nettop -P -L 1 -x -J bytes_in,bytes_out 2>/dev/null \
  | awk -F',' '
    NR > 1 && $1 != "" {
      gsub(/^[ \t]+|[ \t]+$/, "", $1)
      inb=$2+0
      outb=$3+0
      total=inb+outb
      if (total > 0) {
        printf "%12.1f MB  in=%8.1f MB  out=%8.1f MB  %s\n", total/1048576, inb/1048576, outb/1048576, $1
      }
    }' \
  | sort -nr \
  | head -n 20

echo
echo "== Established TCP connection counts =="
lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null \
  | awk 'NR > 1 {count[$1]++} END {for (app in count) printf "%5d  %s\n", count[app], app}' \
  | sort -nr \
  | head -n 20

echo
echo "== Wi-Fi health =="
system_profiler SPAirPortDataType 2>/dev/null \
  | awk '/Current Network Information:/,/Other Local Wi-Fi Networks:|awdl0:/' \
  | awk '/PHY Mode:|Channel:|Signal \/ Noise:|Transmit Rate:/ {print}'

echo
echo "== Interface errors =="
netstat -ibn | awk 'NR==1 || $1=="en0" {print}'
