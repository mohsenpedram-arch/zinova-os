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
