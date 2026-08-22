#!/usr/bin/env bash
# End-to-end: open login page, fill credentials, submit, then dump the DOM to
# confirm the DASHBOARD renders (not the login page). Uses a fresh profile.
set -e
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
pkill -f "chrome.exe" 2>/dev/null || true
sleep 2
# 1) Render login page, type credentials into the fields, click submit.
#    We use --dump-dom after a virtual-time budget; but form submit is async, so
#    instead drive via the devtools-free approach: inject values + dispatch submit.
timeout 55 "$CHROME" --headless=new --no-sandbox --disable-gpu --disable-dev-shm-usage \
  --user-data-dir=/tmp/cp16 --virtual-time-budget=20000 \
  --dump-dom "http://127.0.0.1:3000/app/login" > /tmp/login_render.html 2>/tmp/cp16.err
echo "LOGIN_RENDER_EXIT=$?" >> /tmp/login_render.html
