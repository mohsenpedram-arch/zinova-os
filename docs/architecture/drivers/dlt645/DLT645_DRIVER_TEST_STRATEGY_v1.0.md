# DLT645 Driver – Test Strategy v1.0

**Date:** 2026-07-01  
**Status:** Approved  
**Owner:** CTO / QA Team  

---

## 1. Objectives

- Ensure driver works correctly with real hardware.
- Validate all edge cases without needing physical meters.
- Provide confidence for production deployment.

---

## 2. Test Pyramid

```

```

---

## 3. Unit Tests (Phase 2–3)

| Module | Test Cases |
|--------|------------|
| `checksum` | Valid checksum, invalid, edge cases (empty, max) |
| `bcd` | All defined DI scales, invalid BCD nibbles, leading zeros |
| `frame` | Build request frame, missing markers, length mismatch |
| `parser` | Valid response, checksum mismatch, truncated response, corrupt data |
| `retry` | Retry succeeds on 2nd attempt, max retries exceeded, backoff timing |

---

## 4. Integration Tests (Phase 4)

### 4.1 Mock Transport
- Simulate successful responses for all DI codes.
- Simulate timeouts, NACK, malformed responses.
- Verify that retry logic behaves correctly.

### 4.2 Simulator (pre‑recorded responses)
- Read from a YAML/JSON file containing expected request‑response pairs.
- Test against a full set of parameters.
- Run in CI without hardware.

---

## 5. Hardware Integration Tests (Phase 5)

- Run on a real Robustel device with a physical meter.
- Validate all parameters (voltage, current, power, energy, frequency, PF).
- Measure latency and stability over 24h.
- Test error recovery: disconnect/reconnect cable, power cycle meter.

---

## 6. CI Pipeline

| Stage | Triggers | Tools |
|-------|----------|-------|
| Unit tests | On every PR/push | `cargo test --lib` |
| Mock integration | On every PR/push | `cargo test --test integration -- --ignored` (with mock) |
| Simulator integration | Nightly | `cargo test --test simulator` |
| Hardware tests | Manual / Release | On‑device execution |

---

## 7. Success Criteria

- [x] Unit test coverage > 90%.
- [x] All integration tests pass with mock/simulator.
- [x] Driver reads all parameters from real meter within 2 seconds.
- [x] No panics or unrecoverable errors during 24h stability test.

