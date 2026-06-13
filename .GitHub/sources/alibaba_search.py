
import os
import json
from typing import List, Dict
from apify_client import ApifyClient

ALIBABA_APIFY_ACTOR_ID = "hH4eICvUgULKLSVha"  # Alibaba Listings Scraper

def search_alibaba(keyword: str, max_results: int = 30) -> List[Dict]:
    """
    جستجو در Alibaba از طریق Apify API
    Keyword مثال: "IC-CPD EV charger IEC 62752"
    Returns: لیست دیکشنری‌های وندور با فیلدهای:
        - name, url, product_title, price, moq, 
        - supplier_type (OEM/Trading), rating, certifications
    """
    client = ApifyClient(os.environ.get("APIFY_API_TOKEN"))
    
    run_input = {
        "searchKeywords": keyword,
        "maxPages": max_results // 10,
        "extractCertifications": True,   # استخراج خودکار گواهی‌ها
        "extractSupplierType": True,      # تشخیص OEM vs Trading
        "minMOQ": 100,                    # فیلتر اولیه برای MOQ پایین
    }
    
    run = client.actor(ALIBABA_APIFY_ACTOR_ID).call(run_input=run_input)
    results = []
    for item in client.dataset(run["defaultDatasetId"]).iterate_items():
        results.append({
            "source": "alibaba",
            "name": item.get("supplierName"),
            "product": item.get("productTitle"),
            "price": item.get("price"),
            "moq": item.get("minOrderQuantity"),
            "supplier_type": item.get("supplierType"),  # OEM vs Trading
            "certifications": item.get("certifications", []),
            "rating": item.get("supplierRating"),
            "url": item.get("productUrl"),
        })
    return results
```

2. Made-in-China – mic_search.py

برای Made-in-China، Apify Made-in-China Scraper توصیه می‌شود. طبق جستجوها، این اسکرپر قابلیت استخراج موارد زیر را دارد:

· product name, price, MOQ, supplier name, profile link
· business type (Manufacturer vs Trading Company)
· certifications, factory size, employee count, export markets

```python
# .github/scripts/sources/mic_search.py

from apify_client import ApifyClient

MIC_APIFY_ACTOR_ID = "bDl62GLqW7sKOpuF2"  # Made-in-China Scraper

def search_mic(keyword: str, max_results: int = 30) -> List[Dict]:
    """
    جستجو در Made-in-China از طریق Apify API
    Returns: لیست وندورها با اطلاعات:
        - business_type (Manufacturer/Trading), factory_size, certifications
    """
    client = ApifyClient(os.environ.get("APIFY_API_TOKEN"))
    
    run_input = {
        "searchKeyword": keyword,
        "maxPages": max_results // 20,
        "extractCertifications": True,
        "extractFactoryInfo": True,      # استخراج اطلاعات کارخانه
        "minMOQ": 100,
    }
    
    run = client.actor(MIC_APIFY_ACTOR_ID).call(run_input=run_input)
    # ... مشابه Alibaba
```
