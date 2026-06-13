
```markdown
# ZINOVA NOMAD – Power Core BOM (23 Items)

## Mandatory (Critical Path)

| # | Component | Specification | Qty |
|---|-----------|---------------|-----|
| 1 | Input cable | 3×2.5mm², H05RN-F or better, 2m | 1 |
| 2 | Input plug | Heavy‑duty 16A, Iran compatible (Schuko CEE 7/7 reinforced) | 1 |
| 3 | Control box enclosure | IP65, PC/ABS, UL94 V-0, IK08 | 1 |
| 4 | Relay / Contactor | 20A min, 250V AC, sealed | 2 (L & N) |
| 5 | AC RCD (Type A equivalent) | 30mA trip, self‑test | 1 |
| 6 | DC leakage detection (6mA) | Separate sensor or integrated | 1 |
| 7 | Current transformer (CT) | For load current measurement | 1 |
| 8 | Voltage measurement circuit | Resistor divider + ADC | 1 |
| 9 | STM32 MCU (safety) | STM32F103 or G0 series | 1 |
| 10 | RK3566 module (edge) | SOM with 2GB RAM, 8GB eMMC | 1 |
| 11 | LTE module | Cat 4, industrial temp | 1 |
| 12 | Nano SIM holder | Push‑push, sealed | 1 |
| 13 | eSIM chip (optional) | MFF2, for failover | 1 |
| 14 | Temperature sensor (plug) | NTC 10kΩ, insulated | 1 |
| 15 | Temperature sensor (box) | NTC 10kΩ, PCB mount | 1 |
| 16 | CP pilot circuit | PWM generator (STM32 internal) | 1 |
| 17 | PP resistor detection | Voltage divider | 1 |
| 18 | Output cable | 3×2.5mm², 5m, flexible, TPU jacket | 1 |
| 19 | Type 2 vehicle connector | IEC 62196‑2, with temperature sensor (preferred) | 1 |
| 20 | LED board | 5 LEDs (Power, Charge, Fault, Ground, Temp) | 1 |
| 21 | Button | Momentary, sealed, 10k cycles | 1 |
| 22 | Power supply (AC‑DC) | 230V to 5V/12V, isolated, 15W | 1 |
| 23 | PCB (main + interface) | FR4, 2oz copper, conformal coating | 1 |

## Optional (for specific variants)
- LCD display (128×64, monochrome) – replaces LED board.
- WiFi module (for debug only, not for end user) – not in alpha.

## Notes:
- All safety‑critical components (relay, RCD, DC leakage) must have component‑level certification.
- STM32 and RK3566 communicate via isolated UART.
- Power supply must hold up for 100ms after input loss to log events.
```

---
