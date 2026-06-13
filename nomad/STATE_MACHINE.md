# ZINOVA NOMAD – State Machine (Core Logic)

## States
```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> SELF_CHECK : Plug connected to AC
    SELF_CHECK --> FAULT : Check fails
    SELF_CHECK --> READY : All checks passed
    READY --> CHARGING : Vehicle connected & CP handshake OK
    CHARGING --> DERATING : Over-temperature warning
    DERATING --> CHARGING : Temperature drops
    CHARGING --> FAULT : Critical fault (leakage, no ground, etc)
    CHARGING --> IDLE : User stops or vehicle disconnects
    FAULT --> MANUAL_RESET : Non-recoverable
    FAULT --> SELF_CHECK : Recoverable (auto after cooldown)
    MANUAL_RESET --> IDLE : User re-plug or power cycle

1. IDLE

· Input plug connected, but no vehicle or charging not started.
· LED: Power on.
· No relay closed.

2. SELF_CHECK (runs automatically after plug-in and before each start)

Checks:

· AC voltage in range (207–253V)
· Ground / PE present
· Leakage sensor self-test (injected test pulse)
· Relay contacts open (not welded)
· Temperature sensors reading reasonable
· Internal memory and watchdog OK

If any fails → go to FAULT, block start.

3. READY

· All checks passed, waiting for vehicle connection.
· CP pilot present, waiting for PWM duty cycle from vehicle.
· User can adjust current limit (6–16A).
· Relay still open.

4. CHARGING

· Relay closed, current flowing.
· STM32 monitors in real time (<10ms response):
  · Leakage (AC/DC)
  · Temperature (plug, box)
  · Voltage, current
  · Ground continuity
  · CP signal integrity
· RK3566 logs data every 1s (if storage available).
· Current can be changed by user (button) or by temperature derating.

5. DERATING (sub-state of CHARGING)

· Trigger: plug temperature ≥ 70°C or box temperature ≥ 70°C.
· Action: reduce current by 2A steps, minimum 6A.
· If temperature still rises to critical (≥85°C) → FAULT (stop).
· If temperature drops to <60°C, slowly increase current back to user setpoint.

6. FAULT

· Immediate relay open, red LED.
· Types:
  · Recoverable (auto): Over-voltage that returns to range, temporary communication glitch → auto back to SELF_CHECK after 5s.
  · Non-recoverable (manual): DC leakage, relay weld, missing ground, over-temperature critical, pilot short → require user to unplug and re-plug (or power cycle).
· Fault code stored in non-volatile memory (RK3566 + STM32 EEPROM).

7. MANUAL_RESET

· After non-recoverable fault, device locks out.
· User must disconnect input plug from AC, wait 10s, reconnect.
· Then returns to IDLE → SELF_CHECK.

8. Emergency Shutdown

· Any condition that violates safety (leakage >6mA DC, no ground, relay weld detected) → STM32 cuts relay within 50ms, independent of RK3566.
· Even if RK3566 crashes, STM32 maintains safe state.

9. Start Inhibit Conditions

· No ground detected.
· Self-test failed.
· Temperature sensor short/open.
· Relay welded.
· Internal voltage reference out of spec.

10. State Persistence

· Current state is stored in STM32 RAM (non-volatile for faults).
· On power loss, next power-on goes to IDLE → SELF_CHECK.

```

---

