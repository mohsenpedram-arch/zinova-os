# Mode 3 Charging (IEC 61851‑1)

## Definition
Dedicated EV charging station (wallbox) with a fixed cable or socket. Uses **control pilot (CP)** and may include communication protocols like OCPP.

## Differences from Mode 2
| Feature | Mode 2 | Mode 3 |
|---------|--------|--------|
| Installation | Portable, plug‑in | Fixed, requires electrician |
| Max power | 3.7 kW (single‑phase) | 22 kW (three‑phase) or higher |
| Communication | Basic CP | CP + optional PLC or OCPP |
| RCD | Inside IC‑CPD (Type A + 6 mA DC) | Often external Type B |
| Smart charging | No | Yes (load balancing, scheduling) |

## Relevance to Zinova
- Future product: Zinova Nomad+ could support Mode 3 with fixed wallbox.
- Sourcing for Mode 3 requires additional components: OCPP stack, RFID, dynamic load management.

## When sourcing Mode 3 wallboxes
- Look for OCPP 1.6 or 2.0.1 certification.
- Require MID‑certified energy meter (if billing required).
- Ask for grid protection (over‑voltage, under‑voltage, surge).
