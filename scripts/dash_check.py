#!/usr/bin/env python3
"""Generate a static harness HTML that reuses the live Rails-injected config
but loads the production-built bundle (no HMR websocket) so headless Chrome
can fire `load` and we can verify the Vue app actually mounts."""
import re
import sys
import urllib.request

LIVE = "http://127.0.0.1:3000/"
BUILT_JS = "/vite-dev/assets/dashboard-BvmrM_DZ.js"
BUILT_CSS = "/vite-dev/assets/dashboard-BvliAOzu.css"

html = urllib.request.urlopen(LIVE, timeout=20).read().decode("utf-8")

# Drop the Vite HMR client (the websocket that keeps `load` from firing in headless)
html = re.sub(r'<script src="/vite-dev/@vite/client"[^>]*></script>', "", html)

# Replace the dev entry module with the built bundle + inject the built CSS
html = re.sub(
    r'<script src="/vite-dev/entrypoints/dashboard.js"[^>]*></script>',
    f'<link rel="stylesheet" href="{BUILT_CSS}">\n'
    f'  <script type="module" src="{BUILT_JS}"></script>',
    html,
)

# Stub only WebSocket so the headless page settles (no /cable reconnect loop).
# Let /api calls run naturally; the app tolerates auth failures.
stub = """<script>
  window.WebSocket = function(){ this.close=function(){}; this.send=function(){}; };
  window.WebSocket.prototype = {};
</script>"""
html = html.replace("</head>", stub + "</head>", 1)

out = sys.argv[1] if len(sys.argv) > 1 else "public/dash-check.html"
with open(out, "w", encoding="utf-8") as f:
    f.write(html)
print(f"wrote {out} ({len(html)} bytes)")
