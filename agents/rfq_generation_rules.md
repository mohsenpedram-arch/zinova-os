# ZINOVA – RFQ Generation Rules

## RFQ Types (based on product line)

| Product Line | RFQ Template | Required Documents |
|--------------|--------------|---------------------|
| Nomad (Mode 2 portable) | `templates/rfq_nomad.md` | Datasheet, IEC62752, factory photos, QC procedure |
| Wallbox (Mode 3) | `templates/rfq_wallbox.md` | IEC61851, OCPP cert, installation manual |
| DC Fast Charger | `templates/rfq_dc.md` | CHAdeMO/CCS, ISO15118, thermal management spec |

## Mandatory Attachments for Every RFQ
- [ ] Product datasheet (PDF)
- [ ] IEC / CE / RoHS certificates (scanned)
- [ ] Factory photos (production line, QC area)
- [ ] Production line video (minimum 30 sec)
- [ ] Quality control procedure document
- [ ] Internal block diagram (RCD, leakage detection, relay control)

## RFQ Sending Rules
- Send only to vendors with score ≥ 80 (Shortlist)
- CC: founder@pedramflow.link
- Subject format: `RFQ – Zinova Nomad – [Vendor Name] – [Date]`
- Deadline for response: 14 days
- Follow‑up if no response after 7 days (once)

## Response Evaluation
- Complete response with all docs → proceed to sample stage
- Missing critical docs (IEC, factory photos) → reject or request resend
- Vague or evasive answers → flag as high risk, consider rejection

## RFQ Storage
All sent RFQs and received responses stored in:
`outputs/rfq_responses/[vendor_name]/[date]_rfq.pdf` and `[date]_response.pdf`
