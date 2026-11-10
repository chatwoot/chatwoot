# Contract: Facebook Page comment leads

Issue: DEV-Johnstocker/chatwoot#1. Owner request (2026-11-09): read comments on
our Facebook Page and open a Messenger conversation with people likely to
become customers.

## Scope

- `GET/POST /webhooks/meta`: Meta's Page `feed` webhook.
  - The `GET` subscription check echoes only a short `[A-Za-z0-9_-]` challenge, and only for the right verify token.
  - `POST` bodies must carry a valid `X-Hub-Signature-256`, the HMAC-SHA256 of the raw body with the app secret.
  - Only `feed` / `comment` / `add` events for `META_PAGE_ID` by someone other than the Page are stored. `remove` deletes an unanswered comment.
- Storage on schema v13 (`fb_comments`):
  - one row per Meta comment ID, so retries and replays add nothing;
  - a comment deleted on Facebook keeps a blank `removed` row whatever its status, so a late retry or a replay cannot bring it back, and its text leaves the history too;
  - a row the database refuses for good (an ID over its length, say) is logged and skipped, so it never blocks the rest of a delivery;
  - row level security on, `anon`/`authenticated` revoked;
  - rows deleted 30 days after they arrive.
- **Post context** (2026-11-11): before drafting, the worker reads the post the comment was left on (`GET /{post-id}?fields=message,attachments{title,description}` with the Page token; `pages_read_engagement`).
  - Only digit-and-underscore post IDs are read, so a webhook value cannot change the Graph path; the token goes in the header, and errors name the Graph host only.
  - Posts are cached in memory for an hour (at most 500), so many comments on one post cost one read. Failed reads are not cached. Nothing new is stored in the database.
  - The post goes to the drafter inside `<post>` tags (tag look-alikes removed) and to both reviewers as `post.text`. The drafter answers about the post's topic and, when the profile does not cover it, offers to send details in chat instead of pitching the profile's other products.
  - A comment whose post could not be read is still drafted, but the reviewer always holds it ("post unknown").
  - `/admin/comments` shows "On the post: …" (240 characters) on each card.
  - Without `META_PAGE_TOKEN` drafts are written without the post.
- A background worker (every 20 s) asks the main LLM to classify each new comment as `lead`, `question`, `complaint` or `other`, give a one-line reason, and draft a reply in the business's tone (`profile.Prompt`).
  - `other` is ignored.
  - A failed model call leaves the comment for a later pass, behind comments that have not failed. After 3 failures it goes to the owner unscored ("Not sorted").
  - The comment and the commenter's name are inside `<comment>` tags with tag look-alikes removed. The page labels every draft as an AI suggestion to check, because a comment can still steer what the model writes.
- `/admin/comments` (same auth and cross-origin protection as every admin page, form capped at 16 KiB):
  - waiting comments, newest first (at most 100), each with the time left in Meta's 7-day window;
  - an editable draft, **Send private reply** and **Dismiss**;
  - a history of the last 20.
- Sending:
  - Graph `POST /{page-id}/messages` with `recipient.comment_id`, the token in the `Authorization` header (never in the URL).
  - The comment is claimed at the version the owner saw, so double clicks and two tabs send once.
  - Meta's permanent refusals (10900 already replied, 10903 cannot reply, 551 unavailable) move it to history.
  - Other failures leave it waiting with the error shown; network errors name the Graph host only, never the full URL.
  - If Meta accepts the reply but recording it fails, the page says so ("Sent, but saving that failed") and the comment stays `sending` in the history; it cannot be sent again.
- **Shadow AI reviewer** (`review.go`, `reviewers.go`). After each draft, a second AI pass answers typed questions:
  - one choice: the intent;
  - four yes/no probabilities, all phrased so that yes is good: answers the comment, makes no unbacked offer, the tone fits, the comment is genuine.

  Code then decides "would send" or "would hold":
  - only leads and questions, with at least 0.80 probability between them;
  - thresholds are in code;
  - code rules always hold a draft with a link, a long number, a price, a percentage or over 600 characters.

  It records its answer next to the comment and **never sends**. `/admin/comments` shows its call on each card and how often it agreed with the owner. An owner who changed the draft before sending counts as a hold.

  The question shape follows TypeSafe's System One primitives (Choice and Noul), so `COMMENT_REVIEWER=jev` and `COMMENT_REVIEWER=llm` answer the same contract.
- Off unless `META_APP_SECRET`, `META_VERIFY_TOKEN`, `META_PAGE_ID` and `DATABASE_URL` are set. Without `META_PAGE_TOKEN` the queue fills but Send is refused.

## Not in scope (later, each needs the owner's decision)

- Automatic sending without approval. The shadow reviewer only collects evidence for that decision. Turning it on is a separate change and the owner's call, after the agreement numbers on real comments.
- Public replies under the comment, which need `pages_manage_engagement`.
- Hiding spam comments.
- Instagram comments.
- More than one Page per service.
- Knowledge-base lookups in drafts. Drafts use the business profile only, and the owner reviews every one.
- The Meta app itself, App Review and the public route (phase 2, below).

## Accepted risks (owner to confirm)

- A captured, signed `add` replayed **after** the 30-day purge is stored again. It cannot be sent, because the 7-day window uses Meta's signed `created_time`; it costs one model call and shows as too late to reply.
- Meta puts `hub.verify_token` in the subscription check's query string, so proxy access logs may record it. It only lets someone complete the handshake. Rotate it if those logs are shared.
- **Prompt injection can reach the reviewer's scores.** The comment and the draft are part of its input, so a well-crafted comment can push every check toward "fine". Today the result is only a hint on `/admin/comments`. `Review.Pass` must never gate a real send until the benchmark has injection cases in both the comment and the draft, and the shadow numbers on real comments hold up.
- **New data flow when `COMMENT_REVIEWER=jev`.** The commenter's name, the comment, the draft and the business profile go to TypeSafe (`api.typesafe.ai`), a processor the service did not use before. It is opt-in, and production stays on `llm` (the existing provider). Before switching, add TypeSafe to the privacy policy and to the Meta App Review data-handling answers. `llm` mode sends the same data to the existing provider a second time, so it costs one extra model call per draft.
- One Page per service: `comment_id` is unique across the table and `Forget` is not account-scoped. Make both per account before adding a second Page.

## Acceptance gates

Run from `ai-service/`:

```bash
gofmt -l . && go vet ./... && go test -race ./...
TEST_DATABASE_URL=postgres://… go test -p 1 ./internal/comments/ ./internal/knowledge/ ./internal/admin/
```

1. A signed comment is stored once. A replay, Meta's retry, or a signature that is missing, wrong or for another body changes nothing; the bad signatures get 401, an oversized body 413 (`webhook_test.go`).
   - A deleted comment stays out, even when the delete arrives before the add. One refused row does not block the rest of the batch (`webhook_test.go`, `store_test.go`).
2. The subscription check refuses a wrong token, a wrong mode and a non-token challenge (`meta_test.go`, `webhook_test.go`).
3. The Page's own comments, edits, other Pages and non-comment events are skipped (`meta_test.go`).
4. Send refuses, without calling Meta and leaving the comment waiting, when any of these holds (`queue_test.go`, `comments_test.go`):
   - the reply is empty or longer than 2,000 characters;
   - the comment is older than 7 days;
   - the version is stale;
   - it belongs to another account;
   - no Page token is set.
5. One Send per comment, even when clicked twice (`queue_test.go`, `store_test.go` on Memory and Postgres).
6. `/admin/comments` needs the admin password, refuses cross-site POSTs, escapes comment text and shows only the chosen account (`comments_test.go`).
7. Migrating v12 to v13 on a Supabase-like database leaves `fb_comments` with RLS on and no `anon`/`authenticated` access, and its checks refuse a duplicate comment ID and an unknown status (`knowledge/postgres_test.go`).
8. Logs carry account and comment IDs only: never comment text, names, drafts or tokens.
9. The shadow reviewer never sends, and a reviewer failure leaves the comment untouched (`review_test.go`).
   - Each decision rule holds on its own, and the code rules hold links, numbers, prices and percentages (`review_test.go`).
   - The Jev request matches TypeSafe's documented shape (state, model, `questions` with one `choice` and four `noul`), and its errors never contain the key (`review_test.go`).
10. `go run ./cmd/comment-eval -llm <models>` runs the 43 labelled mock cases (`testdata/comment-eval/`). The mock set is checked for consistency (`cmd/comment-eval/main_test.go`).

## Phase 2: going live (owner + Meta, after this merges)

1. **Meta app** (owner, via the prompt in the session handoff):
   - a separate Business app with Webhooks and Messenger;
   - Business Verification;
   - privacy policy and data deletion URLs;
   - app roles.
2. **Public route** for `POST/GET /webhooks/meta` only, the way `/webhooks/chatwoot` is routed: Traefik path rule on the production domain, or a tunnel route with an Access bypass. `/admin` stays behind Access.
3. **Dokploy env**:
   - `META_APP_SECRET`, `META_VERIFY_TOKEN` (random, ≥16 characters), `META_PAGE_ID`, `META_ACCOUNT_ID`;
   - later `META_PAGE_TOKEN`, from a system user with the MESSAGING task.
   - Entered through the secret box, never chat.
4. **Release**:
   - backup;
   - deploy, which applies v13 on start;
   - check the required tables, then health.
   - **Rebuild and reinstall `/opt/aisvc-backup/restore-check`** from the deployed commit: it now requires `fb_comments` and schema 13. A stale binary fails the nightly drill.
5. **Subscribe**:
   - Meta webhook: Page object, `feed` field, the callback URL and the verify token;
   - `POST /{page-id}/subscribed_apps?subscribed_fields=feed`.
6. **Test** in development mode with app-role users:
   - comment → shows on `/admin/comments` → Send → private reply arrives in Messenger → their reply lands in Chatwoot.
   - Record the screencast for App Review.
7. **App Review** for `pages_messaging`, `pages_manage_metadata`, `pages_show_list`, `pages_read_engagement` and `pages_read_user_content`, then switch the app to Live.

## Reviewer benchmark (mock data)

2026-11-10, 43 hand-labelled mock cases for a fictional business, in Thai, English and Lao. 19 should be sent; 24 should be held (complaints, other, invented offers, off-topic, prompt injection, links and numbers, rude tone). Models were called on OpenAI directly. Prices come from OpenRouter's public model list.

| Reviewer | Decision accuracy | False sends | Missed sends | p50 | $ / 1000 comments |
|---|---|---|---|---|---|
| gpt-5.6-luna | 98%, 98%, 100% | 0, 0, 0 | 1, 1, 0 | 2.7 s | 0.35 |
| gpt-5.6-terra | 100%, 100%, 100% | 0, 0, 0 | 0, 0, 0 | 1.6 s | 2.1–2.2 |
| gpt-5.6-sol | 98%, 100%, 100% | **1** (o05), 0, 0 | 0, 0, 0 | 2.6 s | 5.1–5.4 |

- Each figure in a cell is one run; the models are not deterministic. The third run followed the security fixes: wider code rules, and normalised Jev probabilities. In that run Terra returned one malformed answer, which counts as held.
- Earlier runs found two rule defects, both fixed before the runs above:
  - an intent split between lead and question was treated as doubt;
  - a negatively phrased manipulation check, which Luna answered with the polarity reversed, held 6 good drafts.
- **Jev (jev-1.14.0), measured 2026-11-10 on the same 43 cases, with the same questions and thresholds:**

  | | Decision accuracy | False sends | Missed sends | Intent accuracy | p50 | $ / 1000 |
  |---|---|---|---|---|---|---|
  | Jev | 81% | 0 | 8 | **98%** | **0.26 s** | **0.035** |

  - Jev was the fastest (about 10× faster than the LLMs), the cheapest (about 10× below Luna and 60× below Terra) and read intent best. It made no false sends.
  - It held 8 good drafts. Seven fell on `no_unbacked_offer`, where its calibrated probabilities sit around 0.8–0.9 for good drafts, below the 0.90 bar the LLMs clear. Good and bad drafts barely separate on that question (median 0.91 against 0.86).
  - Experiment, reverted: splitting that check into two atomic questions ("offers nothing extra" and "facts supported by the profile"), as TypeSafe advises, made every reviewer worse. Jev fell to 70%, Luna to 93% and Terra to 98%. The "facts supported" question holds ordinary lines such as "the admin will send details in chat".
  - The thresholds were **not** tuned to make Jev pass: 43 mock cases are too few. Jev's thresholds should be set from shadow results on real comments.

- **Jev optimisation, 2026-11-10.** Three changes, all following TypeSafe's docs:
  1. Each yes/no check now sends `criteria` describing what a yes and a no mean (`checkCriteria` in `reviewers.go`). The LLM prompt is unchanged.
  2. Thresholds are set per reviewer (`Thresholds`, `LLMThresholds`, `JevThresholds`). Calibrated probabilities sit lower than chat models' on good drafts.
  3. The data grew to 85 cases. 42 new ones are harder: true facts from the profile against invented certificates, coaching, deadlines, free shipping, misleading answers and more injection styles.

  Tuning was honest: `-tune` splits the cases into two halves balanced by label, tunes on one half (no false sends allowed) and reports on the other. `-swap` repeats the run the other way round.

  | Held-out half | Jev, no criteria | Jev + criteria, default bars | Jev + criteria, tuned | Luna, default | Luna, tuned | Terra |
  |---|---|---|---|---|---|---|
  | A (42) | 76% / 0 false | 95% / 0 | **100% / 0** | 95% / 0 | 98% / 0 | 98% / **1 false (s07)** |
  | B (43) | — | 91% / 0 | **95% / 0** | 95% / 0 | 98% / 0 | — |

  - Tuning lowered only Jev's offer bar: to 0.60 on one half and 0.75 on the other. `JevThresholds` uses 0.75, the safer value, and keeps every other bar.
  - Final run on all 85 cases with the shipped settings: **Jev 96%, 0 false sends, 0.26 s, $0.047 per 1000 comments; Luna 94%, 0 false sends, 2.6 s, $0.35.** This run includes the cases the thresholds were tuned on, so the held-out figures above are the fairer measure.
  - Criteria add about 300 input tokens per review (about 1120 in total), which is still about 7.5× cheaper than Luna.
- Mock cases are not real comments. The decision to auto-send must rest on the shadow agreement numbers from real comments.

## Reviews

- 2026-11-10: `ai-service-migration-reviewer` gave **changes required**.
  - Fixed: a refused row blocked the whole delivery; unreadable comments stalled scoring (added the `attempts` column); no tests at the length limits; no restore-check note in `deploy/README.md`.
  - Account scoping (one Page per service) is documented as an accepted risk above.
- 2026-11-10: `ai-service-security-reviewer` gave **changes required**. Fixed:
  - deleted comments coming back (now kept as `removed`);
  - a refused row blocking delivery;
  - the commenter's name as an injection point, and drafts not labelled as AI suggestions;
  - the waiting list had no cap;
  - log floods from unsigned requests;
  - full URLs in errors;
  - a misleading message after a send that wasn't recorded;
  - the form had no size cap.

  The verify token in access logs is documented as an accepted risk above.

- 2026-11-10: `ai-service-security-reviewer` reviewed the shadow reviewer (`d948a5ab17..84918e83ec`) and gave **changes required**. It found no path from a review to a send. Fixed:
  - Jev error bodies, which might quote comment text, are dropped from errors;
  - the code rules now catch Thai and full-width digits, any `name.tld` link and spelled-out links;
  - the stored model name is capped;
  - Jev intent probabilities are normalised, and a choice that is not the most likely intent is rejected;
  - the benchmark refuses to send keys over plain http.

  Injection reaching the scores and the TypeSafe data flow are documented as accepted risks above.

## Evidence

- 2026-11-10, local:
  - `gofmt -l .` clean, `go vet ./...` clean, `go test -race ./...` all pass.
  - The full suite passes against a throwaway local `pgvector/pgvector:pg17` container (`go test -p 1 ./...` with `TEST_DATABASE_URL`).
  - After the review fixes, both runs pass again, and govulncheck finds no vulnerabilities.
  - Live local run (branch binary, scratch DB at schema v13). Five signed `feed` deliveries to `/webhooks/meta` each got 200 and stored 4 rows: the Page's own comment was skipped. An unsigned POST got 401.
  - `/admin/comments` renders at 1280 px and 390 px (Chrome device emulation). The owner review page holds the before/after screenshots.
