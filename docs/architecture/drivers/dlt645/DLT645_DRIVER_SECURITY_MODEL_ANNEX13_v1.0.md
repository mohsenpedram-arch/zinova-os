# DLT645 Driver – Security Model (Annex 13) v1.0

**Date:** 2026-07-01  
**Status:** Approved  
**Owner:** CTO / Security Team  

---

## 1. Context

The DL/T645 driver communicates over RS485, a physical serial bus that is inherently **unauthenticated and unencrypted**. While this is common in industrial environments, it poses risks:

- Eavesdropping (data leakage)
- Frame injection (false readings)
- Replay attacks (stale data)

This document defines security controls aligned with **Annex 13** (Zero Trust, Defence in Depth).

---

## 2. Threat Model

| Threat | Impact | Likelihood | Mitigation |
|--------|--------|------------|------------|
| Unauthorised physical access to RS485 bus | Data tampering, false commands | Medium | Physical enclosure + tamper‑evident seals |
| Eavesdropping on RS485 | Exposure of meter readings (energy, power) | Medium | None at transport layer; data is not sensitive enough for encryption (but may be signed) |
| Frame injection (spoofed meter responses) | False DLM decisions, grid instability | Low (requires physical access) | HMAC‑SHA256 per frame (optional, configurable) |
| Replay of old frames | Stale data used for DLM | Low | Timestamp in frame (not supported by standard) → rely on retry/timeout detection |
| Meter impersonation | Readings from wrong meter | Medium | Meter address validation in frame |

---

## 3. Security Controls (Annex 13 Compliance)

| Annex 13 Layer | Implementation | Status |
|----------------|----------------|--------|
| **L1: Device Identity** | Meter address is validated in every request/response frame. Driver rejects responses with mismatched address. | ✅ Planned |
| **L2: Secure Communication (Transport)** | RS485 is physical – no encryption. **Optional HMAC‑SHA256** can be added on top of the frame (custom extension) to detect tampering. | ⚠️ Configurable |
| **L3: Data Integrity** | Checksum (native DL/T645) provides basic integrity. HMAC provides stronger integrity if enabled. | ✅ Native checksum + optional HMAC |
| **L4: Audit & Logging** | All read attempts (success/failure) logged with timestamp, meter address, parameter, and result. | ✅ Planned |
| **L5: Fail‑Safe Defaults** | On communication failure, driver returns `None` (not stale data). Upper layers treat as degraded meter. | ✅ Designed |

---

## 4. HMAC‑SHA256 Extension (Optional)

If enabled via configuration:

- Each request includes a random nonce.
- Meter (or a gateway) computes HMAC over the frame + nonce and appends it.
- Driver verifies HMAC before parsing.

**Trade‑off:** Adds overhead, requires meter/gateway support. **Default: OFF** for compatibility.

---

## 5. Key Management

- HMAC key is stored in a secure configuration file (readable only by `root`).
- Key rotation is manual (planned for future automated rotation).

---

## 6. Audit Events

| Event | Logged Fields |
|-------|---------------|
| Read success | meter_addr, param_name, value, timestamp |
| Read failure | meter_addr, param_name, error_type, retry_count |
| HMAC mismatch | meter_addr, param_name, calculated_hmac, received_hmac |
| Transport error | meter_addr, error_kind, timestamp |

All logs are sent to the central audit log (via `telemetry` module) for compliance.

---

## 7. Compliance Checklist

- [x] Meter address validation on every frame.
- [x] Checksum validation on every response.
- [x] Retry on transient errors (no stale data).
- [x] Audit logging of all operations.
- [x] Configurable HMAC for integrity (disabled by default).
- [x] Fail‑safe: return `None` on error, not cached data.

