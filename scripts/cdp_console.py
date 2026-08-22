#!/usr/bin/env python3
"""Capture browser console messages while loading localhost:3000/ logged-out,
to confirm the "Invalid navigation guard" / "No match found" warnings are gone."""
import base64
import json
import os
import socket
import struct
import subprocess
import time
import urllib.request
from urllib.parse import urlparse

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
PORT = 9344
URL = "http://127.0.0.1:3000/"


def ws_connect(host, port, path):
    s = socket.create_connection((host, port), timeout=30)
    key = base64.b64encode(os.urandom(16)).decode()
    req = (f"GET {path} HTTP/1.1\r\nHost: {host}:{port}\r\n"
           f"Upgrade: websocket\r\nConnection: Upgrade\r\n"
           f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n")
    s.sendall(req.encode())
    buf = b""
    while b"\r\n\r\n" not in buf:
        buf += s.recv(4096)
    return s


def ws_send(s, payload):
    data = json.dumps(payload).encode()
    n = len(data)
    mask = os.urandom(4)
    masked = bytes(b ^ mask[i % 4] for i, b in enumerate(data))
    if n < 126:
        header = bytes([0x81, 0x80 | n])
    elif n < 65536:
        header = bytes([0x81, 0xFE]) + struct.pack(">H", n)
    else:
        header = bytes([0x81, 0xFF]) + struct.pack(">Q", n)
    s.sendall(header + mask + masked)


def ws_recv(s):
    time.sleep(0.05)
    s.settimeout(2.0)
    try:
        b1 = s.recv(1); b2 = s.recv(1)
    except Exception:
        return None
    if not b1 or not b2:
        return None
    length = b2[0] & 0x7F
    if length == 126:
        length = struct.unpack(">H", s.recv(2))[0]
    elif length == 127:
        length = struct.unpack(">Q", s.recv(8))[0]
    data = b""
    while len(data) < length:
        data += s.recv(length - len(data))
    return json.loads(data.decode())


def main():
    proc = subprocess.Popen([CHROME, "--headless=new", "--no-sandbox", "--disable-gpu",
                             "--disable-dev-shm-usage", f"--remote-debugging-port={PORT}",
                             "--user-data-dir=/tmp/cdp_console"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    msgs = []
    try:
        time.sleep(4)
        targets = json.loads(urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json", timeout=10).read().decode())
        page = next(t for t in targets if t.get("type") == "page")
        p = urlparse(page["webSocketDebuggerUrl"])
        s = ws_connect("127.0.0.1", p.port, p.path)
        _id = [0]

        def cmd(method, params=None):
            _id[0] += 1
            ws_send(s, {"id": _id[0], "method": method, "params": params or {}})

        cmd("Runtime.enable")
        cmd("Log.enable")
        cmd("Page.enable")
        cmd("Page.navigate", {"url": URL})
        end = time.time() + 15
        while time.time() < end:
            r = ws_recv(s)
            if not r:
                continue
            if r.get("method") == "Runtime.consoleAPICalled":
                msgs.append(("console", r["params"].get("type"),
                             " ".join(str(a.get("value", "")) for a in r["params"].get("args", []))))
            elif r.get("method") == "Log.entryAdded":
                e = r["params"]
                msgs.append(("log", e.get("level"), e.get("text", "")))
        interesting = [m for m in msgs if any(k in str(m[2]) for k in
                       ["Invalid navigation guard", "No match found", "uncaught error", "next", "Vue Router"])]
        print("=== total console/log msgs:", len(msgs))
        print("=== router-related msgs:", len(interesting))
        for m in interesting[:20]:
            print(m)
        if not interesting:
            print("NO router navigation warnings captured.")
    finally:
        proc.terminate()


if __name__ == "__main__":
    main()
