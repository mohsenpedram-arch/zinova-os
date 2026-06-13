

```python
# .github/scripts/scorer.py

import re
from typing import Dict, List, Tuple

def score_vendor(vendor: Dict, decision_policy: Dict, filtering_bias: Dict) -> Tuple[int, Dict]:
    """
    محاسبه امتیاز نهایی وندور
    Returns: (total_score, breakdown_dict)
    """
    weights = decision_policy.get("weights", {
        "Safety": 25, "Certification": 25, "Engineering_Transparency": 20,
        "Manufacturing": 20, "Cost": 10
    })
    
    breakdown = {}
    total = 0
    
    # 1. Safety Score (25 points)
    safety_score = 0
    safety_keywords = ["6ma", "dc leakage", "ground detection", "pe detection", "temperature sensor"]
    product_text = (vendor.get("product", "") + " " + str(vendor.get("description", ""))).lower()
    
    for kw in safety_keywords:
        if kw in product_text:
            safety_score += 5
    safety_score = min(safety_score, weights["Safety"])
    breakdown["Safety"] = safety_score
    total += safety_score
    
    # 2. Certification Score (25 points)
    cert_score = 0
    cert_keywords = ["iec 62752", "ce", "rohs", "type b", "tuv"]
    
    # Check if certifications field exists (from Apify scraper)
    certs = vendor.get("certifications", [])
    cert_text = " ".join(certs).lower() if certs else product_text
    
    for kw in cert_keywords:
        if kw in cert_text:
            cert_score += 6 if "iec" in kw else 4
    cert_score = min(cert_score, weights["Certification"])
    breakdown["Certification"] = cert_score
    total += cert_score
    
    # 3. Engineering Transparency (20 points)
    trans_score = 0
    # Trading company penalty
    if vendor.get("supplier_type") == "Trading":
        trans_score -= 10
    # Positive: detailed product description
    if len(product_text) > 200:
        trans_score += 8
    breakdown["Engineering_Transparency"] = max(0, min(trans_score, weights["Engineering_Transparency"]))
    total += breakdown["Engineering_Transparency"]
    
    # 4. Manufacturing Capability (20 points)
    mfg_score = 0
    if vendor.get("supplier_type") == "OEM":
        mfg_score += 12
    if vendor.get("factory_size"):
        mfg_score += 5
    breakdown["Manufacturing"] = min(mfg_score, weights["Manufacturing"])
    total += breakdown["Manufacturing"]
    
    # 5. Cost (10 points) - based on MOQ and price
    cost_score = 10
    moq = vendor.get("moq", 1000)
    if moq > 500:
        cost_score -= 5
    if moq > 1000:
        cost_score -= 3
    breakdown["Cost"] = max(0, cost_score)
    total += breakdown["Cost"]
    
    return total, breakdown


def meets_hard_rejection(vendor: Dict, decision_policy: Dict) -> str:
    """
    بررسی قوانین سخت رد
    Returns: دلیل رد (string empty if passed)
    """
    hard_rules = decision_policy.get("hard_reject", [])
    product_text = (vendor.get("product", "") + " " + str(vendor.get("description", ""))).lower()
    
    for rule in hard_rules:
        if "6mA" in rule and "6ma" not in product_text:
            return "Missing 6mA DC leakage detection"
        if "IEC 62752" in rule and "iec" not in product_text:
            return "No IEC 62752 certification found"
        if "OEM" in rule and vendor.get("supplier_type") == "Trading":
            return "Trading company, not OEM"
    
    return ""  # Passed all hard rules
```

---
