📦 ZINOVA NOMAD – FINAL MASTER STRUCTURE

🔵 A) BOM (CORE HARDWARE) — 23 ITEMS (LOCKED)



# ZINOVA NOMAD 
## Portable AC EV Charger — Mode 2  
### Vendor Technical Datasheet / RFQ Specification  
**Version:** Alpha Final Vendor Spec  
**Status:** Locked for Supplier RFQ  
**Application:** Emergency / Portable EV Charging  
**Market:** Iran / 230V Single‑Phase Grid  
**Connector Standard:** IEC Type 2  
**Charging Mode:** Mode 2 IC-CPD / ICCB

---

# 1. Product Definition

| Item | Requirement |
|---|---|
| Product Name | Zinova Nomad / رهرو زینوا |
| Product Type | Portable AC EV Charger |
| Charging Mode | Mode 2 |
| Control Unit | In‑Cable Control and Protection Device / IC‑CPD / ICCB |
| Vehicle Connector | IEC 62196‑2 Type 2 |
| Grid Input | Single‑Phase AC |
| Target Use | Emergency / Portable / Temporary Charging |
| Not Intended As | Permanent wallbox replacement |
| Target Market | Iran, residential and emergency charging |
| Main Positioning | Safe portable charging from standard/heavy‑duty socket |

---

# 2. Electrical Input Specifications

| Parameter | Requirement |
|---|---|
| Rated Input Voltage | 230V AC single phase |
| Voltage Range | 207V – 253V AC |
| Frequency | 50Hz |
| Frequency Tolerance | 45Hz – 55Hz |
| Max Input Current | 16A |
| Adjustable Current Levels | 6A / 8A / 10A / 13A / 16A |
| Current Selection Method | Physical button on control box or touch button; must be user selectable |
| Default Start Current | 10A preferred / vendor to confirm |
| Input Plug Type | Heavy‑duty 16A plug suitable for Iran market; Schuko CEE 7/7 reinforced acceptable if approved |
| Input Cable Cross‑Section | Minimum 3 × 2.5 mm² copper |
| Input Cable Rating | 300/500V or better |
| Grounding | Mandatory PE detection before charging |

---

# 3. Electrical Output Specifications

| Parameter | Requirement |
|---|---|
| Output Voltage | 230V AC single phase |
| Max Output Current | 16A |
| Max Output Power | 3.7kW |
| Vehicle Connector | Type 2 female plug, IEC 62196‑2 |
| Output Cable Cross‑Section | Minimum 3 × 2.5 mm² copper |
| Output Cable Length | 5m standard |
| Optional Cable Length | 7m optional, vendor to quote separately |
| Charging Control | IEC 61851 PWM pilot signal |
| CP Signal | Required |
| PP Resistor Coding | Required according to Type 2 spec |
| Mechanical Lock Support | If available, vendor to specify |

---

# 4. Standards and Compliance

| Standard | Requirement |
|---|---|
| IEC 62752 | Required for Mode 2 IC‑CPD |
| IEC 61851‑1 | Required |
| IEC 62196‑2 | Required for Type 2 connector |
| CE | Required |
| RoHS | Required |
| REACH | Preferred |
| EMC Compliance | Required, vendor to provide test report if available |
| LVD Compliance | Required |
| Certification Documents | Vendor must provide copies of certificates and test reports |
| Factory Test Report | Required per batch |
| Serial Number Traceability | Required |

**Non‑negotiable:** Vendor must clearly state whether IEC 62752 certification is real, partial, self‑declared, or not available. No vague claim accepted.

---

# 5. Protection Functions

| Protection Function | Requirement |
|---|---|
| Over‑Current Protection | Required |
| Short‑Circuit Protection | Required |
| Over‑Voltage Protection | Required |
| Under‑Voltage Protection | Required |
| Over‑Temperature Protection | Required |
| Leakage Current Protection | Required |
| DC Leakage Detection | Required, 6mA DC |
| AC Residual Current Protection | Required, Type A equivalent |
| Ground Fault Detection | Required |
| Missing Ground Detection | Required |
| Relay Welding Detection | Preferred / vendor to specify |
| Surge Protection | Preferred internal basic protection / vendor to specify |
| Auto Recovery | Required for non‑critical faults |
| Manual Reset | Required for critical faults |

---

# 6. Leakage Protection Requirement

Minimum accepted configuration:

| Item | Requirement |
|---|---|
| AC Leakage | Type A equivalent residual current protection |
| DC Leakage | 6mA DC leakage detection |
| Alternative | Full Type B RCD equivalent acceptable |
| Trip Time | Vendor to specify |
| Trip Current | Vendor to specify |
| Self‑Test | Required before charging starts |

**Hard rule:**  
If the product has no 6mA DC leakage detection or Type B equivalent, it is rejected.

---

# 7. Temperature Monitoring

| Sensor Location | Requirement |
|---|---|
| Input Plug Temperature Sensor | Required |
| Control Box Temperature Sensor | Required |
| Vehicle Connector Temperature Sensor | Preferred / vendor to specify |
| Cable Temperature Monitoring | Preferred / vendor to specify |

Required behavior:

| Condition | Action |
|---|---|
| Temperature Warning Level | Reduce current automatically |
| Critical Temperature Level | Stop charging |
| Recovery | Resume only after temperature returns to safe range |
| Temperature Thresholds | Vendor to specify; Zinova target: warning around 70°C, shutdown around 85°C |

**Important:**  
Input plug temperature monitoring is mandatory because socket quality in target market is inconsistent.

---

# 8. Control Box / ICCB Requirements

| Parameter | Requirement |
|---|---|
| Enclosure Rating | Minimum IP65 |
| Material | Flame retardant PC/ABS or equivalent |
| Flame Rating | UL94 V‑0 preferred |
| Impact Resistance | IK08 preferred / vendor to specify |
| Display | LED indicators minimum |
| Optional Display | LCD optional, vendor to quote separately |
| Current Setting | Must show selected current level |
| Button Life | Vendor to specify |
| Relay/Contactor Rating | ≥ 20A preferred for 16A operation |
| Operating Logic | Must perform self‑check before charging |
| Event Memory | Preferred; vendor to specify |
| Firmware Upgrade | Preferred; vendor to specify if available |

---

# 9. Indicator / User Interface

Minimum LED indicators:

| Indicator | Requirement |
|---|---|
| Power | Required |
| Charging | Required |
| Fault | Required |
| Ground Fault / No Ground | Required |
| Over‑Temperature | Required |
| Current Level | Required by LEDs or display |

If LCD is offered, it should show:

- Voltage
- Current
- Power
- Energy
- Charging time
- Fault code
- Temperature warning
- Selected current level

LCD is optional, not mandatory. Reliability is more important than gimmick.

---

# 10. Mechanical Specifications

| Parameter | Requirement |
|---|---|
| Total Cable Length | 5m standard |
| Optional Length | 7m optional |
| Total Weight | Target < 3.5kg |
| Control Box Size | Vendor to specify |
| Connector Type | Type 2 |
| Input Plug | Heavy‑duty 16A, Iran compatible |
| Cable Jacket | TPU preferred / high‑quality rubber acceptable |
| Cable Flexibility | Suitable for outdoor portable use |
| UV Resistance | Required |
| Oil Resistance | Preferred |
| Abrasion Resistance | Required |
| Strain Relief | Required at plug, box, connector |
| Carrying Case | Required |
| Cable Tie / Strap | Required |

---

# 11. Environmental Specifications

| Parameter | Requirement |
|---|---|
| Operating Temperature | -25°C to +55°C |
| Storage Temperature | -40°C to +70°C |
| Operating Humidity | 5% – 95% RH, non‑condensing |
| Control Box IP Rating | IP65 minimum |
| Vehicle Connector IP Rating | IP54 minimum when mated |
| Input Plug IP Rating | Vendor to specify |
| Outdoor Use | Required |
| Rain Resistance | Required, but not for submerged use |
| Altitude | Vendor to specify, preferred up to 2000m |

---

# 12. Safety Behavior Logic

The charger shall operate as follows:

```text
1. User connects input plug to AC socket.
2. ICCB powers on.
3. Device performs self-check:
   - voltage range
   - ground/PE presence
   - leakage sensor status
   - relay status
   - temperature status
4. User selects current level if needed.
5. User connects Type 2 connector to vehicle.
6. Charger communicates through CP/PWM.
7. Charging starts only if all safety checks pass.
8. During charging, device continuously monitors:
   - current
   - voltage
   - leakage
   - temperature
   - PE status
   - relay state
9. If warning temperature occurs:
   - reduce current automatically.
10. If critical fault occurs:
   - stop charging immediately.
11. Non-critical recoverable faults:
   - auto-recovery allowed.
12. Critical faults:
   - require manual reset or reconnect.
```

---

# 13. Fault Handling Requirements

| Fault | Required Action |
|---|---|
| No Ground / PE Fault | Do not start charging |
| Over‑Voltage | Stop charging |
| Under‑Voltage | Stop charging or pause |
| Over‑Current | Stop charging |
| Short Circuit | Immediate trip |
| AC Leakage | Trip |
| DC Leakage ≥ 6mA | Trip |
| Plug Over‑Temperature | Reduce current, then stop if critical |
| Control Box Over‑Temperature | Reduce current, then stop if critical |
| Relay Welded | Block charging, show fault |
| Communication/Pilot Error | Stop charging |
| Internal Self‑Test Failure | Block charging |

---

# 14. Branding and Industrial Design

| Item | Requirement |
|---|---|
| Brand | ZINOVA |
| Product Name | NOMAD |
| Persian Name | رهرو |
| Logo Placement | On control box and carrying case |
| Color | Black / dark graphite preferred |
| Accent Color | Zinova brand color, to be provided |
| Label Language | English minimum; Persian label optional for final batch |
| Rating Label | Required on control box |
| QR Code | Required for user manual / support |
| Serial Number | Required |
| Packaging Branding | Required for production batch |

---

# 15. Label Requirements

Rating label must include:

- Brand: ZINOVA
- Model: Nomad
- Input: 230V AC, 50Hz, 16A max
- Output: 230V AC, 16A max, 3.7kW max
- Current levels: 6/8/10/13/16A
- Mode: Mode 2
- Connector: Type 2
- IP rating
- Standards
- CE/RoHS marks if valid
- Serial number
- Warning symbols
- Made in China / OEM as applicable

---

# 16. Packaging Requirements

Each unit shall include:

| Item | Requirement |
|---|---|
| Portable EV Charger | 1 pc |
| Carrying Bag / Case | 1 pc |
| User Manual | 1 pc |
| Quick Safety Card | 1 pc |
| QC Pass Card | 1 pc |
| Warranty Card | 1 pc optional |
| Cable Strap | 1 pc |

Packaging:

| Parameter | Requirement |
|---|---|
| Inner Box | Required |
| Export Carton | Required |
| Drop Protection | Required |
| Moisture Protection | Required |
| Carton Label | Model, quantity, gross/net weight, batch number |
| Palletization | Vendor to specify |

---

# 17. Quality Control and Factory Testing

Vendor must perform and provide QC process for:

| Test | Requirement |
|---|---|
| Visual Inspection | 100% |
| Electrical Safety Test | 100% |
| Ground Continuity Test | 100% |
| Leakage Protection Test | 100% |
| High‑Voltage / Hi‑Pot Test | 100% |
| Insulation Resistance Test | 100% |
| Functional Charging Test | 100% |
| Current Level Verification | 100% |
| Temperature Sensor Test | Sampling minimum / vendor to specify |
| Burn‑In Test | Preferred, vendor to specify duration |
| Waterproof Test | Sampling |
| Cable Pull / Strain Relief Test | Sampling |
| Label Verification | 100% |
| Serial Number Recording | 100% |

---

# 18. Required Supplier Documents

Supplier must provide:

1. Product datasheet  
2. User manual  
3. CE certificate  
4. RoHS certificate  
5. IEC 62752 certificate or compliance report  
6. IEC 61851‑1 compliance report if available  
7. EMC test report  
8. LVD test report  
9. Internal wiring diagram or block diagram  
10. QC test procedure  
11. Factory test report sample  
12. Packing list  
13. HS code  
14. Product photos  
15. Label artwork template  
16. Warranty terms  
17. Failure rate history if available  
18. MOQ and lead time  
19. Spare parts list  
20. SDK/API/firmware info if any — optional

---

# 19. Commercial RFQ Fields

Supplier must quote:

| Field | Supplier Response |
|---|---|
| MOQ |  |
| Sample Price |  |
| Mass Production Unit Price |  |
| Price for 5m Cable |  |
| Price for 7m Cable |  |
| LCD Version Price |  |
| LED Version Price |  |
| Custom Logo Cost |  |
| Custom Packaging Cost |  |
| Certification Cost if private label |  |
| Lead Time for Sample |  |
| Lead Time for 100 pcs |  |
| Lead Time for 500 pcs |  |
| Warranty Period |  |
| Payment Terms |  |
| Incoterms | FOB / EXW / CIF to be quoted |
| Port |  |
| HS Code |  |

---

# 20. Acceptance Criteria

Zinova will accept the product only if the following are satisfied:

| Requirement | Status |
|---|---|
| 230V single‑phase operation | Mandatory |
| 6/8/10/13/16A adjustable current | Mandatory |
| Type 2 connector | Mandatory |
| Mode 2 ICCB | Mandatory |
| IEC 62752 compliance | Mandatory |
| IEC 61851‑1 compliance | Mandatory |
| 6mA DC leakage detection | Mandatory |
| PE/ground detection | Mandatory |
| Plug temperature sensor | Mandatory |
| Control box temperature sensor | Mandatory |
| IP65 control box | Mandatory |
| IP54 connector minimum | Mandatory |
| 5m cable | Mandatory |
| Weight below target or justified | Mandatory |
| CE/RoHS documents | Mandatory |
| Factory QC test report | Mandatory |
| Serial number traceability | Mandatory |

---

# 21. Rejection Criteria

Product shall be rejected if:

- No 6mA DC leakage detection
- No ground/PE detection
- No plug temperature sensor
- Fake or unclear certification claims
- Cable below 3 × 2.5mm² for 16A
- Weak household plug not suitable for 16A continuous use
- No current adjustment
- Control box IP below IP65
- No factory test report
- No serial number traceability
- Unsafe auto‑restart after critical fault
- Vendor refuses to provide internal protection details

---

# 22. Open Items for Supplier Confirmation

Supplier must confirm:

| Item | Supplier Confirmation |
|---|---|
| Exact input plug model |
| Actual certification status |
| RCD architecture |
| 6mA DC leakage detection method |
| Trip current and trip time |
| Temperature sensor locations |
| Temperature thresholds |
| Cable material |
| Cable cross‑section |
| Control box material |
| Relay/contactor rating |
| IP test report availability |
| LCD or LED version |
| Branding capability |
| Packaging customization |
| Warranty and spare parts policy |

---

# 23. Zinova Internal Decision

| Field | Decision |
|---|---|
| Product Family | Nomad / رهرو |
| Phase | Alpha |
| Role | Entry portable charger |
| Status | Locked for RFQ |
| Vendor Strategy | Source from certified Chinese OEM/ODM |
| Customization Priority | Safety first, branding second, cosmetics third |
| Non‑Negotiable Features | DC leakage, PE detection, plug temp sensor, current limit |
| Not Required in Alpha | App, WiFi, Bluetooth, cloud, billing |

---

# Final Vendor Note

This product is intended for the Iran market where socket quality, grounding quality, and voltage stability may vary significantly. Therefore, Zinova requires strong protection design, plug temperature monitoring, adjustable current, and clear fault behavior. Cosmetic features are secondary to electrical safety and reliability.




🟣 B) RFQ EXTENSION LAYER (SYSTEM REQUIREMENTS)


🔷 24. EDGE COMPUTE TIER DEFINITION

LayerRequirementCompute TierTier 1.5 – Balanced IndustrialSoCRK3566 / RK3568 ONLYOSEmbedded Linux (Yocto / Buildroot)RAM≥ 2GBStorage≥ 8GB eMMCConstraintNo Raspberry Pi / No consumer SBCSafety MCUSTM32 required (separate domain) 

🔷 25. COMMUNICATION PROTOCOL STACK

ProtocolPurposeStatusMQTTTelemetry + heartbeatREQUIREDOCPP 1.6/2.0.1Charging sessionREQUIREDHTTPS RESTOTA + config + fallbackREQUIREDmTLSDevice authenticationREQUIREDWebSocketMonitoringOPTIONAL 

RULES:

MQTT → telemetry only

OCPP → session only

HTTPS → OTA/config only

NO power control via cloud

🔷 26. COMMUNICATION ARCHITECTURE RULE

RuleRequirementCloud controlFORBIDDEN for powerEdge controlONLY authorityOffline modeFULL operation requiredDependencyNo single protocol dependency 

🔷 27. SIM / eSIM ARCHITECTURE

ItemRequirementLTE ModuleIndustrial gradeSIMNano SIM mandatoryeSIMPreferredFailoverRequiredOffline modeMust continue charging 

🔷 28. OTA LINKAGE MODEL

FunctionProtocolFirmware downloadHTTPSUpdate triggerMQTT / HTTPSSession statusOCPPSyncMQTT 

🧠 FINAL STRUCTURAL TRUTH 

🔧 HARDWARE LAYER (23 BOM ITEMS)


🧠 SYSTEM LAYER (RFQ 24–28)



**End of Vendor Technical Datasheet**
