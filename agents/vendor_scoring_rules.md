
# ZINOVA – Vendor Scoring Rules (Weighted)

## Scoring Dimensions (Total 100)

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Certification | 25 | IEC62752, CE, RoHS, test reports |
| Factory & Manufacturing | 25 | OEM vs trading, factory size, QC process |
| Engineering Transparency | 20 | RCD architecture, DC leakage method, PCB/firmware ownership |
| Manufacturing Capability | 20 | Monthly capacity, production lines, export markets |
| Price & Commercial | 10 | MOQ, sample price, lead time, payment terms |

## Scoring Logic (per dimension, 0–100 then weighted)

### Certification (25 pts)
- 100: IEC62752 + CE + RoHS + full test report
- 80: IEC62752 + CE (no test report)
- 60: Only self‑declared IEC
- 0: No IEC or fake

### Factory (25 pts)
- 100: OEM with own factory, factory audit passed, production video
- 70: OEM but no recent audit
- 40: Small workshop, unclear ownership
- 0: Trading company or no factory address

### Engineering Transparency (20 pts)
- 100: Provides block diagram, RCD architecture, 6mA DC method, PCB design owned
- 70: Provides description but no diagram
- 30: Vague, no technical staff
- 0: Refuses to share

### Manufacturing Capability (20 pts)
- 100: >1000 units/month, >5 years export to EU/ME
- 70: 500–1000 units/month, some export
- 30: <200 units/month, local only
- 0: No data

### Price & Commercial (10 pts)
- 100: MOQ ≤ 100, sample <$80, lead time <30 days
- 70: MOQ 100–500, sample $80–120
- 30: MOQ >500, sample >$120
- 0: Unreasonable or hidden

## Final Score Thresholds
- **≥ 80**: Shortlist (RFQ ready)
- **65–79**: Monitor (request more info)
- **< 65**: Reject (unless exceptional justification)
