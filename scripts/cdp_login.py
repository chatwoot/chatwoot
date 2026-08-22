#!/usr/bin/env python3
"""Minimal Chrome DevTools Protocol client (stdlib only, raw WebSocket over a
socket). Drives the real login flow and prints the rendered #app innerHTML so we
can confirm the DASHBOARD mounts after authentication."""
import base64
import json
import os
import socket
import struct
import subprocess
import sys
import time
import urllib.request

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
PORT = 9333
URL = "http://127.0.0.1:3000/app/login"
EMAIL = "john@acme.inc"
PASSWORD = "Testpass123!"


def ws_connect(host, port, path):
    s = socket.create_connection((host, port), timeout=30)
    key = base64.b64encode(os.urandom(16)).decode()
    req = (
        f"GET {path} HTTP/1.1\r\nHost: {host}:{port}\r\n"
        f"Upgrade: websocket\r\nConnection: Upgrade\r\n"
        f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
    )
    s.sendall(req.encode())
    # read handshake response
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
    # minimal frame parser (assumes single frame, no masking from server)
    time.sleep(0.05)
    s.settimeout(2.0)
    try:
        b1 = s.recv(1)
        b2 = s.recv(1)
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
    proc = subprocess.Popen(
        [CHROME, "--headless=new", "--no-sandbox", "--disable-gpu",
         "--disable-dev-shm-usage", f"--remote-debugging-port={PORT}",
         f"--user-data-dir=/tmp/cdp_prof"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    try:
        time.sleep(4)
        # get a page target websocket
        targets = json.loads(urllib.request.urlopen(
            f"http://127.0.0.1:{PORT}/json", timeout=10).read().decode())
        page = next(t for t in targets if t.get("type") == "page")
        ws_url = page["webSocketDebuggerUrl"]
        from urllib.parse import urlparse
        p = urlparse(ws_url)
        s = ws_connect("127.0.0.1", p.port, p.path)
        _id = [0]

        def cmd(method, params=None):
            _id[0] += 1
            ws_send(s, {"id": _id[0], "method": method, "params": params or {}})
            return _id[0]

        def wait_result(wid, timeout=20):
            end = time.time() + timeout
            while time.time() < end:
                r = ws_recv(s)
                if r and r.get("id") == wid:
                    return r
            return None

        cmd("Page.enable")
        cmd("Runtime.enable")
        nav = cmd("Page.navigate", {"url": URL})
        time.sleep(6)  # let Vue mount

        # Type email + password + submit via evaluated JS (sets v-model + clicks)
        expr = (
            "(function(){"
            "  var email=document.querySelector('[data-testid=email_input]');"
            "  var pass=document.querySelector('[data-testid=password_input]');"
            "  function set(el,v){if(!el)return;var d=el.ownerDocument.defaultView;"
            "    var proto=Object.getPrototypeOf(el);"
            "    var setter=Object.getOwnPropertyDescriptor(proto,'value').set;"
            "    setter.call(el,v);el.dispatchEvent(new d.Event('input',{bubbles:true}));"
            "    el.dispatchEvent(new d.Event('change',{bubbles:true}));}"
            "  set(email,'" + EMAIL + "');set(pass,'" + PASSWORD + "');"
            "  var form=document.querySelector('form');"
            "  if(form){form.dispatchEvent(new Event('submit',{bubbles:true,cancelable:true}));}"
            "  return 'submitted';"
            "})()"
        )
        cmd("Runtime.evaluate", {"expression": expr, "returnByValue": True})
        time.sleep(8)  # wait for auth + redirect + dashboard mount

        res = cmd("Runtime.evaluate", {
            "expression": "document.getElementById('app') ? document.getElementById('app').innerHTML.slice(0,1500) : 'NO #app'",
            "returnByValue": True,
        })
        r = wait_result(res)
        out = r.get("result", {}).get("result", {}).get("value", "") if r else "NO_RESULT"
        print("=== DASHBOARD DOM (first 1500) ===")
        print(out)
        print("=== markers ===")
        import re
        print("conversation/inbox/dashboard/Acme markers:",
              len(re.findall(r"conversation|inbox|dashboard|Acme|KIRA|sidebar", out, re.I)))
    finally:
        proc.terminate()


if __name__ == "__main__":
    main()
