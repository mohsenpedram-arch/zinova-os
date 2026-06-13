```markdown
# ZINOVA NOMAD – Protocol Specification

## 1. MQTT (Telemetry & Heartbeat)

### Transport
- MQTT 3.1.1 over TLS 1.2
- Keepalive: 60s
- QoS 1 for critical events, QoS 0 for periodic

### Topics (Outbound from Nomad)

| Topic | Payload | Interval |
|-------|---------|----------|
| `zinova/nomad/[SERIAL]/telemetry` | JSON (V, I, P, temp, state) | 30s |
| `zinova/nomad/[SERIAL]/event` | JSON (fault code, start, stop) | On event |
| `zinova/nomad/[SERIAL]/heartbeat` | JSON (uptime, rssi) | 60s |

### JSON Telemetry Example
```json
{
  "serial": "ZN2401001",
  "ts": 1710000000,
  "V": 228,
  "I": 13.2,
  "P": 3010,
  "temp_plug": 52,
  "temp_box": 48,
  "state": "CHARGING",
  "fault_active": false
}
```

Inbound MQTT (config)

· zinova/nomad/[SERIAL]/config/set → new current limit, regional mode (subject to STM32 approval)

2. OCPP 1.6 (Session Management)

Profiles Supported

· Core (mandatory)
· Local Auth List (optional)
· Firmware Management (for OTA status)

OCPP over WebSocket (or HTTPS fallback)

· Endpoint: wss://ocpp.zinova.com/{serial}/{chargeBoxId}
· Authentication: Basic auth or TLS client cert

Mandatory Calls (Nomad → Central)

· BootNotification
· Heartbeat
· StartTransaction
· StopTransaction
· MeterValues (every 60s while charging)

Mandatory Calls (Central → Nomad)

· RemoteStartTransaction → ignored (cloud forbidden to start)
· RemoteStopTransaction → accepted (emergency stop from cloud allowed)
· ChangeConfiguration (current limit) → accepted but subject to local safety
· GetDiagnostics

OCPP vs MQTT Separation

· OCPP only for session start/stop and meter values.
· MQTT only for real‑time telemetry and config.

3. HTTPS REST (OTA & Config Fallback)

Endpoints

· GET https://ota.zinova.com/v1/nomad/{serial}/firmware/latest
· POST https://api.zinova.com/v1/nomad/{serial}/config (used when MQTT down)

Authentication

· mTLS (client certificate provisioned at factory)

Response format (JSON)

```json
{
  "version": "1.2.0",
  "url": "https://cdn.zinova.com/nomad/1.2.0.rk3566.bin",
  "sha256": "abc123...",
  "size": 24576000,
  "mandatory": true
}
```

4. Local (STM32 – RK3566) Protocol

· UART at 115200 baud, 8N1, isolated.
· Simple command/response frame:

```
STX | CMD | LEN | PAYLOAD | CRC16 | ETX
```

· Commands:
  · 0x01 – Get status (V, I, temp, fault)
  · 0x02 – Set current limit (6–16A)
  · 0x03 – Close relay (only after safety checks)
  · 0x04 – Open relay
  · 0x05 – Get fault history
· Safety: STM32 can reject any command that violates its own safety checks.

5. Device Identity Model

· Serial Number (printed + eMMC)
· Manufacturing Certificate (issued by Zinova CA)
· LTE IMEI bound to serial in factory database
· SIM ICCID logged but not hard-bound (allows SIM swap)

6. Cloud Limitation Rules (Hardcoded in RK3566)

· No cloud command shall start a charging session.
· Remote current limit changes must be between 6–16A and cannot override plug temperature derating.
· Cloud cannot disable local safety features.
· If cloud connectivity is lost, device continues charging with last valid configuration.

```

---
