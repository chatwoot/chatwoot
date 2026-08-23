# PLANNING.md — Maddix-Chat → «ChatPaw» 🐾

> **ماموریت:** ساخت یک پلتفرم گفتگوی مشتری + CRM متن‌باز و رایگان، از فورک Chatwoot، با ادغام کامل قابلیت‌های Goftino، هویت بصری جدید، لایه هوش مصنوعی با اتصال به هر Router/API سازگار با OpenAI (OpenRouter / LiteLLM / OmniRoute / NineRouter / Ollama / Groq / vLLM)، ویجت قابل‌سفارشی‌سازی با حالت Pet و ابزار تولید ویجت با AI.
>
> **وضعیت:** فورک تازه از Chatwoot `v4.17.0` (کمیتی که کلون شده). این سند نقشه راه اجراست — هر سِشن عامل (agent) باید همینجا شروع کند.

---

## 1. هویت پروژه

| مورد | مقدار |
|---|---|
| **نام محصول (پیشنهاد اصلی)** | **ChatPaw** (چت‌پا) — ترکیب Chat + Paw؛ پیوند مستقیم با تم Pet/مَسکات |
| **جایگزین‌ها** | PawDesk · NexChat · Mochat · OpenPaw |
| **تگ‌لاین EN** | *Customer conversations with a soul.* |
| **تگ‌لاین FA** | «گفتگو با مشتری‌ها، با یک رفیق دیجیتال» |
| **ریپو** | `maddixmhn/Maddix-Chat` (عمومی، جدا از سایت شخصی) |
| **لایسنس هدف** | MIT (ارثی از Chatwoot core) — بخش‌های حذف‌شده enterprise را **هرگز** برنگردان |

### 1.1 پالت رنگ

| نقش | دارک | لایت |
|---|---|---|
| Primary (teal) | `#1fe0b5` | `#12b892` |
| Secondary (blue) | `#1ba5ff` | `#0f7fd4` |
| Accent (amber paw) | `#ffc857` | `#e8a020` |
| Background | `#0d1f26` | `#f7f9fa` |
| Surface/card | `#122b34` | `#ffffff` |
| Text | `#e6f1ef` | `#1a2b30` |
| Danger | `#ff6b6b` | `#d64545` |

گرادیان برند: `135deg, #1fe0b5 → #1ba5ff` (هماهنگ با هویت شخصی maddix).

### 1.2 تایپوگرافی
- EN/UI: **Inter** (variable)
- فارسی: **Vazirmatn**
- مونو: JetBrains Mono
- RTL باید شهروند درجه‌یک باشد (Goftino قوت اصلیش فارسی است — ما هم `dir=rtl` را first-class میکنیم).

### 1.3 لوگو و مَسکات
- آیکون: بلاب رباتِ گرد با **اثر جای پنجه (paw)** روی شکم — SVG برداری در `docs/brand/logo-icon.svg` (نسخه اولیه ضمیمه شده).
- وردمارک: "ChatPaw" با p انتهایی به‌شکل پنجه.
- مَسکات: همان خانواده MaddyBot (بلاب سبز→آبی) ولی با پنجه؛ اسم مَسکات پیشنهادی **«Pawly»**.

---

## 2. نکته حقوقی مهم (قبل از هر کدی)

1. پوشه `enterprise/` لایسنس اختصاصی دارد و در فورک عمومی **باید کامل حذف شود** (کد + spec ها + رفرنس‌ها در `config/routes.rb`، `Gemfile`، `.github/workflows`).
2. کپی‌رایت Chatwoot در `LICENSE` حفظ شود (MIT اجازه فورک و ریبرندینگ می‌دهد، مشروط به نگهداشتن notice).
3. نام‌ها/لوگوی Chatwoot از UI، ایمیل‌ها، متا و docker image names پاک شوند.

---

## 3. استک فعلی (چه چیزی داریم)

- **Backend:** Rails 7.2.3 (API+SSR)، PostgreSQL (+ **pgvector** ✅ برای RAG آماده‌ایم)، Redis، Sidekiq 7 + sidekiq-cron، Devise (+2FA)، Puma، vite_rails
- **Dashboard:** Vue 3 (پکیج dashboard در `app/javascript/dashboard`)
- **Widget:** vanilla JS (`app/javascript/widget`) + SDK عمومی `@chatwoot/chatwoot-livechat`
- **Channelها:** وبسایت، تلگرام، واتساپ، فیسبوک/اینستاگرام، ایمیل، SMS/Twilio، Line…
- **AI موجود:** Captain (سمت cloud/enterprise محدود) — ما نسخه open خودمان را میسازیم (فاز P4)

**اصل طلایی معماری:** برای حفظ امکان merge از upstream، کدهای سفارشی را تا حد ممکن در موتورهای مجزا بنویسیم:
```
engines/chatpaw_ai/        # AiRouter + RAG + agent logic (Rails engine)
engines/chatpaw_goftino/   # parity features گوفتینو که در core جا نمیشوند
services/ai-gateway/       # (اختیاری) Node microservice سبک برای LLM proxy
apps/pet/                  # Tauri desktop pet
packages/widget-theme/     # تم‌ها و آیکون‌های ویجت
```
اگر تغییری در core لازم شد: کوچک، ایزوله و با کامنت `// [chatpaw]` نشانه‌گذاری شود.

---

## 4. ماتریس ادغام قابلیت‌ها (Chatwoot ∪ Goftino ∪ نوآوری)

### 4.1 از Goftino میآیند (چکلیست پیاده‌سازی)
- [ ] ساعت کاری per-inbox با پیام آفلاین خودکار (worktime + offaction) — CW پایه business hours دارد؛ UI گوفتینویی + فرم آفلاین
- [ ] پیام تأخیر پاسخ (ondelay: بعد از N ثانیه پیام/فرم نشان بده)
- [ ] پاسخ‌های آماده دوزبانه با کلید (readypms) — CW canned responses دارد؛ sync با widget-side quick replies
- [ ] امتیازدهی اپراتور بعد از پایان گفتگو (rating) + گزارش — CW CSAT دارد؛ ارتقا: NPS
- [ ] ضبط و ارسال ویس در ویجت (voice notes)
- [ ] انتخاب دپارتمان در شروع گفتگو (department picker)
- [ ] توزیع خودکار گفتگو بین اپراتورها + صف انتظار (round-robin / least-busy) — CW assignment policy دارد؛ ارتقا با صف زمان واقعی
- [ ] مسدودسازی کاربر مزاحم با قانون (IP/شناسه) — CW blocklist دارد؛ UI بهتر + مدت‌دار
- [ ] برچسب‌گذاری + گزارش تگ‌ها
- [ ] احراز هویت کاربر در شروع گفتگو (widget auth mode)
- [ ] نمایش «در حال تایپ» کاربر به اپراتور (typing text visibility toggle)
- [ ] ارسال پیامک به اپراتور/کاربر — آداپتر HTTP جنریک (Kavenegar، SMS.ir، Twilio)
- [ ] خروجی گرفتن داده‌ها (CSV/JSON export)
- [ ] پیام گروهی به بازدیدکنندگان قبلی (campaigns — CW دارد؛ پوشش UI گوفتینویی)
- [ ] پرسش‌های چندمرحله‌ای در شروع گفتگو (multi-step pre-chat form) → در فاز Flow Builder ادغام
- [ ] حرکت‌های ویجت (motion presets: tada/bounce/wiggle) + صداهای رویداد (sound pack)
- [ ] چند سایت در یک حساب (CW multi-account/inbox ✅ فقط UX شبیه گوفتینو)
- [ ] اتصال به **بله** (Bale bot channel — جدید! نه CW دارد نه خیلی‌ها)
- [ ] حذف برندینگ از ویجت (در ما همیشه آزاد است 😄 ولی تم سفارشی کامل)

### 4.2 از Chatwoot میمانند (دارایی‌ها)
Omnichannel کامل، Teams، Labels، Automation rules، Macros، Reports، Campaigns، Help Center/Portal، API+Webhook+Platform API، Integration (Slack/Dashboard apps…)، Mobile app، SLA، Audit log پایه، SSO.

### 4.3 نوآوری‌های ما (در هیچ‌کدام نیست یا ناقص است)
1. **🤖 Desktop Pet (Tauri)** — مَسکات شناور روی دسکتاپ اپراتور: اعلان گفتگوی جدید با انیمیشن، drag، کلیک = باز شدن inbox. برای ویژیت‌ها هم «pet mode» داخل ویجت.
2. **🧠 BYOR — Bring Your Own Router:** اتصال به هر endpoint سازگار با OpenAI (OpenRouter/LiteLLM/**OmniRoute**/**NineRouter**/Ollama/vLLM/Groq) با config per-account در UI + fallback chain + cost tracking.
3. **✨ AI Widget Generator:** توصیف زبانی («ویجت صورتی برای فروشگاه گل با لحن صمیمی») → تولید theme JSON + آیکون + پیام‌های خوشآمد + mini-flow.
4. **📚 RAG بومی با pgvector:** هضم مقالات Help Center → پاسخ خودکار دقیق AI Agent (بدون سرویس خارجی).
5. **🎨 Widget Theme Marketplace:** تم‌های JSON اشتراکی + آیکون‌های دیفالت (۸ عدد: paw-blob، گربه، جغد، روباه، ghost، robot-box، قلب، ستاره).
6. **🔒 Privacy-first self-host:** `docker compose up` تک‌فرمانی روی localhost، بدون هیچ تماس خروجی اجباری.
7. **RTL-first i18n** (fa/en/ar) در dashboard و ویجت.
8. **Flow Builder no-code** (الهام از Tiledesk/Botpress): درخت تصمیم برای pre-chat و bot پاسخگو — فاز آخر.
9. **Co-browsing lite** (نمایش اسکرول/هاور بازدیدکننده با اجازه) — optional/بعداً.
10. **Plugin hooks for widgets:** dashboard apps سمت visitor (نمایش داده CRM کنار چت).

### 4.4 مقایسه پلن‌های گوفتینو → در ما همه رایگان
| گوفتینو | رایگان | استارتاپ 249K | حرفه‌ای 549K | تجاری 1.19M | **ChatPaw** |
|---|---|---|---|---|---|
| اپراتور | ۲ | ۴ | ۱۰ | ۱۰۰ | ♾️ self-host |
| گفتگوی جدید/ماه | ۱۰۰ | ۵۰۰ | ۲۰۰۰ | ۱۰٬۰۰۰ | ♾️ |
| آرشیو | ۳۰روز | ۱سال | ۳سال | ۳سال | ♾️ |
| AI / API / SMS / توزیع خودکار | ❌ | ❌ | ✅ | ✅ | ✅ همه |
| Self-host | ❌ (فقط سازمانی) | ❌ | ❌ | ❌ | ✅ ذات محصول |

---

## 5. طراحی لایه AI (AiRouter)

```yaml
# engines/chatpaw_ai/config/providers.example.yml
providers:
  omniroute_local:      # هر اسم دلخواه
    type: openai_compatible     # تنها نوع لازم است!
    base_url: http://localhost:PORT/v1
    api_key_env: OMNIROUTE_KEY  # هرگز key در DB plaintext
    models: [gpt-4o-mini, llama-3.3-70b]
  ninerouter:
    type: openai_compatible
    base_url: https://api.ninerouter.../v1
  ollama_local:
    type: openai_compatible
    base_url: http://localhost:11434/v1
  groq_cloud:
    type: openai_compatible
    base_url: https://api.groq.com/openai/v1
routing:
  primary: omniroute_local
  fallbacks: [groq_cloud]
budget:
  monthly_usd_cap: 10
```

قابلیت‌هایی که از آن تغذیه میشوند:
1. **AI Agent inbox** (پاسخ خودکار با RAG روی Help Center) — جایگزین open-source Captain
2. **Copilot اپراتور**: پیشنهاد پاسخ، خلاصه گفتگو، sentiment، ترجمه
3. **Widget AI assistant**: همان چیزی که برای maddixmhn.github.io ساختیم (MaddyBot) — عمومیت یافته
4. **Widget Generator**: prompt → theme+flow JSON
5. **Smart routing**: دسته‌بندی/اولویت خودکار تیکت‌ها

اجرا: Rails engine با `OpenAI-compatible client` ساده (Faraday) — بدون وابستگی به SDK سنگین. Streaming با ActionCable/SSE.

---

## 6. ویجت و Pet

- **widget fork:** همان `app/javascript/widget` با پوسته تم‌محور: `theme.json` شامل colors، icon (از ۸ دیفالت یا upload)، motion، sound، position، RTL، department picker، pre-chat form چندمرحله‌ای، pet-mode.
- **pet-mode در ویجت:** مَسکات انیمیشنی (SVG sprite مثل MaddyBot: blink/bob/wiggle/eye-track) که خودش bubble چت است.
- **Desktop pet:** `apps/pet` با **Tauri 2** (سبک‌تر از Electron): WebView شفاف + همان spriteها؛ اتصال به API با token اپراتور؛ WebSocket برای «conversation.created» → hop + notification.
- آداپتور embed همان الگوی فعلی: `<script src=".../sdk.js" data-site-id>`.

---

## 7. نقشه راه (Phases + Acceptance)

| فاز | محتوا | Acceptance Criteria |
|---|---|---|
| **P0 — Detox & Brand scaffold** | حذف `enterprise/` و رفرنس‌ها، rename package به `@chatpaw/core`، logo/palette tokens، LICENSE، docker compose rename، `upstream` remote | ✅ **انجام شد (2026-08-23):** enterprise/ و spec/enterprise حذف؛ رفرنس‌های Ruby/CI پاک؛ `@chatpaw/core`؛ brand assets + توکن‌های `cp-*`؛ compose ها chatpaw؛ README جدید. *باقیمانده: اجرای rspec روی ماشین با Ruby (لوکال فعلی فقط Node دارد)* |
| **P1 — Dashboard reskin + RTL** | Inter/Vazirmatn، CSS variables برند، login/sidebar/topbar، i18n fa کامل dashboard | اسکرین‌های قبل/بعد؛ تست e2e لاگین fa/en |
| **P2 — Widget revamp** | تم JSON، ۸ آیکون دیفالت، motion/sound، voice note، dept picker، offline form، RTL | دمو صفحه HTML با ۳ تم متفاوت از یک build |
| **P3 — Goftino parity backend** | worktime، ondelay، ban rules، rating/NPS، export CSV، SMS adapter، Bale channel، auto-distribution queue | هر feature حداقل ۱ request spec؛ UI فارسی |
| **P4 — AI layer** | chatpaw_ai engine، provider UI، AI Agent + RAG(pgvector)، copilot، widget AI toggle | پاسخ grounded از مقالات با citation؛ fallback بین providerها تست شود |
| **P5 — Pet** | Tauri app + widget pet-mode | pet روی ویندوز/مک اعلان بدهد و inbox باز کند |
| **P6 — Flow builder & launch** | flow editor، marketplace تم، docs site، demo online | ویدیو دمو ۲ دقیقه‌ای + README نهایی |

**قانون merge upstream:** ماهانه `git fetch upstream && git merge upstream/main` در برنچ `sync/upstream` + رزولوشن تعارض (بهخاطر ایزولاسیون engines باید کم باشد).

---

## 8. اجرای localhost (هدف DX)

```bash
# dev کامل
docker compose -f docker/compose.yaml up -d postgres redis mailhog
overmind start            # rails + vite + sidekiq از Procfile
# → dashboard: http://localhost:3000 ; widget demo: /widget

# یک‌خطی برای تازه‌کارها (P0 تحویل دهد)
docker compose -f docker/compose.prod.yaml up   # همه‌چیز در یک stack
```

---

## 9. تحقیق رقبا (خلاصه — چه چیز دیگری بدزدیم… به معنی خوبش 😄)

| پروژه | چیزی که یاد میگیریم |
|---|---|
| **Tiledesk** | flow builder بصری + multichannel ساده |
| **Botpress v12** | NLU محلی، آموزش intent با مثال |
| **Crisp** | KB درون‌چت، shared inbox UX، mobile کیفیت |
| **Rocket.Chat** | omnichannel + livecall (تماس صوتی از ویجت — roadmap دور) |
| **Typebot** | builder گرافیکی فرم/چت — مرجع UX برای flow builder |
| **Twenty CRM** | datamodel مدرن CRM (contact timeline) — الهام CRM view ما |
| **tawk.to** | سادگی onboarding (paste ۱ خط) + monitoring زنده بازدیدکننده |

---

## 10. ترتیب کاری سِشن بعدی (Quick Start برای agent)

1. `AGENTS.md` را بخوان.
2. P0 را طبق §7 انجام بده (enterprise detox اول!). commit های کوچک، پیام‌های conventional.
3. هر فاز تمام → جدول §7 را آپدیت کن (تیک + تاریخ).
4. تست‌ها را قبل از هر push اجرا کن: `bundle exec rspec` (حداقل related specs) + `npm run build` برای javascript touched.
