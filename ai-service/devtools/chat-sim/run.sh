#!/bin/sh
# Serve the chat simulator for the local Chatwoot (see README.md).
# Usage: devtools/chat-sim/run.sh [inbox name]   (default "Messenger test")
set -eu
cd "$(dirname "$0")"
NAME="${1:-Messenger test}"
PG="${PG_CONTAINER:-chatwoot-local-postgres-1}"
ID=$(docker exec "$PG" psql -U postgres -d chatwoot_production -Atc \
  "select c.identifier from inboxes i join channel_api c on c.id = i.channel_id
   where i.channel_type = 'Channel::Api' and i.name = '$(printf %s "$NAME" | sed "s/'/''/g")' limit 1")
if [ -z "$ID" ]; then
  echo "No API inbox named \"$NAME\" in local Chatwoot. Create one first (README.md)." >&2
  exit 1
fi
PORT="${PORT:-8099}"
# config.js is local only (gitignored): the page reads the inbox from it.
printf 'window.CHATSIM = { inbox: "%s" };\n' "$ID" > config.js
echo "Chat simulator: http://127.0.0.1:$PORT/"
exec python3 -m http.server "$PORT" --bind 127.0.0.1
