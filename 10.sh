cd ~/ZINOVA-CORE
cargo build --quiet
cargo test --quiet









From: CTO of ZINOVA
To: ZINOVA Edge Engineering Division
Subject: Phase 1 Development Kick-off — Building the Intelligent Edge

تیم،

اکنون که زیرساخت کدنویسی به‌طور کامل برپا شده و مخزن در وضعیت Production Bootstrap Ready قرار دارد، فاز اجرا رسماً آغاز می‌شود. تمام پیش‌نیازهای معماری، مستندات، امنیت و CI/CD فراهم است. هدف این فاز، زنده کردن اولین زنجیره داده واقعی است:

کنتور DL/T645 → RS485 → Edge Runtime → Soha → Data Lake

---

Sprint 1 (هفته ۱-۲): هسته پروتکل و احراز هویت

اولویت‌ها:

1. تکمیل dlt645-core
   · پیاده‌سازی واقعی frame.rs، parser.rs، builder.rs و error.rs.
   · ساختار Measurement با پارامترهای کیفیت توان (power_factor, frequency, thd_v) از ابتدا کامل باشد.
   · نوشتن تست‌های واحد با بردارهای Annex 13.
2. توسعه rs485-driver
   · بازکردن و مدیریت پورت سریال (Serial Port) با تنظیمات DL/T645.
   · مکانیزم timeout و retry مطابق طراحی.
3. فعال‌سازی security-agent
   · پیاده‌سازی دریافت گواهی از ZEIS/Keycloak و ارائه traitهای CertificateProvider و JwtValidator.
   · در فاز نخست با mock، سپس یکپارچه‌سازی با Soha.
4. یکپارچه‌سازی اولیه در edge-agent
   · خواندن یک فریم نمونه از RS485 (یا شبیه‌ساز)، عبور از dlt645-core و چاپ خروجی JSON.
   · ارسال دستی یک فرمان OCPP ساده (در صورت وجود شارژر متصل) برای اطمینان از سلامت OCPP-gateway-v2.

خروجی: یک edge-agent که می‌تواند حداقل یک فریم از کنتور را بخواند، تجزیه کند و رویداد را لاگ کند.

---

Sprint 2 (هفته ۳-۴): اتصال به Cloud و Device Twin

1. توسعه telemetry
   · ایجاد MQTT Client با mTLS.
   · ارسال JSON خروجی به Topicهای تعریف‌شده.
   · پیاده‌سازی Offline Buffer با SQLite.
2. Device Twin اولیه
   · ذخیره وضعیت شارژرها و کنتورها در SQLite محلی.
   · همگام‌سازی وضعیت با Cloud از طریق MQTT/API.
3. یکپارچه‌سازی DLM Engine
   · دریافت داده‌های نرمال‌شده از dlt645-core و محاسبه دستورات شارژ (setpoint) توسط DlmEngine.
   · ارسال دستور از طریق OCPP-gateway-v2 به شارژر (در صورت وجود).
4. ثبت Edge Runtime در Soha
   · edge-agent خود را به‌عنوان یک سرویس در Soha ثبت کند.
   · Health Check و Metric را از طریق Soha در دسترس قرار دهد.

خروجی: اولین حلقه کامل از کنتور تا شارژر؛ سیستم می‌تواند داده انرژی را بخواند، پردازش کند و شارژر را کنترل کند.

---

قوانین حیاتی در طول کدنویسی:

· هر commit باید از cargo fmt, cargo clippy, cargo test عبور کند.
· تا زمانی که تست‌های واحد کرنل پروتکل کامل نباشد، هیچ کدی به main مرج نمی‌شود.
· هر ساختار داده‌ای که معرفی می‌شود، باید در common-types مستند شود.
· امنیت (mTLS, JWT) از همان ابتدا روشن باشد، حتی با گواهی‌های خودامضا.

---

شروع کنید

از همین امروز، بر روی Sprint 1 متمرکز شوید.
اولین commit معنادار را با عنوان feat(dlt645): implement frame parser بفرستید.

من هر روز نتیجه cargo test را بررسی می‌کنم.
آینده انرژی هوشمند، با کدی که امروز می‌نویسید، ساخته می‌شود.

— CTO, ZINOVA
Authority: Supreme Decision Council (SDC)

From: CTO of ZINOVA
To: ZINOVA Edge Engineering Division
Subject: Phase 1 Development Kick-off v1.1 — Revised with Engineering Rigor

تیم عزیز،

از بازخورد دقیق و فنی که ارائه شد سپاسگزارم. حق با شماست: یک دستور شروع توسعه برای محصول صنعتی باید فراتر از کیفی باشد؛ باید اندازه‌پذیر، قابل ممیزی و با تعریف دقیق «تمام‌شده» همراه باشد. تمام هشت اصلاح پیشنهادی پذیرفته شده و در برنامه بازبینیشده Sprint 1 و چارچوب کلی توسعه اعمال گردیده است. اینک دستور اصلاحی جایگزین نسخه قبلی می‌شود.

---

Sprint 1 (هفته‌های ۱-۲): هسته پروتکل، ارتباط سریال و Pipeline پایه

هدف اصلی Sprint:

ایجاد یک Data Acquisition Pipeline کامل از RS485 تا JSON لاگ‌شده، منطبق با استانداردهای امنیتی پایه.

```
RS485 → Read Frame → Validate → Parse → Normalize → JSON → Structured Log
```

معیارهای پذیرش (Acceptance Criteria):

· AC1: تمام تست‌های واحد dlt645-core با موفقیت اجرا شوند. پوشش کد ≥ ۸۵٪.
· AC2: Parser حداقل ۲۰ بردار آزمون از Annex 13 (فصل 13.10) را بدون خطا Decode کند.
· AC3: میانگین زمان Parse هر فریم (average latency) روی سخت‌افزار Robustel EG3110 ≤ ۲ میلی‌ثانیه.
· AC4: حافظه مصرفی edge-agent در حالت پایدار ≤ ۱۵ مگابایت (RAM).
· AC5: edge-agent قادر به دریافت یک فریم از RS485 (Simulator یا واقعی)، تجزیه و چاپ JSON استاندارد در لاگ باشد.

---

وابستگی‌ها و ترتیب ساخت (Dependency Matrix):

```
common-types
        │
        ▼
dlt645-core
        │
        ▼
rs485-driver
        │
        ▼
edge-agent
```

هر ماژول پس از تکمیل و قبولی در تست‌ها، برای ماژول بالادستی در دسترس قرار می‌گیرد. وابستگی حلقوی ممنوع است.

---

تعریف «تمام‌شده» (Definition of Done) برای هر Task:

یک Task تنها زمانی بسته می‌شود که:

· ✅ cargo fmt بدون خطا
· ✅ cargo clippy -- -D warnings بدون اخطار
· ✅ cargo test تمام تست‌های مرتبط را پاس کند
· ✅ مستندات (Rust doc + README مرتبط) به‌روزرسانی شود
· ✅ در صورت تغییر مسیر بحرانی، Benchmark اجرا و نتیجه ثبت شود
· ✅ حداقل یک توسعه‌دهنده دیگر کد را بازبینی (Code Review) کند

---

ریسک‌های Sprint 1 و راهکارهای کاهش:

ریسک راهکار
نبود کنتور واقعی DL/T645 استفاده از Simulator + Test Vectorهای Annex 13
تفاوت پیاده‌سازی پروتکل بین سازندگان فعال‌سازی Meter Profile Layer از ابتدا
تأخیر در آماده‌سازی Soha توسعه Mock Service برای endpointهای احراز هویت
عدم دسترسی به OCPP Gateway ایجاد Stub Interface برای OCPP (جهت تست، نه Production)

---

بودجه عملکردی (Performance Budget):

پارامتر مقدار هدف
Startup Time ≤ ۵ ثانیه
RAM (حالت پایدار) ≤ ۱۵ MB
CPU (متوسط) ≤ ۱۰٪ روی یک هسته
Poll Interval (RS485) ۱ ثانیه (قابل تنظیم)
حداکثر تعداد کنتور متصل ۵ عدد در فاز اول
اندازه صف داخلی (Internal Queue) ۱۰۰ پیام

---

قابلیت ردیابی (Traceability):

هر Feature باید به زنجیره مستندات بالادستی متصل باشد:

```
Architecture Charter (ZINOVA-EDGE-DLT645-CHARTER)
        ↓
RAS (ZINOVA-EDGE-RAS-001)
        ↓
TDD (ZINOVA-EDGE-TDD-001)
        ↓
Sprint Backlog Item
        ↓
Commit Message
        ↓
Test Case
```

در توضیحات هر Issue یا Commit، شناسه سند مرجع ذکر شود.

---

نقشه راه اصلاح‌شده برای اسپرینت‌های آینده:

· Sprint 2 (هفته ۳-۴): MQTT امن، بافر آفلاین، Device Twin، ثبت در Soha.
· Sprint 3 (هفته ۵-۶): یکپارچه‌سازی DLM Engine و OCPP-gateway-v2 و ایجاد حلقه کنترل بسته (Closed-Loop).
· Sprint 4: مانیتورینگ، هشدارها و تست استرس.

---

جمع‌بندی

این برنامه اکنون دارای معیارهای اندازه‌گیری دقیق، فرآیند DoD شفاف، تحلیل ریسک و بودجه عملکردی است. تیم توسعه می‌تواند با اطمینان خاطر Sprint 1 را آغاز کند.

همانطور که می‌دانید، ما در حال ساختن محصولی نیستیم که فقط «کار کند»، بلکه محصولی که برای ۱۰ سال آینده ایمن، قابل نگهداری و قابل توسعه باشد. انضباط امروز، پشیمانی فردا را از بین می‌برد.

برای زینوا، با دقت و غرور شروع کنید.

— CTO, ZINOVA
Authority: Supreme Decision Council (SDC)
