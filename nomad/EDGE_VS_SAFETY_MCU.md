```markdown
# ZINOVA NOMAD – RK3566 vs STM32 Responsibility Split

## 1. Philosophy
- **STM32**: Safety‑critical, real‑time, independent of Linux.
- **RK3566**: Smart functions, connectivity, user interface, but **no authority** over safety.

## 2. Exclusive STM32 Responsibilities (Cannot be overridden by RK3566)
- DC leakage detection and trip (6mA)
- AC leakage trip (Type A equivalent)
- Ground / PE monitoring
- Relay control and weld detection
- Pilot signal (CP) generation and monitoring (IEC 61851)
- Over‑temperature shutdown (hard limit 85°C)
- Over‑voltage / under‑voltage immediate reaction
- Watchdog for RK3566 (if RK3566 stops sending heartbeat, STM32 continues charging but logs fault)

## 3. Exclusive RK3566 Responsibilities
- LTE stack, MQTT, OCPP, HTTPS
- OTA download and verification
- User display (if LCD), LED patterns
- Local logging (SQLite / files)
- Time synchronization (NTP)
- Current adjustment button handling (user request → send to STM32)

## 4. Shared / Coordinated Functions
| Function | STM32 | RK3566 |
|----------|-------|--------|
| Current limit | Stores the active limit, enforces | Can request change, but STM32 validates |
| Temperature monitoring | Reads sensor, triggers derating | Reads same sensor (via UART) for display/logging |
| Fault handling | Immediate action, stores fault code | Receives fault code, logs, and uploads |
| Charging statistics (kWh) | Measures (via current*voltage*time) | Reports to cloud |
| Serial number | Stores in EEPROM | Reads and uses for identity |

## 5. Communication Protocol (Isolated UART)
- Frame: `<STX><CMD><LEN><PAYLOAD><CRC><ETX>`
- Heartbeat: RK3566 sends every 1s; if STM32 misses 3 heartbeats, STM32 assumes RK3566 crashed but **continues charging** (safe mode).
- Command examples:
  - `RK3566 → STM32`: `SET_CURRENT 10` (allowed range 6–16)
  - `STM32 → RK3566`: `STATUS` (voltage, current, temp, fault)

## 6. Boot Order
1. STM32 boots first (few ms), waits for RK3566.
2. If RK3566 does not respond within 5s, STM32 enters **safe mode** (charging allowed, no smart features).
3. RK3566 boots Linux (approx 15s), then initiates handshake with STM32.
4. If handshake fails, STM32 remains in safe mode.

## 7. Power Domains
- RK3566 can be reset independently (via STM32 GPIO) without affecting charging (useful for OTA recovery).
- STM32 power is non‑resettable by RK3566.

## 8. Development Responsibility
- Zinova controls both firmware codebases (STM32 and RK3566). OEM only assembles and runs factory tests, **does not modify firmware**.
```

---
