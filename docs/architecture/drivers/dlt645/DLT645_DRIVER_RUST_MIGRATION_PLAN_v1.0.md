# DLT645 Driver – Rust Migration Plan v1.0

**Document Type:** Enterprise Migration Plan  
**Version:** 1.0  
**Date:** 2026-07-01  
**Status:** Approved  
**Owner:** CTO / Rust Team  
**Classification:** Internal  

---

## 1. Executive Summary

This document defines the complete migration strategy for the DL/T645 meter driver from Python to Rust. The migration is driven by the need for improved memory safety, performance, and architectural alignment with ZINOVA’s Edge‑First and Brain‑Body separation principles. The migration will be executed in **10 phases (Phase 0 – Phase 9)** over **3 sprints**, following Agile/Scrum methodology with continuous integration and delivery.

The new Rust driver will be a **pure adapter** – it reads, writes, parses, validates, and retries, but contains **no business logic** (DLM, Policy, MQTT). It will be integrated into `zinova-core` via a `MeterAdapter` trait and will replace the existing Python driver with zero downtime using a blue‑green deployment strategy.

---

## 2. Business Drivers

| Driver | Description |
|--------|-------------|
| **Edge‑First Architecture** | All real‑time decisions (DLM) must run on the edge device (Robustel). A reliable, low‑latency meter driver is critical. |
| **Operational Resilience** | RS485 communication is prone to transient errors. Rust’s strong error handling and retry logic improve system stability. |
| **Maintenance Cost** | Python driver requires frequent bug fixes for memory/type issues. Rust reduces runtime errors and maintenance overhead. |
| **Talent Strategy** | Core team is shifting to Rust for all edge components. Keeping the driver in Python creates a skills gap and increases bus factor. |
| **Security Compliance** | Annex 13 mandates secure coding practices and memory safety. Rust is the only language that guarantees memory safety without GC. |
| **Performance** | Rust driver will consume less CPU and memory, leaving more resources for DLM and OCPP on the edge device. |

---

## 3. Technical Drivers

| Driver | Description |
|--------|-------------|
| **Memory Safety** | Rust eliminates buffer overflows, use‑after‑free, and null pointer dereferences – critical for embedded systems. |
| **Concurrency** | `tokio` enables efficient async I/O on RS485 without blocking the main loop. |
| **Strong Typing** | Encode protocol constants (DI codes, BCD scales) as types to prevent invalid parameters at compile time. |
| **Error Handling** | `Result` and `Option` force explicit handling of all failure cases, reducing hidden bugs. |
| **Testability** | Rust’s built‑in test framework and `#[cfg(test)]` make unit testing seamless. |
| **Integration** | The driver will be a separate crate, following Hexagonal Architecture, with a well‑defined public interface. |
| **Zero‑Cost Abstractions** | No runtime overhead for abstractions – performance comparable to C. |

---

## 4. Existing Python Driver Assessment

### 4.1 Strengths
- Functional and stable in production.
- Good separation of concerns (DLT645Master, MQTT publisher, main loop).
- BCD decoding and checksum logic are correct.

### 4.2 Weaknesses
- **No strong typing** – DI codes are strings, risk of typos.
- **No retry logic** – single attempt per read, fails on transient errors.
- **Serial I/O is blocking** – uses `time.sleep()` and blocking reads, not suitable for async edge runtime.
- **Mixed responsibilities** – MQTT publishing is inside the driver, violating Brain‑Body separation.
- **No unit tests** – only manual testing with real hardware.
- **No error recovery** – if meter is offline, driver keeps retrying without backoff.
- **No health monitoring** – upper layers have no visibility into meter state.

### 4.3 Technical Debt Identified
- BCD decoding logic is duplicated.
- No separation between transport and protocol layers.
- Configuration (port, baudrate, meter address) is hardcoded via env vars, not validated.
- No logging of failed reads for audit.

---

## 5. Migration Objectives

| Objective | Target |
|-----------|--------|
| **Functionality** | 100% feature parity with Python driver (all DI codes, BCD decoding, checksum validation). |
| **Performance** | Read all parameters in < 2 seconds (Python currently ~3‑5 seconds). |
| **Memory Usage** | < 10 MB RSS (Python driver uses ~30 MB). |
| **CPU Usage** | < 5% average (Python driver uses ~10‑15%). |
| **Resilience** | Retry up to 3 times with exponential backoff; return `None` on failure (no stale data). |
| **Test Coverage** | > 90% unit test coverage, 100% of protocol logic. |
| **Security** | Compliant with Annex 13 (audit logging, HMAC optional, fail‑safe defaults). |
| **Maintainability** | Clean Architecture with clear separation of transport, protocol, and business logic. |

---

## 6. Migration Principles

| Principle | Description |
|-----------|-------------|
| **Brain‑Body Separation** | Driver is pure Body – no DLM, Policy, or MQTT. |
| **Edge‑First** | Driver runs on edge; all critical decisions happen locally. |
| **Fail‑Safe** | On error, return `None` – never use stale/cached data. |
| **Zero Trust** | Validate every frame; treat all data as untrusted. |
| **Defence in Depth** | Checksum + optional HMAC + audit logging. |
| **Test‑Driven** | Write tests before code (TDD) for all protocol logic. |
| **Incremental Migration** | Replace Python driver only after Rust driver passes all acceptance tests. |
| **No Downtime** | Blue‑green deployment – switch traffic after validation. |

---

## 7. Architecture Vision

The new driver follows **Hexagonal Architecture** (Ports & Adapters):

```

┌─────────────────────────────────────────────────────────────────┐
│                    dlt645-driver (crate)                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    Domain (Protocol)                     │ │
│  │  - MeterDriver trait (port)                              │ │
│  │  - DI codes, BCD, Frame, Checksum                       │ │
│  └───────────────────────────┬───────────────────────────────┘ │
│                              │                                  │
│  ┌───────────────────────────▼───────────────────────────────┐ │
│  │              Application (Use Cases)                     │ │
│  │  - read_parameter()                                      │ │
│  │  - read_all()                                           │ │
│  │  - Retry logic (with backoff)                           │ │
│  └───────────────────────────┬───────────────────────────────┘ │
│                              │                                  │
│  ┌───────────────────────────▼───────────────────────────────┐ │
│  │                  Infrastructure (Adapters)                │ │
│  │  - SerialTransport (tokio-serial)                        │ │
│  │  - MockTransport (for testing)                           │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

```

**Key Design Decisions:**
- Use `trait Transport` to abstract serial I/O (enables mocking).
- Use `thiserror` for custom error types.
- Use `serde` only for configuration, not for protocol.
- No `unsafe` code – all safe Rust.
- Async runtime: `tokio` with `tokio-serial` for non‑blocking RS485.

---

## 8. Scope

### In Scope
- Full implementation of DL/T645 protocol (request frames, response parsing, checksum, BCD decoding).
- Read all defined DI codes (voltage, current, power, energy, frequency, power factor).
- Retry logic with exponential backoff (configurable attempts and delays).
- Serial transport via `tokio-serial` (RS485).
- Mock transport for testing.
- Integration with `zinova-core` via `MeterAdapter` trait.
- Audit logging of all reads (success/failure).
- Configuration via `Config` struct (port, baudrate, meter address, retry settings).
- Health monitoring (expose meter status via a `health()` method).
- Unit and integration tests (with mock/simulator).
- Documentation (API docs, user guide).

### Out of Scope
- MQTT publishing (handled by `zinova-core` or a separate publisher).
- DLM or Policy logic.
- Support for other meter protocols (Modbus, SunSpec) – future extensions.
- TLS/encryption on RS485 (not feasible for DL/T645).
- HMAC implementation (optional, configurable, but not required for Phase 1).
- Multiple meter support on the same port (one driver instance per meter).

---

## 9. Assumptions

| Assumption | Description |
|------------|-------------|
| RS485 hardware is reliable (no frequent disconnects). | Retry logic handles transient errors. |
| Meter responds within 500 ms (configurable timeout). | Timeout is set to 1 second to be safe. |
| BCD encoding follows standard DL/T645 (no vendor extensions). | We only support standard DI codes. |
| One driver instance per meter (no multiplexing). | Each meter has its own serial port. |
| Configuration is static (no runtime changes to port/baudrate). | Changes require restart. |

---

## 10. Constraints

| Constraint | Description |
|------------|-------------|
| **Memory** | Edge device has limited RAM (Robustel EG3110: 256 MB). Driver must stay under 20 MB. |
| **CPU** | Single‑core ARM Cortex‑A7. No heavy computation. |
| **Time** | Migration must be completed within 3 sprints (6 weeks). |
| **Backward Compatibility** | New driver must produce identical output format (same JSON structure). |
| **No Breaking Changes** | Upper layers (MeterAdapter) must not require changes. |

---

## 11. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| RS485 timing differences between Python and Rust | Meter may not respond within expected timeout | Medium | Use configurable timeout; test with real hardware early. |
| BCD decoding edge cases (unexpected byte patterns) | Wrong values or panics | Low | Extensive unit tests with known BCD samples; fallback to 0.0 on invalid. |
| Serial driver incompatibility with Robustel kernel | `tokio-serial` may not work on older kernel | Medium | Test on target hardware early; fallback to blocking `serial` crate if needed. |
| Performance degradation due to async overhead | Higher CPU usage than Python | Low | Benchmark; use `tokio` with minimal contention. |
| Integration with `zinova-core` – API mismatch | Breaking changes in upper layers | Medium | Keep adapter interface identical to Python version. |
| Developer learning curve (Rust) | Slower initial progress | Medium | Pair programming; internal training; use `cargo clippy` and `cargo fmt`. |

---

## 12. Dependencies

| Dependency | Description | Owner |
|------------|-------------|-------|
| **tokio** | Async runtime for I/O | Rust Team |
| **tokio-serial** | Async serial port access | Rust Team |
| **thiserror** | Error handling | Rust Team |
| **serde** | Configuration deserialisation | Rust Team |
| **uuid** | For trace IDs (audit logging) | Rust Team |
| **tracing** | Structured logging | Rust Team |
| **mockall** | For mocking `Transport` in tests | QA Team |
| **criterion** | Performance benchmarks | QA Team |
| **Robustel EG3110** | Target hardware | DevOps |
| **Real DL/T645 meter** | For integration tests | Sourcing / Field Ops |

---

## 13. Migration Strategy

We will follow an **incremental, feature‑flag‑based migration** with **blue‑green deployment**:

1. **Phase 0‑2:** Build core protocol logic in Rust (no I/O). Test thoroughly with unit tests.
2. **Phase 3‑4:** Add serial transport and integration with `zinova-core` (in a separate branch).
3. **Phase 5‑6:** Run parallel Python and Rust drivers in staging (dual‑write mode). Compare outputs.
4. **Phase 7‑8:** Deploy Rust driver to a subset of sites (canary). Monitor for 1 week.
5. **Phase 9:** Full rollout; remove Python driver from production.

**Feature Flags:**
- `USE_RUST_DRIVER` – enables Rust driver in `zinova-core`.
- `DRIVER_MODE` = `dual` (run both, compare), `rust` (Rust only), `python` (fallback).

**Rollback:** If Rust driver fails, switch back to Python via feature flag (within 5 minutes).

---

## 14. Phase 0 – Foundation

**Objective:** Set up the crate, define types, errors, and configuration.

**Activities:**
- Create `crates/dlt645-driver/` with `Cargo.toml`.
- Define `error.rs` with `thiserror` (all driver error types).
- Define `types.rs` with `MeterAddress`, `DiCode`, `Scale`, `BcdData`, `Frame`.
- Define `config.rs` with `DriverConfig` struct (port, baudrate, address, retry settings).
- Write `lib.rs` to expose public API.

**Deliverables:**
- `Cargo.toml` with all dependencies.
- `src/error.rs`, `src/types.rs`, `src/config.rs`, `src/lib.rs`.
- Unit tests for `types` (validation of DI codes, address parsing).

**Acceptance Criteria:**
- Crate compiles without warnings.
- All type definitions are complete.
- Configuration can be deserialised from `config.toml`.

**Sprint:** Sprint 4 (Week 1)

---

## 15. Phase 1 – Checksum & BCD Decoder

**Objective:** Implement checksum calculation and BCD decoding (no I/O).

**Activities:**
- Implement `checksum.rs` – function `calculate(data: &[u8]) -> u8`.
- Implement `bcd.rs` – functions `decode_bcd(data: &[u8], scale: f64) -> f64`.
- Write unit tests for all valid/invalid BCD patterns and checksum cases.

**Deliverables:**
- `src/checksum.rs` with tests.
- `src/bcd.rs` with tests.
- Integration with `types.rs` for BCD data structures.

**Acceptance Criteria:**
- All BCD test cases pass (including edge cases like leading zeros, invalid nibbles).
- Checksum matches known good values from Python driver.

**Sprint:** Sprint 4 (Week 1)

---

## 16. Phase 2 – Frame Builder & Parser

**Objective:** Build request frames and parse response frames (no I/O).

**Activities:**
- Implement `frame.rs` – `build_request(di: DiCode) -> Vec<u8>`.
- Implement `frame.rs` – `parse_response(raw: &[u8]) -> Result<Response, DriverError>`.
- Validate frame markers (0x68, 0x16), length, and checksum.
- Extract data from response.

**Deliverables:**
- `src/frame.rs` with public functions.
- Unit tests for frame building (verify against Python output).
- Unit tests for response parsing (valid, invalid, truncated, malformed).

**Acceptance Criteria:**
- Built frames match Python driver output byte‑for‑byte.
- All valid responses parse correctly.
- All invalid responses return appropriate errors.

**Sprint:** Sprint 4 (Week 1)

---

## 17. Phase 3 – Retry Logic

**Objective:** Implement exponential backoff retry for transient errors.

**Activities:**
- Design `retry.rs` with a generic retry function.
- Define retry policy: `max_attempts`, `base_delay`, `max_delay`.
- Integrate retry with `read_parameter()` and `read_all()`.

**Deliverables:**
- `src/retry.rs` with tests (mock failures).
- Retry integrated into `client.rs`.

**Acceptance Criteria:**
- Retry succeeds on 2nd attempt after simulated timeout.
- Max retries exceeded returns error.
- Backoff delays follow exponential pattern.

**Sprint:** Sprint 4 (Week 2)

---

## 18. Phase 4 – Transport Layer (RS485)

**Objective:** Implement async serial transport using `tokio-serial`.

**Activities:**
- Define `trait Transport` with `write_and_read(request: &[u8]) -> Result<Vec<u8>>`.
- Implement `SerialTransport` using `tokio-serial`.
- Implement `MockTransport` for testing.
- Integrate transport with `client.rs`.

**Deliverables:**
- `src/transport.rs` with trait and serial implementation.
- `src/mock.rs` with mock transport.
- Integration tests using `MockTransport`.

**Acceptance Criteria:**
- SerialTransport can open port, send frame, receive response.
- MockTransport can simulate success, timeout, checksum error.
- All integration tests pass with mock.

**Sprint:** Sprint 4 (Week 2)

---

## 19. Phase 5 – Client (Public API)

**Objective:** Expose a clean public API for upper layers.

**Activities:**
- Define `MeterDriver` trait with `read_parameter(di: DiCode) -> Result<f64>` and `read_all() -> Result<HashMap<DiCode, f64>>`.
- Implement `Dlt645Client` struct that holds transport and config.
- Add `health()` method to return meter status.

**Deliverables:**
- `src/client.rs` with public API.
- `src/lib.rs` exports `MeterDriver`, `Dlt645Client`, `DiCode`, `DriverConfig`.
- Documentation comments (`///`) for all public items.

**Acceptance Criteria:**
- Client can read a single parameter and return a float.
- Client can read all parameters in a single call (sequential reads).
- Health returns `Ok(())` if meter responds, `Err` otherwise.

**Sprint:** Sprint 5 (Week 1)

---

## 20. Phase 6 – Integration with `zinova-core`

**Objective:** Integrate Rust driver into `zinova-core` as a `MeterAdapter`.

**Activities:**
- Create `src/assets/meter/adapters/dlt645.rs` in `zinova-core`.
- Implement `MeterAdapter` trait using `MeterDriver`.
- Replace Python driver call with Rust driver (feature‑flagged).
- Add configuration for Rust driver in `config/app_config.rs`.

**Deliverables:**
- `dlt645.rs` adapter in `zinova-core`.
- Feature flag `USE_RUST_DRIVER` in `Cargo.toml` (or config).
- Integration test in `zinova-core` that uses mock driver.

**Acceptance Criteria:**
- `zinova-core` compiles with Rust driver feature enabled.
- `MeterAdapter` methods (read_state, read_reading) return correct data.
- No breaking changes to upper layers.

**Sprint:** Sprint 5 (Week 1)

---

## 21. Phase 7 – Dual‑Write & Comparison

**Objective:** Run both Python and Rust drivers in parallel and compare outputs.

**Activities:**
- Modify `MeterAdapter` to run both drivers (if `DRIVER_MODE == "dual"`).
- Compare results (within tolerance: 0.01).
- Log mismatches for analysis.
- Run in staging for 1 week.

**Deliverables:**
- Dual‑write mode implementation.
- Comparison script (generates report).
- Logs of mismatches (if any) resolved.

**Acceptance Criteria:**
- Both drivers produce identical results (with tolerance) for all parameters.
- No regressions in DLM decisions due to meter data differences.

**Sprint:** Sprint 5 (Week 2)

---

## 22. Phase 8 – Canary Deployment

**Objective:** Deploy Rust driver to a small subset of production sites.

**Activities:**
- Select 5 sites with stable meters.
- Enable Rust driver via feature flag (`DRIVER_MODE = "rust"`).
- Monitor for 1 week (metrics, logs, health).
- Rollback if any critical errors occur.

**Deliverables:**
- Canary deployment plan.
- Monitoring dashboard (Grafana).
- Incident response plan.

**Acceptance Criteria:**
- Zero critical errors during canary period.
- Metrics show improved performance (latency, CPU, memory).
- DLM decisions remain correct.

**Sprint:** Sprint 6 (Week 1)

---

## 23. Phase 9 – Full Rollout & Retirement

**Objective:** Deploy Rust driver to all sites and remove Python driver.

**Activities:**
- Enable Rust driver globally.
- Remove Python driver code and dependencies from codebase.
- Update documentation and build scripts.
- Archive Python driver in a separate branch.

**Deliverables:**
- Production deployment.
- Updated documentation.
- Cleaned codebase (no Python driver).

**Acceptance Criteria:**
- All sites running Rust driver.
- Python driver fully removed.
- No regression in system stability or performance.
- All KPIs met.

**Sprint:** Sprint 6 (Week 2)

---

## 24. Sprint Mapping

| Sprint | Weeks | Phases Covered |
|--------|-------|----------------|
| Sprint 4 | 2 weeks | Phase 0, Phase 1, Phase 2, Phase 3, Phase 4 |
| Sprint 5 | 2 weeks | Phase 5, Phase 6, Phase 7 |
| Sprint 6 | 2 weeks | Phase 8, Phase 9 |

---

## 25. Product Backlog (Epics & Stories)

### Epic 1: Protocol Core (Phases 0‑2)
- [PB‑001] As a developer, I want a well‑defined error type set for the driver.
- [PB‑002] As a developer, I want strong types for DI codes, meter address, and BCD data.
- [PB‑003] As a developer, I want to calculate DL/T645 checksum correctly.
- [PB‑004] As a developer, I want to decode BCD data according to the standard.
- [PB‑005] As a developer, I want to build a valid request frame for any DI code.
- [PB‑006] As a developer, I want to parse a response frame and extract data.

### Epic 2: I/O & Resilience (Phases 3‑4)
- [PB‑007] As a developer, I want to read from a serial port asynchronously.
- [PB‑008] As a developer, I want to retry failed reads with exponential backoff.
- [PB‑009] As a developer, I want to simulate serial I/O for testing.

### Epic 3: Integration (Phases 5‑6)
- [PB‑010] As a developer, I want a clean public API for reading parameters.
- [PB‑011] As a developer, I want to integrate the driver into `zinova-core`.
- [PB‑012] As a developer, I want to run both Python and Rust drivers in dual‑write mode.

### Epic 4: Deployment (Phases 7‑9)
- [PB‑013] As a site operator, I want to deploy the Rust driver without downtime.
- [PB‑014] As a site operator, I want to monitor the driver’s health and performance.
- [PB‑015] As a developer, I want to completely remove the Python driver from the codebase.

---

## 26. Technical Debt

| Debt Item | Description | Severity | Plan |
|-----------|-------------|----------|------|
| No HMAC support | Optional security feature | Medium | Add in Phase 9 if required by customer. |
| Single‑meter only | No support for multiple meters on one port | Low | Future enhancement. |
| No auto‑detection of baudrate | Must be configured manually | Low | Not required for Phase 1. |
| No dynamic reconfiguration | Changes require restart | Low | Not required. |
| No persistent session | No keep‑alive for meter | Medium | Not required; each read is independent. |

---

## 27. Rollback Strategy

| Scenario | Action |
|----------|--------|
| Rust driver fails to compile | Revert to last stable commit; continue with Python. |
| Rust driver crashes at runtime | Feature flag `DRIVER_MODE = "python"`; restart service. |
| Rust driver produces wrong values | Switch to dual‑write mode to verify; if mismatch, use Python. |
| Performance regression (high CPU/memory) | Rollback to Python; investigate in lab. |
| Meter not responding (timeout) | Increase timeout; if persistent, fallback to Python. |

**Rollback Time:** < 5 minutes (feature flag change + restart).

---

## 28. Deployment Strategy

| Environment | Strategy | Notes |
|-------------|----------|-------|
| Development | Direct deploy (Rust only) | No Python fallback. |
| Staging | Dual‑write | Compare outputs; detect mismatches. |
| Production (Canary) | Feature flag (5 sites) | Monitor for 1 week. |
| Production (Full) | Feature flag (all sites) | Remove Python after 2 weeks. |

**Deployment Artifacts:**
- Static binary (Rust) – no runtime dependencies.
- Docker image with Rust driver + `zinova-core`.

---

## 29. Documentation Strategy

| Document | Target Audience | Owner |
|----------|-----------------|-------|
| API Reference (crate docs) | Developers | Rust Team |
| User Manual | Field Ops | Documentation Engineer |
| Integration Guide | DevOps / SRE | DevOps |
| Security Model | Security Team / Auditors | Security Architect |
| Test Report | QA Team | QA Lead |
| ADR (Decision Log) | SDC / CTO | CTO |

All documentation will be stored in `docs/architecture/drivers/dlt645/`.

---

## 30. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Correctness** | 100% parity with Python | Dual‑write comparison for 1 week. |
| **Latency** | < 2 seconds for read_all() | Benchmark (criterion). |
| **Memory** | < 20 MB RSS | Runtime measurement (pmap). |
| **CPU** | < 5% average | Runtime measurement (top). |
| **Error Rate** | < 1% of reads fail | Production logs. |
| **Test Coverage** | > 90% | `cargo-tarpaulin` or `cargo-llvm-cov`. |
| **MTBF** | > 30 days | Production monitoring. |
| **Rollback Time** | < 5 minutes | Incident drill. |

---

## 31. KPIs

| KPI | Target | Frequency |
|-----|--------|-----------|
| Number of retries per read | < 0.5 on average | Daily |
| Timeout rate | < 1% | Daily |
| Mismatch rate (dual‑write) | 0 | Daily |
| Build time (cargo build --release) | < 2 minutes | Per commit |
| Test execution time | < 30 seconds | Per commit |

---

## 32. Timeline

| Phase | Start | End | Duration |
|-------|-------|-----|----------|
| Phase 0 | 2026-07-04 | 2026-07-06 | 3 days |
| Phase 1 | 2026-07-04 | 2026-07-07 | 4 days |
| Phase 2 | 2026-07-07 | 2026-07-10 | 4 days |
| Phase 3 | 2026-07-11 | 2026-07-14 | 4 days |
| Phase 4 | 2026-07-11 | 2026-07-15 | 5 days |
| Phase 5 | 2026-07-16 | 2026-07-20 | 5 days |
| Phase 6 | 2026-07-18 | 2026-07-22 | 5 days |
| Phase 7 | 2026-07-23 | 2026-07-28 | 6 days |
| Phase 8 | 2026-07-29 | 2026-08-05 | 8 days |
| Phase 9 | 2026-08-06 | 2026-08-10 | 5 days |

**Total:** 6 weeks (Sprint 4‑6)

---

## 33. Milestones

| Milestone | Date | Deliverable |
|-----------|------|-------------|
| M1: Core Protocol Ready | 2026-07-10 | Checksum, BCD, Frame, Parser (Phases 0‑2) |
| M2: I/O & Retry Ready | 2026-07-15 | Transport, Retry (Phases 3‑4) |
| M3: Integration Ready | 2026-07-22 | Client API, zinova‑core integration (Phases 5‑6) |
| M4: Dual‑Write Verified | 2026-07-28 | No mismatches (Phase 7) |
| M5: Canary Success | 2026-08-05 | 1 week stable on 5 sites (Phase 8) |
| M6: Full Rollout | 2026-08-10 | Python driver removed (Phase 9) |

---

## 34. Decision Records (ADR)

### ADR-001: Use Rust for DL/T645 Driver
- **Context:** Python driver is causing performance and maintainability issues.
- **Decision:** Rewrite the driver in Rust.
- **Status:** Approved (CTO + SDC).
- **Consequences:** Improved memory safety, performance; requires team training.

### ADR-002: Use `tokio` for Async Runtime
- **Context:** Need non‑blocking I/O on RS485.
- **Decision:** Use `tokio` with `tokio-serial`.
- **Status:** Approved.
- **Consequences:** Better integration with `zinova-core` (which already uses `tokio`).

### ADR-003: Separate Transport from Protocol (Hexagonal Architecture)
- **Context:** Need testability without hardware.
- **Decision:** Define `Transport` trait and implement `SerialTransport` and `MockTransport`.
- **Status:** Approved.
- **Consequences:** Highly testable; can run integration tests in CI without hardware.

### ADR-004: No MQTT in Driver
- **Context:** Driver should be a pure adapter.
- **Decision:** Remove MQTT publishing; leave to upper layers.
- **Status:** Approved (Brain‑Body separation).
- **Consequences:** Cleaner separation of concerns; driver is reusable.

### ADR-005: Use Feature Flags for Rollback
- **Context:** Need zero‑downtime migration.
- **Decision:** Use `DRIVER_MODE` config to switch between Python and Rust.
- **Status:** Approved.
- **Consequences:** Easy rollback; canary deployments.

---

## 35. Lessons Learned (From Python Driver)

| Lesson | Applied in Rust |
|--------|-----------------|
| Always validate checksum before parsing. | ✅ Checksum validation is mandatory. |
| Retry transient errors (timeout, NACK). | ✅ Retry logic with exponential backoff. |
| Separate transport from protocol. | ✅ `Transport` trait separates I/O from business logic. |
| Use strong types to prevent invalid parameters. | ✅ `DiCode` enum + `MeterAddress` newtype. |
| Log all failures with context. | ✅ `tracing` structured logging. |
| Never return stale data on error. | ✅ Return `None` or `Err` – never cached. |
| Test with real hardware early. | ✅ Hardware integration in Phase 8. |

---

## 36. Final Checklist

- [x] All phases defined (Phase 0 – Phase 9).
- [x] Deliverables and acceptance criteria for each phase.
- [x] Sprint mapping (3 sprints).
- [x] Product backlog (epics & stories).
- [x] Technical debt identified.
- [x] Rollback strategy defined.
- [x] Deployment strategy defined.
- [x] Documentation strategy defined.
- [x] Success metrics and KPIs defined.
- [x] Timeline and milestones defined.
- [x] ADRs documented.
- [x] Lessons learned captured.
- [x] Executive summary included.

---

## 37. Approvals

| Role | Name | Signature | Date |
|------|------|-----------|------|
| CTO | — | ✅ | 2026-07-01 |
| SDC Chair | — | (pending) | — |
| Rust Team Lead | — | (pending) | — |
| QA Lead | — | (pending) | — |
| DevOps Lead | — | (pending) | — |

---

**Document Version:** 1.0  
**Next Review:** 2026-08-15 (post‑rollout retrospective)

