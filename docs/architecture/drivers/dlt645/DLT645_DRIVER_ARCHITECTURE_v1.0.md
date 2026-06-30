# DLT645 Driver – Architecture v1.0

**Date:** 2026-07-01  
**Status:** Approved  
**Owner:** CTO / Rust Team  

---

## 1. Overview

The DL/T645 driver is a low‑level component responsible for communicating with Chinese‑standard power meters over RS485. It is a **pure adapter** – it reads, writes, parses, validates, and retries, but contains **no business logic** (DLM, Policy, MQTT, etc.).

---

## 2. Crate Structure

```

crates/dlt645-driver/
├── Cargo.toml
└── src/
├── lib.rs          # Public API (trait MeterDriver)
├── error.rs        # Custom error types (thiserror)
├── types.rs        # Strong types (MeterAddress, DiCode, BcdData, etc.)
├── checksum.rs     # DL/T645 checksum calculation
├── frame.rs        # Frame builder and parser
├── bcd.rs          # BCD decoding with scale factors
├── parser.rs       # Response parser with validation
├── retry.rs        # Exponential backoff retry logic
├── transport.rs    # Transport trait + serial implementation
└── mock.rs         # Mock transport for testing

```

---

## 3. Layered Architecture

```

┌─────────────────────────────────────────────────────────────┐
│                     zinova-core                            │
│                  (Meter Adapter)                           │
└─────────────────────────┬───────────────────────────────────┘
│ uses
▼
┌─────────────────────────────────────────────────────────────┐
│                   dlt645-driver (Rust)                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Public Trait: MeterDriver                          │   │
│  │  - read_parameter(param: DiCode) -> Result<f64>    │   │
│  │  - read_all() -> Result<HashMap<DiCode, f64>>     │   │
│  └─────────────────────┬───────────────────────────────┘   │
│                        │                                    │
│  ┌─────────────────────▼───────────────────────────────┐   │
│  │  Retry Layer (exponential backoff)                 │   │
│  └─────────────────────┬───────────────────────────────┘   │
│                        │                                    │
│  ┌─────────────────────▼───────────────────────────────┐   │
│  │  Parser + Validation (checksum, frame markers)     │   │
│  └─────────────────────┬───────────────────────────────┘   │
│                        │                                    │
│  ┌─────────────────────▼───────────────────────────────┐   │
│  │  Frame Builder (request) + BCD Decoder (response)  │   │
│  └─────────────────────┬───────────────────────────────┘   │
│                        │                                    │
│  ┌─────────────────────▼───────────────────────────────┐   │
│  │  Transport (RS485 via tokio-serial)                │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

```

---

## 4. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| No MQTT inside driver | Separation of concerns; driver only reads/writes bytes |
| No DLM/Policy logic | Brain‑Body separation – driver is pure Body |
| Strong types for DI codes | Compile‑time safety, prevents invalid parameter names |
| Transport trait + Mock | Enables unit/integration testing without hardware |
| Exponential backoff retry | Handles temporary serial errors gracefully |
| Checksum validation on every read | Prevents corrupted data from reaching upper layers |

---

## 5. Error Handling

- All I/O errors are mapped to driver‑specific error types (`DriverError`).
- Retry layer distinguishes between transient (retry) and permanent (fail) errors.
- Timeout is treated as transient up to `max_retries`.

---

## 6. Performance Considerations

- No heap allocations in hot path (frame building/parsing uses fixed‑size arrays).
- BCD decoding is O(1) per parameter.
- Serial read is async (non‑blocking) with configurable timeout.

