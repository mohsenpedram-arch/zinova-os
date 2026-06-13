```markdown
# ZINOVA NOMAD – Security Model

## 1. Threat Model
| Threat | Mitigation |
|--------|-------------|
| Unauthorized firmware update | Signed image, verified by RK3566 bootloader |
| Physical tampering | Enclosure tamper-evident seals, potting of safety circuits (optional) |
| Cloud takeover | No cloud power control; local STM32 final authority |
| Man-in-the-middle on LTE | TLS 1.2 with pinned certificates |
| Fake device spoofing | mTLS client certificate unique per device |
| Firmware rollback to vulnerable version | Anti-rollback counter in secure storage |
| OEM backdoor | Source code audit of STM32 + RK3566; signed builds by Zinova |

## 2. Secure Boot Chain (RK3566)
1. BootROM loads first-stage bootloader from eMMC
2. First-stage verifies signature of U-Boot
3. U-Boot verifies signature of Linux kernel
4. Kernel verifies signature of root filesystem (dm-verity or signed squashfs)
5. Any failure → device refuses to boot, enters recovery mode (LED pattern)

## 3. OTA Signing
- Firmware image signed with Zinova private key (Ed25519 or RSA-4096)
- Signature stored in separate `.sig` file
- Device verifies signature using public key embedded in bootloader (burned once)
- OTA server URL pre-configured; no unsigned image accepted

## 4. Secure Storage
- Device private key (for mTLS) stored in eMMC RPMB or separate secure element (optional for alpha)
- Factory configuration (serial, limits) write-protected after provisioning

## 5. Communication Security
- MQTT: TLS 1.2 + client certificate
- HTTPS: TLS 1.2 + server certificate pinning (public key)
- OCPP: WSS (TLS)
- No plaintext protocols allowed

## 6. Cloud Permission Limits (enforced locally)
- Cloud **cannot**:
  - Start a charging session
  - Disable temperature derating
  - Lower current below 6A or above 16A
  - Change safety thresholds (e.g., leakage trip level)
- Cloud **can**:
  - Request stop charging (RemoteStopTransaction)
  - Request diagnostic logs
  - Update configuration (within bounds)
  - Trigger OTA

## 7. Kill‑Switch Rule
- If Zinova issues a global kill‑switch command (signed and broadcast via MQTT):
  - Device will stop charging immediately.
  - Device will not resume charging until physical manual reset (press and hold button 10s).
  - This is a legal/compliance requirement, not a backdoor for normal use.

## 8. Physical Security
- Relay control lines from STM32 are not externally accessible.
- JTAG/SWD disabled in production (fuses blown) for STM32.
- RK3566 debug UART disabled in production, only enabled in engineering samples.

## 9. Privacy
- No PII transmitted.
- Telemetry does not include GPS or exact location (only optional coarse region config).
- Logs stored locally can be deleted by user (button sequence: hold current button for 15s).

## 10. OEM Binding
- OEM factory must sign a security addendum.
- Zinova provides signed firmware only; OEM cannot sign firmware.
- All test firmware has expiration date (60 days) to prevent production use of unsigned builds.
```

---
