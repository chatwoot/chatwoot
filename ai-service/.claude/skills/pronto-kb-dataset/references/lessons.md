# Lessons from testing the Pronto bot

Newest first. Each entry: what was tested, the numbers, and the rule it
implies. The test sets are the owner's 95 rated chats ("john-95") and 49 real
customer chats ("real-49"), 3 runs each, on a local copy of the database,
judged by answer-eval plus a "closer" sales judge. Pass counts are means over
the 3 runs.

## 2026-11-12: core sales block in the profile, shortened rules (j10)

Changed (all at once): round 6 bot rules; profile "about" with a core sales
block (course link, price, coupon, end date, after-price, tax total, buying
steps); profile rules shortened from about 7,700 to about 3,700 characters to
fit the MCP limit; new tone; contact relabelled the AutoCut site "info and
example clips, not the place to buy".

| | Baseline (g10) | j10 |
|---|---|---|
| john-95 pass | 53.3 | 41.3 |
| real-49 pass | 25.0 | 23.7 |
| Fact accuracy | 95-98% | 96-99% |
| Replies with the course buy link | 42 | 48 |

Discarded. Rules implied:
- The core sales block works: buy links came back, and fact accuracy rose.
- Shortening the rules lost details the bot needed. Gone were "the team
  continues in this chat", "2,900 is the old price from the ad, apologise",
  and "1 licence = 1 computer". Don't shorten working rules; add to them.
- Calling a website "info and examples" in the contact field made the bot
  send its home page as the example link (39 of 432 replies).
- Changing four things in one test hid which one hurt. Change one per test.

## 2026-11-11: all product facts moved to the sheet (i10)

Changed: profile "about" with no product facts (everything in the sheet),
plus round 6 rules, new tone and updated sheet.

| | Baseline (g10) | i10 |
|---|---|---|
| john-95 pass | 53.3 | 36.3 |
| real-49 pass | 25.0 | 20.3 |
| "I don't know" replies | 16 | 2 |

Discarded. Rules implied:
- Search does not reliably return the buy link, price, coupon or tax total.
  Keep them in the profile.
- With no buy link in the profile, the bot took the sales website from the
  contact field (16 of 432 replies), with no coupon or price.
- The rule "never say ไม่ทราบ" works (16 → 2) and is kept.

## 2026-11-11: embedding model name (eval setup)

The knowledge base stores chunks under the plain model name
(`text-embedding-3-large`). An eval env using `openai/text-embedding-3-large`
made every search return nothing. Results from before this fix measured the
bot without its knowledge base. Production was not affected.

## 2026-11-11: owner decisions on content

- After 30 Nov 2026 the price returns to 9,900 baht with no coupon.
- Refunds: "no" in principle; if the customer insists, hand off and
  compromise.
- Promotion text names both dates, since the bot knows today's date.
