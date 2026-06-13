
# ZINOVA NOMAD – Product Definition

## 1. What is Nomad?
Nomad is a **portable Mode 2 AC EV charger** (IC-CPD / ICCB) designed for emergency, residential, and temporary charging in markets with unstable grid and socket quality (first target: Iran). It is **not a wallbox replacement**.

## 2. What Nomad is NOT
- Not a permanent installation
- Not a DC fast charger
- Not a connected smart charger (cloud control forbidden)
- Not a high-power (>3.7kW) device

## 3. Use Case (Real)
- A driver runs out of charge and needs to plug into any standard 16A household socket.
- A home without a dedicated wallbox needs occasional charging.
- Temporary charging at workshops, rural areas, or events.
- Emergency backup when public charging fails.

## 4. Target Market Constraints
| Constraint | Implication |
|------------|--------------|
| Unreliable socket quality | Mandatory plug temperature sensor |
| Missing or poor grounding | Mandatory PE detection before start |
| Voltage fluctuations (207–253V) | Wide input range, under/over voltage protection |
| High ambient temperature (up to +55°C) | Derating and thermal shutdown |
| Dust and rain | IP65 control box, IP54 connector |
| No cloud dependency | Full offline operation, local decisions |

## 5. Core Positioning Statement
> *Nomad is the safest portable EV charger for unreliable grids. It protects the user, the vehicle, and the building – even when the building doesn't protect itself.*

## 6. Non‑Negotiable Features (Locked)
- 6mA DC leakage detection (Type B equivalent or dedicated DC)
- Ground / PE detection before charging
- Plug temperature sensor (mandatory)
- Adjustable current (6/8/10/13/16A)
- Mode 2 ICCB with IEC 62752
- IP65 control box
- Serial number traceability

## 7. Out of Scope for Alpha
- WiFi, Bluetooth, App
- Cloud billing or remote start/stop
- ISO 15118 (Plug & Charge)
- LCD as mandatory (optional only)
