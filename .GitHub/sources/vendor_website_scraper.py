
```python
# .github/scripts/sources/vendor_website_scraper.py

from tavily import TavilyClient
import requests

TAVILY_API_KEY = os.environ.get("TAVILY_API_KEY")

def extract_vendor_info_from_website(domain: str, vendor_name: str) -> Dict:
    """
    Crawl وب‌سایت وندور و استخراج:
        - certifications page
        - product specs matching BOM
        - factory/location information
        - technical contacts
    """
    tavily = TavilyClient(api_key=TAVILY_API_KEY)
    
    queries = [
        f"site:{domain} IEC 62752",
        f"site:{domain} {vendor_name} IC-CPD",
        f"site:{domain} factory quality control",
        f"site:{domain} certification"
    ]
    
    merged_info = {"certifications": [], "products": [], "certification_urls": []}
    
    for q in queries:
        response = tavily.search(query=q, search_depth="advanced", include_answer=False)
        for result in response.get("results", []):
            merged_info["certification_urls"].append(result["url"])
            # بررسی محتوا برای کلمات کلیدی گواهی
            if "iec" in result["content"].lower():
                merged_info["certifications"].append("IEC")
    return merged_info
```
