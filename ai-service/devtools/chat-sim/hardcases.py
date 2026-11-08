#!/usr/bin/env python3
"""Play scripted customer chats through the local Chatwoot and record what
the bot did.

Each case is a new customer in the local API inbox ("Messenger test"). Steps
send text, quick bursts, files, or act as staff (reply, resolve) through
Chatwoot's own APIs, then wait for the bot to settle. The output JSON holds
every message (private notes included), the conversation status, labels and
custom attributes, for a person to grade.

Local only: reads the inbox identifier and a staff API token from the local
Chatwoot database (docker), never prints them.

    python3 -I hardcases.py cases.json out.json [--only 7,12] [--workers 4]
"""
import argparse
import json
import mimetypes
import os
import subprocess
import sys
import time
import urllib.request
import uuid
from concurrent.futures import ThreadPoolExecutor

CW = os.environ.get("CHATWOOT_URL", "http://localhost:3000")
PG = os.environ.get("PG_CONTAINER", "chatwoot-local-postgres-1")
BOT = os.environ.get("BOT_CONTAINER", "chatwoot-local-ai-service-1")
ACCOUNT = os.environ.get("CHATWOOT_ACCOUNT", "1")
INBOX_NAME = os.environ.get("INBOX_NAME", "Messenger test")


def sql(q):
    return subprocess.check_output(
        ["docker", "exec", PG, "psql", "-U", "postgres", "-d", "chatwoot_production", "-Atc", q]
    ).decode().strip()


INBOX = sql(
    "select c.identifier from inboxes i join channel_api c on c.id = i.channel_id "
    f"where i.channel_type = 'Channel::Api' and i.name = '{INBOX_NAME}' limit 1"
)
TOKEN = sql("select token from access_tokens where owner_type = 'User' order by owner_id limit 1")
PUB = f"{CW}/public/api/v1/inboxes/{INBOX}"
ACC = f"{CW}/api/v1/accounts/{ACCOUNT}"


def http(method, url, body=None, form=None, staff=False):
    headers = {}
    data = None
    if form is not None:
        data, ctype = form
        headers["content-type"] = ctype
    elif body is not None:
        data = json.dumps(body).encode()
        headers["content-type"] = "application/json"
    if staff:
        headers["api_access_token"] = TOKEN
    req = urllib.request.Request(url, method=method, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=60) as r:
        raw = r.read()
    return json.loads(raw) if raw else None


def multipart(paths, text):
    b = uuid.uuid4().hex
    out = []
    if text:
        out.append(f'--{b}\r\nContent-Disposition: form-data; name="content"\r\n\r\n{text}\r\n'.encode())
    for p in paths:
        ctype = mimetypes.guess_type(p)[0] or "application/octet-stream"
        name = os.path.basename(p)
        out.append(
            f'--{b}\r\nContent-Disposition: form-data; name="attachments[]"; filename="{name}"\r\n'
            f"Content-Type: {ctype}\r\n\r\n".encode()
        )
        out.append(open(p, "rb").read() + b"\r\n")
    out.append(f"--{b}--\r\n".encode())
    return b"".join(out), f"multipart/form-data; boundary={b}"


class Chat:
    def __init__(self, name):
        c = http("POST", f"{PUB}/contacts", {"name": name})
        self.source = c["source_id"]
        self.conv = http("POST", f"{PUB}/contacts/{self.source}/conversations", {})["id"]

    def path(self, tail=""):
        return f"{PUB}/contacts/{self.source}/conversations/{self.conv}{tail}"

    def say(self, text):
        http("POST", self.path("/messages"), {"content": text})

    def send_files(self, paths, text=""):
        http("POST", self.path("/messages"), form=multipart(paths, text))

    def staff_say(self, text):
        http("POST", f"{ACC}/conversations/{self.conv}/messages",
             {"content": text, "message_type": "outgoing", "private": False}, staff=True)

    def staff_status(self, status):
        http("POST", f"{ACC}/conversations/{self.conv}/toggle_status", {"status": status}, staff=True)

    def messages(self):
        out = http("GET", f"{ACC}/conversations/{self.conv}/messages", staff=True)
        return sorted(out.get("payload", []), key=lambda m: m["id"])

    def details(self):
        c = http("GET", f"{ACC}/conversations/{self.conv}", staff=True)
        labels = http("GET", f"{ACC}/conversations/{self.conv}/labels", staff=True)
        return {"status": c.get("status"), "attributes": c.get("custom_attributes") or {},
                "labels": (labels or {}).get("payload", [])}

    def settle(self, before, quiet=12, maximum=60):
        """Wait for the bot's first answer after a step (or `maximum` seconds
        of silence, which is the result when staff own the chat), then until
        nothing new arrives for `quiet` seconds."""
        start = last_change = time.time()
        count, answered = before, False
        while time.time() - start < maximum + quiet:
            time.sleep(2)
            msgs = self.messages()
            if len(msgs) != count:
                count, last_change = len(msgs), time.time()
            answered = answered or any(m["message_type"] != 0 for m in msgs[before:])
            if answered and time.time() - last_change >= quiet:
                return
            if not answered and time.time() - start >= maximum:
                return


def restart_bot():
    subprocess.run(["docker", "restart", "-t", "5", BOT], check=True, capture_output=True)
    for _ in range(30):
        try:
            urllib.request.urlopen("http://127.0.0.1:8080/healthz", timeout=2)
            return
        except Exception:
            time.sleep(1)


def run_case(case, media_dir):
    chat = Chat(case.get("customer", f"HC{case['id']} ลูกค้า"))
    for step in case["steps"]:
        before = len(chat.messages())
        kind = next(iter(step))
        val = step[kind]
        if kind == "say":
            chat.say(val)
        elif kind == "burst":
            for t in val:
                chat.say(t)
                time.sleep(step.get("gap", 0.8))
        elif kind == "file":
            chat.send_files([os.path.join(media_dir, f) for f in val.split(",")], step.get("text", ""))
        elif kind == "staff_say":
            chat.staff_say(val)
        elif kind == "staff_status":
            chat.staff_status(val)
        elif kind == "restart_bot":
            restart_bot()
        elif kind == "sleep":
            time.sleep(val)
            continue
        if kind not in ("staff_status",):
            chat.settle(before, quiet=step.get("quiet", 12))
    transcript = []
    for m in chat.messages():
        who = {0: "customer", 1: "page", 2: "activity", 3: "template"}.get(m["message_type"], "?")
        sender = (m.get("sender") or {})
        if who == "page":
            who = "bot" if sender.get("type") == "agent_bot" or m.get("sender_type") == "AgentBot" else "staff"
        transcript.append({
            "who": who + (" (private note)" if m.get("private") else ""),
            "text": m.get("content"),
            "files": [a.get("file_type") for a in m.get("attachments") or []],
        })
    return {"id": case["id"], "title": case["title"], "conversation": chat.conv,
            "expect": case.get("expect", ""), "transcript": transcript, **chat.details()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cases")
    ap.add_argument("out")
    ap.add_argument("--only", default="")
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--media", default=os.path.join(os.path.dirname(os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")), "media"))
    a = ap.parse_args()
    if not INBOX or not TOKEN:
        sys.exit("local Chatwoot inbox or staff token not found")
    cases = json.load(open(a.cases))
    if a.only:
        keep = set(a.only.split(","))
        cases = [c for c in cases if str(c["id"]) in keep]
    solo = [c for c in cases if any("restart_bot" in s for s in c["steps"])]
    pooled = [c for c in cases if c not in solo]
    results = []
    with ThreadPoolExecutor(a.workers) as ex:
        for r in ex.map(lambda c: run_case(c, a.media), pooled):
            results.append(r)
            print(f"done {r['id']}: {r['title']}", flush=True)
    for c in solo:
        results.append(run_case(c, a.media))
        print(f"done {c['id']}: {c['title']}", flush=True)
    results.sort(key=lambda r: (float(str(r["id"]).split("-")[0].rstrip("abcdefgh") or 0), str(r["id"])))
    json.dump(results, open(a.out, "w"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
