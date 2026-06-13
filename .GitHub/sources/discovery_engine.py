
```python
# .github/scripts/discovery_engine.py

from concurrent.futures import ThreadPoolExecutor, as_completed
from sources.alibaba_search import search_alibaba
from sources.mic_search import search_mic

def discover_vendors(keyword: str) -> List[Dict]:
    """اجرای جستجوی موازی در تمامی منابع"""
    all_vendors = []
    
    with ThreadPoolExecutor(max_workers=3) as executor:
        future_alibaba = executor.submit(search_alibaba, keyword)
        future_mic = executor.submit(search_mic, keyword)
        
        for future in as_completed([future_alibaba, future_mic]):
            try:
                results = future.result()
                all_vendors.extend(results)
            except Exception as e:
                print(f"Search failed: {e}")
    return all_vendors
```
