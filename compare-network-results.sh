#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
log_file="${script_dir}/network-retune-results.csv"

if [[ ! -f "${log_file}" ]]; then
  echo "No log file found at ${log_file}"
  echo "Run network-retune-check.sh first."
  exit 1
fi

awk -F',' '
NR == 1 { next }
{
  rows++
  ts[rows]=$1
  channel[rows]=$2
  signal[rows]=$3
  tx[rows]=$4
  router_max[rows]=$7 + 0
  internet_max[rows]=$10 + 0
  down[rows]=$11 + 0
  up[rows]=$12 + 0
  resp[rows]=$13 + 0
  idle[rows]=$14 + 0
}
END {
  if (rows == 0) {
    print "No measurements found."
    exit 1
  }

  first=1
  last=rows

  printf "Measurements: %d\n\n", rows
  printf "%-24s %-22s %8s %8s %10s %10s %10s %10s\n", "Time", "Channel", "RouterMax", "NetMax", "Down", "Up", "Loaded", "Idle"
  for (i=1; i<=rows; i++) {
    printf "%-24s %-22s %8.1f %8.1f %10.1f %10.1f %10.1f %10.1f\n", ts[i], channel[i], router_max[i], internet_max[i], down[i], up[i], resp[i], idle[i]
  }

  if (rows > 1) {
    print ""
    printf "Change from first to latest:\n"
    printf "  Router max ping:       %+0.1f ms\n", router_max[last] - router_max[first]
    printf "  Internet max ping:     %+0.1f ms\n", internet_max[last] - internet_max[first]
    printf "  Loaded responsiveness: %+0.1f ms\n", resp[last] - resp[first]
    printf "  Download:              %+0.1f Mbps\n", down[last] - down[first]
    printf "  Upload:                %+0.1f Mbps\n", up[last] - up[first]
  }

  print ""
  if (router_max[last] <= 30 && internet_max[last] <= 40 && resp[last] > 0 && resp[last] <= 100) {
    print "Status: Good. Latency and loaded responsiveness are in the target range."
  } else if (router_max[last] <= 30 && internet_max[last] <= 40) {
    print "Status: Idle latency is good, but loaded responsiveness still needs router queueing/QoS improvement."
  } else {
    print "Status: Latency spikes remain. Prioritize 5 GHz 80 MHz channel tuning and SQM/QoS."
  }
}' "${log_file}"
