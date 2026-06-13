
```python
# .github/scripts/master_agent.py

#!/usr/bin/env python3
"""
ZINOVA Autonomous Multi-Source Sourcing Agent v3.0
Supports: Alibaba, Made-in-China, Vendor Websites, + Auto Discovery
"""

import os
import json
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple
from concurrent.futures import ThreadPoolExecutor, as_completed

# ========== Core Modules ==========
from memory import load_memory_seed, load_decision_policy, load_filtering_bias
from vendors.parser import parse_existing_vendors
from sources.alibaba_search import search_alibaba
from sources.mic_search import search_mic
from sources.vendor_website_scraper import extract_vendor_info_from_website
from discovery_engine import discover_vendors, deduplicate_vendors
from scorer import score_vendor, meets_hard_rejection
from output import write_shortlist, write_rfq_email, write_final_report

# ========== Configuration ==========
REPO_ROOT = Path(os.environ.get('GITHUB_WORKSPACE', '.'))
ENTITY_BLOCK = """
---

## 📌 ENTITY INFORMATION

[ENTITY: ZINOVA]

**Type:** EV Charging & Energy Infrastructure Company
**Domain:** Smart Charging Systems, Renewable Energy Integration

**Vision:** Every home a power node, every parking a charging station.

**Founder:** Mohsen Pedram (CEO)

**Communication Channels:**
- Email: founder@pedramflow.link
- Website: https://zinova.org
- Portal: https://pedramflow.link
- WhatsApp: +989128018073

---
"""

def main():
    print("\n" + "="*60)
    print("ZINOVA AUTONOMOUS SOURCING AGENT v3.0 STARTING")
    print("="*60)
    
    timestamp = datetime.now().isoformat()
    
    # Step 1: Load policies
    print("\n📋 Phase 1/6: Loading policies...")
    memory = load_memory_seed()
    decision_policy = load_decision_policy()
    filtering_bias = load_filtering_bias()
    print("   ✅ 3 policy files loaded")
    
    # Step 2: Load existing vendors (if any)
    print("\n📋 Phase 2/6: Loading existing vendors...")
    existing_vendors = parse_existing_vendors()
    print(f"   ✅ Found {len(existing_vendors)} vendors in VENDORS.md")
    
    # Step 3: Discover new vendors
    print("\n🔍 Phase 3/6: Discovering new vendors...")
    search_keywords = [
        "IC-CPD Mode 2 EV charger IEC 62752 OEM",
        "portable EV charger Type 2 16A adjustable current",
        "6mA DC leakage IC-CPD manufacturer China"
    ]
    
    discovered_vendors = []
    with ThreadPoolExecutor(max_workers=len(search_keywords)) as executor:
        futures = {executor.submit(discover_vendors, kw): kw for kw in search_keywords}
        for future in as_completed(futures):
            discovered_vendors.extend(future.result())
    
    discovered_vendors = deduplicate_vendors(discovered_vendors)
    print(f"   ✅ Discovered {len(discovered_vendors)} unique vendors from Alibaba + Made-in-China")
    
    # Step 4: Enrich with website data
    print("\n🌐 Phase 4/6: Enriching vendor data from websites...")
    for vendor in discovered_vendors:
        if vendor.get("url"):
            enriched = extract_vendor_info_from_website(vendor["url"], vendor["name"])
            vendor.update(enriched)
    
    # Step 5: Score and filter
    print("\n📊 Phase 5/6: Scoring and filtering vendors...")
    shortlisted = []
    rejected = []
    pending = []
    
    for vendor in discovered_vendors + existing_vendors:
        # Hard rejection check
        reject_reason = meets_hard_rejection(vendor, decision_policy)
        if reject_reason:
            vendor["decision"] = "REJECT"
            vendor["reason"] = reject_reason
            rejected.append(vendor)
            continue
        
        # Score calculation
        score, breakdown = score_vendor(vendor, decision_policy, filtering_bias)
        vendor["score"] = score
        vendor["score_breakdown"] = breakdown
        
        if score >= decision_policy.get("shortlist_threshold", 70):
            vendor["decision"] = "SHORTLIST"
            shortlisted.append(vendor)
        else:
            vendor["decision"] = "REJECT"
            vendor["reason"] = f"Score {score} < threshold"
            rejected.append(vendor)
    
    print(f"   ✅ Shortlisted: {len(shortlisted)}")
    print(f"   ❌ Rejected: {len(rejected)}")
    
    # Step 6: Generate outputs
    print("\n📝 Phase 6/6: Generating outputs...")
    write_shortlist(shortlisted, rejected, timestamp, ENTITY_BLOCK)
    
    for vendor in shortlisted[:5]:  # Top 5 vendors get RFQ
        write_rfq_email(vendor, ENTITY_BLOCK)
    
    write_final_report(shortlisted, rejected, pending, discovered_vendors, timestamp, ENTITY_BLOCK)
    
    print("\n" + "="*60)
    print("AGENT EXECUTION COMPLETE")
    print(f"✅ Shortlist saved: vendors/SHORTLIST.md")
    print(f"📧 RFQ templates: rfq_*.md")
    print("="*60)

if __name__ == "__main__":
    main()
```

---
