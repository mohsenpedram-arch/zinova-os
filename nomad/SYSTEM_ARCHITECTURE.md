
# ZINOVA NOMAD – System Architecture

## 1. High-Level Block Diagram
```

┌─────────────────────────────────────────────────────────────┐
│                     AC Input (230V, 16A)                     │
│                         (Heavy-duty plug)                     │
└─────────────────────────────┬───────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│                    Power & Protection Layer                  │
│  • Relay / Contactor (≥20A)                                 │
│  • AC RCD (Type A equivalent)                               │
│  • DC Leakage Detection (6mA)                               │
│  • Over/Under voltage, Overcurrent, Short circuit           │
│  • Temperature sensors (plug, box, optional connector)      │
└─────────────────────────────┬───────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│                    Safety MCU Domain (STM32)                 │
│  • Real-time monitoring: leakage, temp, voltage, current    │
│  • PWM pilot (CP) generation and monitoring (IEC 61851)     │
│  • PP resistor decoding                                     │
│  • Relay control and weld detection                         │
│  • Emergency stop and fault reaction (hard cutoff)          │
│  • Watchdog for Edge domain                                 │
└─────────────────────────────┬───────────────────────────────┘
│ (UART / SPI / isolated)
▼
┌─────────────────────────────────────────────────────────────┐
│                    Edge Compute Domain (RK3566)              │
│  • Linux (Yocto)                                            │
│  • Telemetry aggregation                                     │
│  • MQTT client (over LTE)                                   │
│  • OCPP 1.6 JSON (session management)                       │
│  • OTA update handler                                       │
│  • Local logging and event storage                          │
│  • No direct power control (requests to STM32 only)         │
└─────────────────────────────┬───────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│                    Connectivity Layer (LTE + SIM/eSIM)       │
│  • Industrial LTE module                                    │
│  • Nano SIM (mandatory) + eSIM (optional failover)          │
│  • MQTT over TLS                                            │
│  • HTTPS for OTA and config                                 │
└─────────────────────────────────────────────────────────────┘

```

## 2. Power Control Authority Rule
| Component | Authority |
|-----------|-----------|
| STM32 (Safety MCU) | **Final authority** – can cut relay independently |
| RK3566 (Edge) | Can request current change, but cannot bypass STM32 |
| Cloud | **No direct power control** – only config and telemetry |

## 3. Communication Flow
- **Telemetry (MQTT)** → Periodic (every 30s) and on event (fault, start, stop)
- **Charging session (OCPP)** → StartTransaction, StopTransaction, MeterValues
- **OTA (HTTPS)** → Firmware download → signature check → RK3566 update → STM32 update via local bus
- **Configuration (HTTPS/REST)** → Current limits, regional settings

## 4. Offline Mode Rules
- Charging **must** work with no LTE signal.
- All safety functions remain active (STM32 independent).
- Logs stored locally and uploaded when connectivity returns.
- No cloud authentication required to start charging.

## 5. Partition of Responsibilities

| Function | Owner |
|----------|-------|
| Leakage trip | STM32 (hardware interrupt) |
| Over-temperature derating | STM32 (immediate) |
| Pilot signal (CP) | STM32 |
| Current adjustment request | User button → RK3566 → STM32 |
| OTA download | RK3566 |
| Telemetry formatting | RK3566 |
| Fault history storage | RK3566 (SQLite / file) |
| Display/LCD if present | RK3566 |
```

---
