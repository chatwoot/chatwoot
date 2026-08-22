FROM node:20-alpine

# Create app directory
WORKDIR /app

# Install app dependencies (leverage Docker layer cache when package.json is unchanged)
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

# Bundle app source
COPY . .

# Auth state (creds + Signal keys) MUST persist on a volume mounted at /app/auth
# so WhatsApp sessions survive container restarts without re-scanning the QR.
# Media forwarded to Chatwoot is served from /app/media (also volume-backed).
VOLUME ["/app/auth", "/app/media"]

ENV AUTH_DIR=/app/auth \
    MEDIA_DIR=/app/media \
    PORT=4000

EXPOSE 4000

# restart: always on the compose side keeps this process alive; Baileys also
# auto-reconnects from persisted state on crash.
CMD ["node", "src/index.js"]
