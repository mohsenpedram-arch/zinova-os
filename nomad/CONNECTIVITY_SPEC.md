
```markdown
# ZINOVA NOMAD – Connectivity Specification

## 1. Cellular Module Requirements
| Parameter | Requirement |
|-----------|-------------|
| Form factor | Mini PCIe or LGA (industrial grade) |
| LTE category | Cat 4 minimum (for reliable MQTT) |
| Fallback | 3G (WCDMA) fallback required |
| Bands | Global bands or specific to Iran (B3, B7, B20, B28 preferred) |
| Temperature range | -30°C to +75°C |
| SIM interface | Nano SIM (4FF) mandatory + eSIM optional |

## 2. SIM / eSIM Architecture
- **Nano SIM slot**: accessible externally (under sealed cover) for operator SIM.
- **eSIM (optional)**: programmed with Zinova global roaming profile as failover.
- Behavior: primary = Nano SIM; if no service for 5 minutes, fallback to eSIM.
- Device reports active SIM type in heartbeat.

## 3. Antenna
- External SMA connector or internal PCB antenna with gain >2dBi.
- Antenna placement ensures >-80dBm RSSI in typical use.

## 4. MQTT & Network Parameters
| Parameter | Value |
|-----------|-------|
| MQTT broker | `mqtt.zinova.com:8883` (TLS) |
| Keepalive | 60s |
| Clean session | False (persistent) |
| QoS for telemetry | 0 (loss tolerated) |
| QoS for events | 1 (ack required) |
| Maximum offline queue | 5000 messages (FIFO, oldest dropped) |

## 5. Offline Behavior Rules (Critical)
- Charging **never** requires network.
- If network down:
  - Device continues charging with last valid config.
  - Logs all events locally (eMMC).
  - Tries to reconnect every 30s (exponential backoff up to 5min).
  - Once back online, replays stored events (with timestamps).
- No network → no telemetry, but safety unaffected.

## 6. Connectivity LEDs
- Green solid: connected to LTE, MQTT OK.
- Green flashing: LTE registered, MQTT connecting.
- Orange: No LTE, but charging allowed.
- Red: SIM error or permanent network failure (report only).

## 7. APN Configuration
- APN must be configurable via OTA (for different operators).
- Default APN is pre‑set for primary market (Iran MCI or Irancell).

## 8. Data Usage Budget
- Telemetry (30s interval): ~2MB per month.
- OTA (once per quarter max): ~25MB per update.
- Total < 50MB/month → suitable for low‑cost data plans.

## 9. Factory Provisioning
- Each device is flashed with unique client certificate for mTLS.
- SIM ICCID and IMEI are recorded in Zinova database but not hard‑locked (allows field SIM change).
```

---
