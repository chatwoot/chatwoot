#!/usr/bin/env python3
"""Check a Pronto knowledge-base sheet (CSV or JSON Lines) before it is synced.

Runs the general checks in check_dataset.py with Pronto's importer rules
(internal/feed/feed.go): Thai column names, the id column, id and title
limits, 500 rows per source. Then adds what testing the AutoCut bot taught us
(see ../references/lessons.md):

- a promotion that gives its end date but not the price after it;
- links to a site's home page instead of the exact page;
- Thai mobile numbers (a link-shared sheet is public);
- rows that instruct the bot (those belong in the business profile rules).

It also lists every link with the row ids that use it, so the owner can see
that the buy link is the same everywhere.

Usage: pronto_check.py FILE [FILE ...] [--today YYYY-MM-DD] [--json]
Errors make the exit code 1; warnings do not. Standard library only.
"""
import argparse
import csv
import datetime as dt
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_dataset as base  # noqa: E402

# Keep in step with internal/feed/feed.go (thaiColumns, MaxRows, MaxIDRunes,
# maxTitleRunes). The importer also reads "description" and "name".
THAI_COLUMNS = {
    "รหัส": "id", "ไอดี": "id",
    "คำถาม": "question", "คำตอบ": "answer",
    "ชื่อเรื่อง": "title", "หัวเรื่อง": "title",
    "เนื้อหา": "content", "ข้อความ": "content", "รายละเอียด": "content", "description": "content",
    "หมวด": "category", "หมวดหมู่": "category",
    "หัวข้อ": "section", "หัวข้อย่อย": "section",
    "วันเริ่ม": "start_date", "วันที่เริ่ม": "start_date",
    "วันสุดท้าย": "last_day", "วันหมดอายุ": "last_day",
}
MAX_ROWS, MAX_ID, MAX_TITLE = 500, 120, 300

URL = re.compile(r"https?://[^\s<>\"'()]+")
# "ถึง 30 พ.ย." / "ถึงวันที่ 30" / "until 30 Nov": a stated end of an offer.
PROMO_END = re.compile(r"(ถึง(วันที่)?\s*\d{1,2}\s*[ก-๙]|until\s+\d{1,2}\s+[A-Za-z]|หมดเขต|หมดโปร)", re.I)
PRICE = re.compile(r"\d[\d,]*\s*(บาท|฿|baht|THB)", re.I)
AFTER = re.compile(r"(ตั้งแต่|หลังจาก|หลังหมด|from\s+\d|after\s+\d)", re.I)
MOBILE = re.compile(r"(?<!\d)0[689]\d[-\s]?\d{3}[-\s]?\d{4}(?!\d)")
BOT_RULE = re.compile(r"(บอท|ห้ามบอก|ห้ามสัญญา|ห้ามเสนอ|\bthe bot\b)", re.I)


def norm_key(k):
    k = (k or "").strip().lstrip("﻿")
    return THAI_COLUMNS.get(k, base.ALIASES.get(k.lower(), k.lower()))


def row_text(r):
    return " ".join(v for k, v in r.items() if k in ("question", "answer", "title", "content"))


# Read headers the way the importer does, in the base checks too.
base.norm_key = norm_key


def check_file(path, today):
    res = base.check(path, today, MAX_ROWS, {})
    rows = base.read_rows(path)
    errors, warnings, links, bot_rows = res["errors"], res["warnings"], {}, []
    if rows and not any(r and "id" in r for _, r, _ in rows):
        errors.append({"line": 0, "message": "no id column; the importer refuses the whole file"})
    for line, r, problem in rows:
        if problem or not r:
            continue
        rid = " ".join(r.get("id", "").split()).replace(" ", "-")
        text = row_text(r)
        if len(rid) > MAX_ID:
            errors.append({"line": line, "message": f"id longer than {MAX_ID} characters; the importer skips the row"})
        title = r.get("title", "") or r.get("question", "")
        if len(title.strip()) > MAX_TITLE:
            warnings.append({"line": line, "message": f"title is cut at {MAX_TITLE} characters"})
        if PROMO_END.search(text) and PRICE.search(text) and not AFTER.search(text):
            warnings.append({"line": line, "message": "gives an end date but not the price after the promotion; "
                                                      "add 'ตั้งแต่ <date> ราคา ...' so the bot can answer on both sides"})
        for url in URL.findall(text):
            url = url.rstrip(".,;:")
            links.setdefault(url, []).append(rid)
            path_part = url.split("://", 1)[1].partition("/")[2]
            if path_part.strip("/") == "":
                warnings.append({"line": line, "message": f"links a home page ({url}); name the exact page "
                                                          "(course page, examples page), or the bot may send it as a buy link"})
        if MOBILE.search(text):
            warnings.append({"line": line, "message": "has a mobile number; a link-shared sheet is public, "
                                                      "keep staff numbers out of it unless the owner wants them published"})
        if BOT_RULE.search(text):
            bot_rows.append(rid or f"line {line}")
    if bot_rows:
        warnings.append({"line": 0, "message": f"{len(bot_rows)} rows instruct the bot ({', '.join(bot_rows[:15])}"
                                               f"{', ...' if len(bot_rows) > 15 else ''}); behaviour rules work best "
                                               "in the business profile rules, facts in the sheet"})
    res["warnings"] = sorted(warnings, key=lambda x: x["line"])
    res["links"] = links
    return res


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("files", nargs="+", metavar="FILE")
    p.add_argument("--today", default=dt.date.today().isoformat())
    p.add_argument("--json", action="store_true")
    a = p.parse_args()
    today = base.parse_day(a.today)
    if not today:
        p.error("--today must be YYYY-MM-DD")
    results = []
    for f in a.files:
        try:
            results.append(check_file(f, today))
        except (OSError, UnicodeDecodeError, csv.Error) as e:
            print(f"cannot read {f}: {e}", file=sys.stderr)
            return 2
    cross = base.across(results) if len(results) > 1 else []
    for r in results:
        r.pop("_ids", None), r.pop("_heads", None)
    if a.json:
        print(json.dumps({"files": results, "across_files": cross}, ensure_ascii=False, indent=2))
    else:
        for res in results:
            print(f"{res['file']}: {res['rows']} rows ({res['faqs']} FAQs, {res['documents']} documents, "
                  f"{res['with_last_day']} with last_day)")
            for kind in ("errors", "warnings"):
                print(f"{len(res[kind])} {kind}")
                for x in res[kind]:
                    print(f"  {'line ' + str(x['line']) if x['line'] else 'file'}: {x['message']}")
            print(f"links ({len(res['links'])}):")
            for url, ids in sorted(res["links"].items()):
                print(f"  {url}  <- {', '.join(ids[:8])}{', ...' if len(ids) > 8 else ''} ({len(ids)} rows)")
        if cross:
            print(f"across files: {len(cross)} warnings")
            for x in cross:
                print(f"  {x['message']}")
    return 1 if any(r["errors"] for r in results) else 0


if __name__ == "__main__":
    sys.exit(main())
