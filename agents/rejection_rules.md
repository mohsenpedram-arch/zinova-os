# ZINOVA – Automatic Rejection Rules

## Hard Rejection (Any triggers → immediate reject, no scoring)

| Rule | Verification |
|------|--------------|
| No IEC62752 certification (real, not self‑declared) | Certificate number must be verifiable |
| No 6mA DC leakage detection | Datasheet or block diagram must show |
| No ground / PE detection before charging | Must be explicitly stated |
| No plug temperature sensor | Mandatory for Nomad |
| Trading company (not OEM) | Business license, factory photos missing |
| Refuses to provide factory address or production photos | WeChat/email record |
| Refuses to discuss RCD architecture or PCB ownership | Engineering call log |
| No QC procedure document | Factory test plan missing |
| Cable cross‑section < 2.5mm² for 16A | Spec sheet |
| Auto‑restart after critical fault (leakage, over‑temp) | Behavior description |

## Soft Rejection (Score penalty, can be recovered)

- No previous export to EU/Middle East → −15 points
- No technical contact (only sales) → −20 points
- MOQ > 1000 units → −10 points
- Sample lead time > 45 days → −10 points
- No serial number traceability → −15 points

## Rejection Logging
Every rejection must be recorded in `outputs/daily_scan/rejected_vendors.csv` with:
- Vendor name, date, reason, evidence (link or screenshot)
