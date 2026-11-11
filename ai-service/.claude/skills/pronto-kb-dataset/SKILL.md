---
name: pronto-kb-dataset
description: Prepare, edit, check and load the data the Pronto (ai-service) sales bot answers from - the business profile and the Google Sheet knowledge base (Page and Product tabs, CSV or JSON Lines feeds). Pronto's own version of the general knowledge-base-dataset skill, with the importer's exact format and the lessons from testing the AutoCut bot - which facts must stay in the business profile, how to write promotions with dates, which links to use, and how to verify a change with test_bot and the answer-eval comparison. Use it whenever someone adds, edits, splits, audits or syncs the Pronto knowledge base or business profile, asks "what should the bot know", or wants to change prices, promotions, links or policies the bot quotes.
---

# Pronto knowledge base

The Pronto bot answers from two places, and putting a fact in the wrong one
is the most common way to make it worse:

| Place | Sent to the bot | Holds |
|---|---|---|
| **Business profile** (`/admin` → Business profile: about, rules, tone, contact) | Every reply, whole | Core sales facts, behaviour rules, tone, contact details |
| **Knowledge base** (Google Sheet tabs synced as sources) | Only the few rows that match the message | Everything else: specs, how-to, FAQs, policies, examples |

Testing showed the bot does **not** reliably find the buy link, price,
coupon or tax total by search. Moving them out of the profile cut passes on
the owner's test set from 53 to 36 of 95 (`references/lessons.md`).

Read `references/lessons.md` before changing either place. It records what
each test showed, and it outranks the general rules below when they disagree.
The general method (one fact per row, stable ids, customer wording) is the
`knowledge-base-dataset` skill; this skill adds what is specific to Pronto.

## 1. What goes where

**Profile "about": core sales facts, one short block per product** (about 150-200
characters each):
- the buy link (the course or product page; one buy link per product);
- the normal price, and the promo price with its coupon and end date;
- the price after the promotion ends;
- the tax-invoice total;
- the buying steps in one line, plus any required extra cost.

This block repeats a few sheet facts on purpose. When a price changes,
update both places in the same edit. Past about 15-20 products the block no
longer fits the profile (rules and tone use most of the 4,000-character MCP
limit). At that point the bot needs a code change that always attaches the
right product's card. Raise it as a decision with the owner; don't keep
growing the profile.

**Profile "rules": behaviour.** Hand-offs, what never to promise, refund
handling, what to ask. Don't shorten the existing rules to make room: the
shortened version lost passes (lessons, j10).

**Profile "contact":** channels and numbers. Label each website for what it
is, but don't call one "info and examples": the bot then sends its home page
as the example link (lessons, j10).

**Sheet: everything else.** One fact per row, in the customer's words.

## 2. The sheet format (`internal/feed/feed.go`)

- CSV (or JSON Lines) with a header row and an **`id` column**. Without it,
  the whole file is refused.
- Columns: `id`, `question` + `answer` (FAQ), or `title` + `content`
  (document), `category`, `section`, `start_date`, `last_day` (YYYY-MM-DD).
  Thai names work too: รหัส, คำถาม, คำตอบ, หัวเรื่อง, เนื้อหา, หมวด,
  หัวข้อ, วันเริ่ม, วันสุดท้าย. With no `title`, the title becomes
  `category: section`. The importer ignores other columns (for example
  ต้องยืนยัน, อัปเดตล่าสุด).
- Limits: 500 rows per source, id up to 120 characters (longer ids are
  skipped), title up to 300 characters (cut).
- Each sheet tab is one source (its own link, `gid`). Documents are keyed
  `feed:<source id>:<row id>`, so **never change an id or move a row between
  tabs**. The row is treated as deleted and added again.
- The sheet must be shared "Anyone with the link: Viewer". That makes it
  public, so keep private data out of it (staff mobile numbers included,
  unless the owner chose to publish them).
- Current production sources (account 1): Page tab (source 5) and Product tab
  (source 6), synced every 24 hours. Id prefixes `page-` and `product-`.

## 3. Writing rows that work

- **Promotions: write both sides with dates.** The bot knows today's date. A
  row that says "ถึงวันที่ 30 พ.ย. 2026 ใส่คูปอง ... เหลือ 3,900 บาท
  ตั้งแต่ 1 ธ.ค. 2026 ราคา 9,900 บาท ไม่มีคูปองลด" answers before and after
  the deadline. Use `last_day` only for a row that should disappear entirely.
  An expired row drops the after-promotion price with it.
- **Exact links.** Link the page the customer needs (course page to buy,
  `/examples` for samples). Never a home page.
- **Facts, not orders.** "ไม่มีทดลองใช้ฟรี" is a fact. "บอทห้ามเสนอ..."
  is a rule; put it in the profile rules. Existing rows with instructions
  work, so move them when you next edit them, not all at once.
- **Keep the owner's decisions verbatim.** Refunds: "no" in principle, but
  if the customer insists, hand off and compromise. Never invent a policy;
  list open questions for the owner.

## 4. Check

```bash
python3 .claude/skills/pronto-kb-dataset/scripts/pronto_check.py page.csv product.csv --today YYYY-MM-DD
```

Export each tab as CSV first (or read it with the Google Sheets MCP and save
it as CSV). The checker runs the general checks (missing or duplicate ids,
dates, expired rows, near-duplicates, rows that refer to other rows) plus the
Pronto ones:
- an id column, and the id and title limits;
- a promotion with an end date but no after-price;
- home-page links, with a list of every link and the rows that use it;
- mobile numbers;
- rows that instruct the bot.

Fix every error. Explain each warning you leave.

Tests: `python3 -m unittest discover -s .claude/skills/pronto-kb-dataset/scripts`.

## 5. Load and verify

1. **Back up first.** Copy the tabs to "Backup <tab> <date>" in the same
   sheet before a big edit.
2. **Sync.** Use `sync_source` (pronto-prod MCP) or the Knowledge base page.
   Read the result: rows imported, skipped, and why.
3. **Profile changes.** `update_profile` sends a proposal the owner approves
   on `/admin` → Approvals. An AI tool can't add links, @handles, LINE IDs or
   long numbers to the profile; the owner pastes those on the admin page.
   Give them the exact text.
4. **Spot check.** Run `test_bot` with the 5 key questions: price, how to
   buy, tax invoice, after the promotion, refund. The buy link, coupon and
   prices must be right.
5. **Bigger changes** (profile rules, tone, moving facts between places):
   compare before and after with the answer-eval runner on a local copy of the
   database. Never test on production. Change **one thing per test**, and
   keep a change only if it wins on both test sets without losing fact
   accuracy.

Every sync and every approved profile change reaches real customers at once.

## 6. Keep this skill current

This skill is expected to change. When a test, an owner decision or an
importer change teaches something new:
1. Add a dated entry to `references/lessons.md`: what changed, the numbers,
   and the rule it implies.
2. Update the matching rule above, and the checker if it can test the rule
   (with a unit test).
3. When `internal/feed/feed.go` changes its columns or limits, update §2 and
   the constants at the top of `scripts/pronto_check.py` in the same PR.
