# AGENTS.md — راهنمای شروع برای هر عامل/سِشن جدید

## این ریپو چیست؟
فورک Chatwoot v4.17.0 در حال تبدیل به **ChatPaw** — پلتفرم open-source گفتگوی مشتری + CRM با قابلیت‌های گوفتینو، لایه AI با اتصال به هر OpenAI-compatible router (OmniRoute/NineRouter/OpenRouter/LiteLLM/Ollama/Groq)، ویجت تم‌محور و Desktop Pet.

## اول از همه
1. **`PLANNING.md` را کامل بخوان** — منبع حقیقت: برند، معماری، فازها، ماتریس قابلیت.
2. جدول فازها (§7) را ببین؛ کاری که شروع میکنی باید داخل یکی از فازها باشد. اگر فاز قبلی ناتمام است، همان را تمام کن.
3. وضعیت فعلی: فاز P0 انجام نشده. کارهای P0 به ترتیب:
   - [ ] `git rm -r enterprise/` و حذف همه رفرنس‌ها (`Gemfile`, `config/routes.rb`, `spec/`, `.github/workflows/*`, `app/` جستجوی `Enterprise::`)
   - [ ] rename در `package.json`: name → `@chatpaw/core`
   - [ ] اضافه کردن brand tokens (رنگ §1.1 PLANNING.md) به CSS variables dashboard
   - [ ] لوگوها از `docs/brand/` به assets
   - [ ] اجرای تست: `bundle exec rspec spec/models spec/controllers` (زیرمجموعه سریع)
4. remote `upstream` تنظیم شده است → هرگز مستقیم به آن push نکن.

## قوانین سخت (Non-negotiables)
- **ایزوله بنویس:** کد جدید در `engines/chatpaw_*` یا `services/`. تغییر core فقط حداقلی با کامنت `// [chatpaw]`.
- enterprise code را هرگز restore/کپی نکن.
- API keys هرگز در repo/DB plaintext نیست — فقط env reference.
- commit های کوچک conventional: `feat(widget): ...` / `chore(brand): ...`
- قبل از push: تست مربوطه سبز باشد.

## فرمان‌های مفید
```bash
bundle install && yarn install          # setup
bin/rails db:prepare                     # db
overmind start                           # همه سرویس‌ها (Procfile)
bundle exec rspec spec/path/to_spec.rb   # تست هدفمند
yarn build                               # javascript packs
docker compose -f docker/compose.yaml up -d  # pg+redis
```

## ساختار سفارشی هدف
```
engines/chatpaw_ai/       # فاز P4
engines/chatpaw_goftino/  # فاز P3
apps/pet/                 # Tauri — فاز P5
packages/widget-theme/    # تم‌ها — فاز P2
docs/brand/               # لوگو/پالت
docs/goftino-feature-map.md  # نقشه معکوس قابلیت‌های گوفتینو
```

## تعریف «تمامشدن» هر PR/commit
- کد + تست + UI فارسی/انگلیسی + آپدیت چک‌لیست فاز در PLANNING.md §7
