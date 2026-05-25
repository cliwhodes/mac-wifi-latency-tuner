# Faster Network Action Plan

Router admin: `https://192.168.1.1` (adjust if your gateway differs)

## Current Measurements

- Wi-Fi band: 5 GHz
- Wi-Fi mode: 802.11ax
- Current channel: 56
- Current channel width: 160 MHz
- Signal/noise: -54 dBm / -94 dBm
- Link rate: 1441 Mbps
- Router ping: 0% loss, 2.8 ms min, 11.8 ms avg, 73.4 ms max
- Internet ping to 8.8.8.8: 0% loss, 9.2 ms min, 15.1 ms avg, 69.1 ms max
- Apple network quality: 196.7 Mbps down, 501.9 Mbps up
- Loaded responsiveness: 173 ms

Latest spot check:

- The router is still on 5 GHz channel 56 at 160 MHz.
- Idle latency is currently excellent: router max about 4 ms, internet max
  about 10 ms.
- A later Apple network quality run improved to 260.9 Mbps down, 527.0 Mbps up,
  with loaded responsiveness at 85.0 ms.
- Because this improved without a router setting change, the issue is
  intermittent rather than a constant line-speed fault.

Safe Mac-side refresh performed:

- Flushed local DNS cache.
- Restarted Wi-Fi.
- Reconnected to the same Wi-Fi network.
- Got a fresh local IP on Wi-Fi.
- Left router/modem settings unchanged.
- Left DNS servers unchanged because ISP DNS tested fastest.
- Did not delete profiles, change MTU, reset network settings, or kill apps.

Latest post-refresh result:

- Router max ping: 4.6 ms.
- Internet max ping: 10.4 ms.
- Download: 264.8 Mbps.
- Upload: 443.5 Mbps.
- Loaded responsiveness: 88.9 ms.
- Status from comparison script: good; latest latency and loaded
  responsiveness are in the target range.

Additional local usage check:

- Chrome currently has the highest number of active TCP connections.
- Claude/Codex traffic is also active because this diagnostic session is
  running.
- The Wi-Fi interface reports 0 packet errors, so the Mac adapter itself does
  not look faulty.

## Diagnosis

The connection has good raw bandwidth and no packet loss. The main problem is
latency spikes, including spikes to the local router. That points to Wi-Fi
channel behavior, local airtime contention, or router queueing rather than DNS
or a simple ISP speed cap.

## Change These Router Settings

Open your router admin page (usually `https://192.168.1.1`) and look for the wireless/WLAN settings. The exact menu path varies by router model — look for "5 GHz" channel width settings.

For the 5 GHz network:

- Change channel width from `160 MHz` to `80 MHz`.
- Change channel from `Auto` or `56` to one of these, in this order:
  - `149`
  - `153`
  - `157`
  - `161`
  - If those are unavailable: `36`, `40`, `44`, or `48`
- Keep 5 GHz mode at `a/n/ac/ax` or the closest Wi-Fi 6 option.
- Keep transmit power at high/default.
- Keep DNS as-is. Current ISP DNS is faster than 1.1.1.1 and 8.8.8.8 here.

For the 2.4 GHz network:

- Use 20 MHz channel width.
- Use channel 1, 6, or 11 only.
- Prefer channel 1 or 6 based on the current scan; channel 11 is also present
  nearby.

## Optional If Available

Enable QoS/SQM/Smart Queue Management if the router provides it.

Use these initial shaping values:

- Download: 180 Mbps
- Upload: 450 Mbps

If the router uses Kbps:

- Download: 180000 Kbps
- Upload: 450000 Kbps

## Verify After Applying

Reconnect Wi-Fi, then run the all-in-one post-change check:

```bash
./after-router-change.sh
```

Or run the pieces manually. Wait 60 seconds, then run:

```bash
./network-retune-check.sh
```

Then summarize the logged before/after rows:

```bash
./compare-network-results.sh
```

If the network feels slow but the router settings have not changed, also run:

```bash
./network-usage-now.sh
```

If Chrome is at the top with many connections, close heavy tabs, pause downloads,
stop cloud web apps, or quit Chrome briefly and re-run the retune check. This
separates Wi-Fi/router latency from app-generated load.

The change worked if:

- Router max ping is consistently below 30 ms.
- Internet max ping is consistently below 40 ms.
- Apple loaded responsiveness drops meaningfully below 100 ms.
- Down/up bandwidth remains acceptable for the internet plan.

If bandwidth drops too much but latency improves, try 80 MHz on channel 36 or
149 and compare. If latency does not improve, the next step is either enabling
SQM on a better router or asking PLDT to bridge the F6600P to a third-party
router with SQM support.
