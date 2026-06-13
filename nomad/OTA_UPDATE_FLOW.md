```markdown
# ZINOVA NOMAD – OTA Update Flow

## 1. Overview
OTA updates are **signed, authenticated, and offline‑safe**. Both RK3566 (Linux) and STM32 firmware can be updated. STM32 update is delivered via RK3566 over local UART.

## 2. OTA Trigger Methods
| Method | Description |
|--------|-------------|
| MQTT config message | `{"cmd":"ota_check","version":"1.2.0"}` |
| Periodic check | Every 24h, device polls `https://ota.zinova.com/v1/nomad/{serial}/firmware/latest` |
| Manual (button combination) | Hold Current+ button for 10s |

## 3. Update Flow (RK3566)
```text
1. Device receives OTA trigger or timer.
2. HTTPS GET to OTA server with current version.
3. Server responds with latest version info (URL, size, SHA256, signature).
4. Device downloads firmware to separate partition (A/B scheme).
5. Verify signature using public key in bootloader.
6. Verify SHA256 hash of downloaded file.
7. If valid, set boot flag to new partition and reboot.
8. After reboot, new firmware sends `ota_status: success` via MQTT.
9. If boot fails twice, rollback to previous partition automatically.
```

4. STM32 Update (via RK3566)

· RK3566 downloads STM32 binary (signed as part of the same OTA package).
· Over UART, using STM32 bootloader protocol (or custom IAP).
· STM32 verifies signature of incoming binary before flashing.
· After flash, STM32 resets, sends version to RK3566.
· If STM32 fails to boot (watchdog), RK3566 retries or reports failure.

5. Rollback Logic

· RK3566 maintains two boot partitions (A/B).
· STM32 maintains one primary plus a backup (can revert via RK3566).
· If new RK3566 firmware crashes more than 3 times in 10 minutes → rollback to previous.
· Rollback triggers a fault event sent to cloud.

6. OTA Security Rules

· No OTA from untrusted source (only pre‑configured server).
· No downgrade to version with known vulnerability (anti‑rollback counter).
· OTA cannot be interrupted by power loss; device resumes after power restore.
· If signature verification fails at any stage, device rejects update and logs attempt.

7. Offline OTA

· Support for USB‑based update (service only): insert USB drive with signed firmware, device detects and updates. Must still verify signature.

8. OTA Logging

· Each OTA attempt is logged in device (timestamp, version, result, failure reason).
· Logs transmitted to cloud when connectivity returns.

9. Factory Recovery

· If both partitions corrupted (extremely rare), device enters recovery mode (special button sequence) and accepts firmware over USB from Zinova tool.

```

---
