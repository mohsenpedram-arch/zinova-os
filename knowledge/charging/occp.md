
# OCPP – Open Charge Point Protocol

## What is OCPP?
Open standard for communication between EV charging stations (charge points) and a central management system (CSMS). Developed by the Open Charge Alliance.

## Versions
| Version | Format | Key features |
|---------|--------|---------------|
| 1.5 | SOAP | Legacy, rarely used |
| 1.6 | JSON (OCPP‑J) | Most common. Supports smart charging, local auth list, firmware update. |
| 2.0.1 | JSON | Improved security, device model, transactions. |

## Mandatory OCPP features for Zinova (future products)
- **Start/stop transaction** (remote stop is allowed, remote start may be allowed with authentication).
- **MeterValues** – energy delivered (Wh).
- **Heartbeat** – keep connection alive.
- **BootNotification** – identify charge point to central system.
- **Firmware update** – OTA via OCPP.

## OCPP 1.6 security
- Basic authentication (username/password) or TLS client certificates.
- Recommended: TLS with certificates (mTLS) for production.

## For sourcing agents
- If a wallbox claims OCPP support, ask for **OCPP certification** or successful integration test with a known CSMS (e.g., SteVe, EVerest).
- Beware of “OCPP ready” but no actual implementation.
