# Goftino Feature Map — باز مهندسی‌شده از پنل واقعی (اسکن 1405)

> منبع: اسکن مستقیم پنل `my.goftino.com` با نشست واقعی + تحلیل JS پنل (`goftino.js?v=279`, ~585KB) و runtime ویجت عمومی.
> کاربرد: مرجع پیاده‌سازی parity در فاز P3.

## 1. ساختار حساب
- هر ادمین چند **سایت (site)** دارد؛ هر سایت = یک widget instance با `gid` (مثل `kWrYfy`) و `sid`.
- نقش‌ها: `admin-op-owner`, اپراتور؛ access flags per-op: chat/online/rate/report/edit/tag/archive.
- API پنل همه زیر `/action/*` است (SPA با jQuery + navigo router + socket.io realtime).

## 2. Endpoints کشف‌شده (برای طراحی معادل، نه کپی)
| گروه | endpoint ها | معادل ChatPaw |
|---|---|---|
| auth | `a_signin`, `login_2factor`, `check_session`, `verify_tel` | Devise + 2FA موجود |
| dashboard | `dashboard/{sid}`, `count_online_ops/{sid}`, `count_online_visitors/{sid}` | CW reporting |
| چت | `chatlist/getlist/getmore`, `chatlist/chat/{id}`, `odata`, `user_data/{id}`, `send2offuser`, `readypms`, `opfilter`, `groupchat` | Conversation API |
| تنظیمات | `setting/{sid}` (کل کلیدهای زیر)، `setting/{sid}/aibot` | Inbox/Account settings |
| اپراتور | `operators/{sid}`, `add_operator_step1/2`, `edit_operator_profile`, `setopaccess`, `del_operator`, `distribution/oplist|addremoveop|mystatus` | Agents+Teams+assignment |
| جانبی | `tagslist`, `gettags`, `ban_list`, `unblock`, `rate_comment`, `ratedetails`, `export*`, `smstemplate`, `send_test_sms`, `telegram_api`, `bale_connection`, `getapikey`, `report_all_sids`, `affiliate*`, `bills/generatebill` | engines/chatpaw_goftino |

## 3. کلیدهای `GET /action/setting/{sid}` (پروفایل کامل ویجت)
```json
{
  "position": "right", "color": "rgb(2,61,102)", "icon": "<cdn url>",
  "toptext1": "Contact whit Me", "toptext2": "...",
  "showinmob": "1", "margin": {"rl":"30","bottom":"30"}, "marginmob": {...},
  "canmic": "yes", "canattach": "yes", "hide_ops_name": false,
  "readypms": { "my": [["intro","<html>"]], "others": {} },
  "autopm": [],                    // پیام خودکار ورود
  "onstart": {"action":"none","top":"","form":[]},     // فرم شروع
  "ondelay": {"action":"text","timer":120,"top":"در دسترس نیستم...","form":[]},
  "offha": [], "offaction": "show",                    // صفحات مخفی/آفلاین
  "sound": {...}, "worktime": "", "assignop": "",
  "telegram": "", "bale": "", "lang": "en",
  "motion": {"style":"tada","timer":"2"},
  "rating": "", "api": "", "distribution": "",
  "showTypingText": "", "widgetAuthentication": ""
}
```
→ این JSON دقیقاً الگوی `theme.json` ماست (§6 PLANNING.md).

## 4. AI Bot گوفتینو
- فقط پلن حرفه‌ای+: `GET /action/setting/{sid}/aibot` → `{"error_detail":"upgrade_plan"}` روی free.
- منطق سمت سرورشان بسته است؛ مدل/مدل‌ها نامشخص (بدون رفرنس OpenAI در bundle).
- **ما:** open با AiRouter (PLANNING §5) — مزیت رقابتی اصلی.

## 5. ویجت runtime (نکات فنی)
- لودر async با `requestIdleCallback`، iframe `goftino_w`، نسخه‌بندی `?o=` از localStorage.
- API عمومی window.Goftino: `open/close/toggle/sendMessage/setUser/setUserId/reload/destroy`.
- localStorage keys: `goftino`, `_autopm_{gid}`, `_startform_{gid}`, `_unread_{gid}`.
- realtime با socket.io; صداها mp3 در `/static/assets/sound/s(n).mp3`.
→ SDK ما همان DX را با postMessage/BroadcastChannel میسازد + API سازگار (`window.ChatPaw.open()` …).

## 6. پلن‌ها (قیمت رسمی 1405)
رایگان: ۲اپ/۱۰۰چت/۳۰روز · استارتاپ ۲۴۹هزار: ۴/۵۰۰/۱سال · حرفه‌ای ۵۴۹هزار: ۱۰/۲۰۰۰/۳سال + AI/API/SMS/توزیع · تجاری ۱.۱۹میلیون: ۱۰۰/۱۰٬۰۰۰.
→ ماتریس تبدیل به «همه رایگان» در PLANNING.md §4.4.
