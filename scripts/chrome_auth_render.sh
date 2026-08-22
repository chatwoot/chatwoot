#!/usr/bin/env bash
# Authenticate, capture cookies, then headless-render localhost:3000/ with the
# session so we can verify the DASHBOARD (not just login) renders.
set -e
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
LOGIN=$(curl -s -i -X POST http://127.0.0.1:3000/auth/sign_in -H "Content-Type: application/json" -d '{"email":"john@acme.inc","password":"Testpass123!"}')
AT=$(printf '%s' "$LOGIN" | grep -i '^access-token:' | awk '{print $2}' | tr -d '\r')
CL=$(printf '%s' "$LOGIN" | grep -i '^client:' | awk '{print $2}' | tr -d '\r')
UID_=$(printf '%s' "$LOGIN" | grep -i '^uid:' | awk '{print $2}' | tr -d '\r')
EXPY=$(printf '%s' "$LOGIN" | grep -i '^expiry:' | awk '{print $2}' | tr -d '\r')
pkill -f "chrome.exe" 2>/dev/null || true
sleep 2
COOKIE="access-token=$AT; client=$CL; uid=$UID_; expiry=$EXPY"
timeout 55 "$CHROME" --headless=new --no-sandbox --disable-gpu --disable-dev-shm-usage \
  --user-data-dir=/tmp/cp15 --virtual-time-budget=15000 \
  --dump-dom "http://127.0.0.1:3000/" > /tmp/dom15.html 2>/tmp/cp15.err
echo "CHROME_EXIT=$?" >> /tmp/dom15.html
