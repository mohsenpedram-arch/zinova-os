```markdown
# ZINOVA NOMAD – Factory Acceptance Criteria

## 1. Lot Acceptance (AQL)

| Inspection Level | AQL |
|------------------|-----|
| Critical defects (safety) | 0% |
| Major defects (function) | 0.65% |
| Minor defects (cosmetic) | 1.5% |

## 2. Critical Defects (Reject whole lot if ANY found)
- Missing or non‑functional 6mA DC leakage detection
- Missing ground detection or false ground detection
- Plug temperature sensor missing or >5°C error at critical range
- Relay welded closed (any unit)
- IEC 62752 certificate not valid
- IP rating lower than declared
- Input cable cross‑section <2.5mm²
- No serial number or non‑unique serial
- Any electrical shock hazard (accessible live parts)

## 3. Major Defects (Reject unit, may rework if possible)
- One current level out of spec (>±10%)
- LED indicator wrong color or no light
- Button not responding
- Over‑temperature shutdown at lower than 80°C (false trip)
- Communication (MQTT/OCPP) fails after 3 attempts
- OTA signature verification fails
- Enclosure cracked but not exposing live parts
- Label missing or wrong rating

## 4. Minor Defects (Accept, but deduct from payment)
- Small scratch (<2cm) on enclosure
- Slight misalignment of label (<2°)
- Carrying case stitch loose but functional
- Manual has minor typo

## 5. Factory Must Provide:
- Certificate of conformance for each batch.
- Test data for all 100% tests (CSV or PDF).
- Sample of failed units with root cause analysis.
- Video recording of IP test (if requested).

## 6. Zinova Right to Witness
- Zinova can send representative to witness any test, at own expense.
- Factory must give 14 days notice before production run.

## 7. Re‑work and Re‑submission
- If lot fails AQL, factory may rework and re‑submit once.
- Second failure → contract termination for that product line.

## 8. Payment Hold Conditions
Zinova may withhold up to 20% of payment until acceptance criteria are met, including:
- Missing test reports
- Failed independent third‑party test (Zinova‑selected lab)
- Non‑compliance with safety certification

## 9. Warranty Return Criteria (for returned units)
- If failure is due to manufacturing defect (not misuse), factory covers shipping and replacement.
- Factory must analyze failure and provide 8D report within 30 days.
```

---
