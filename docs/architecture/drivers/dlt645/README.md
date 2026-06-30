# DL/T645 Driver – Rust Migration

**Repository:** ZINOVA-CORE  
**Component:** dlt645-driver-rs  
**Status:** In Progress (Sprint 4‑6)  
**Owner:** CTO / Rust Team  

---

## Overview

This directory contains all architecture, design, test, and security documentation for the DL/T645 meter driver being migrated from Python to Rust.

The driver is a **pure adapter** – it reads data from DL/T645‑compliant power meters over RS485, decodes BCD‑encoded values, validates frame integrity, and exposes a clean public API to upper layers (zinova‑core). It contains **no business logic** (DLM, Policy, MQTT) and follows the **Brain‑Body separation** principle.

---

## Documents

| Document | Description |
|----------|-------------|
| `DLT645_DRIVER_RUST_MIGRATION_PLAN_v1.0.md` | Full migration plan (Phases 0‑9, sprint mapping, ADRs, KPIs). |
| `DLT645_DRIVER_ARCHITECTURE_v1.0.md` | Architecture design (Arc42, C4, DDD, Hexagonal, Rust best practices). |
| `DLT645_DRIVER_TEST_STRATEGY_v1.0.md` | Test strategy (ISTQB, ISO 29119, unit/integration/hardware tests, CI/CD). |
| `DLT645_DRIVER_SECURITY_MODEL_ANNEX13_v1.0.md` | Security architecture (IEC 62443, OWASP IoT, NIST, Zero Trust, Annex 13). |

---

## Code Location

The Rust implementation lives in: `services/dlt645-driver-rs/`

```

services/dlt645-driver-rs/
├── Cargo.toml
└── src/
├── lib.rs
├── error.rs
├── types.rs
├── config.rs
├── checksum.rs
├── bcd.rs
├── frame.rs
├── retry.rs
├── transport.rs
├── mock.rs
├── client.rs
└── tests/

```

---

## Quick Links

- [Migration Plan](./DLT645_DRIVER_RUST_MIGRATION_PLAN_v1.0.md)
- [Architecture](./DLT645_DRIVER_ARCHITECTURE_v1.0.md)
- [Test Strategy](./DLT645_DRIVER_TEST_STRATEGY_v1.0.md)
- [Security Model](./DLT645_DRIVER_SECURITY_MODEL_ANNEX13_v1.0.md)

---

## Status

| Phase | Status |
|-------|--------|
| Phase 0 (Foundation) | ✅ Planned |
| Phase 1 (Checksum / BCD) | 🔄 In Progress |
| Phase 2 (Frame / Parser) | ⏳ Pending |
| Phase 3 (Retry) | ⏳ Pending |
| Phase 4 (Transport) | ⏳ Pending |
| Phase 5 (Client API) | ⏳ Pending |
| Phase 6 (Integration) | ⏳ Pending |
| Phase 7 (Dual‑write) | ⏳ Pending |
| Phase 8 (Canary) | ⏳ Pending |
| Phase 9 (Rollout) | ⏳ Pending |

---

**Last Updated:** 2026-07-01  
**Next Review:** 2026-08-15

