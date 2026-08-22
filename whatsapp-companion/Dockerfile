# syntax=docker/dockerfile:1.6
FROM node:20-alpine

# Create app directory
WORKDIR /app

RUN apk add --no-cache git

# Install app dependencies (leverage Docker layer cache when package.json is unchanged)
# BuildKit cache mount on npm's download cache: re-running after a lockfile change
# reuses already-fetched tarballs instead of re-downloading from the registry.
COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm,id=whatsapp-npm npm ci --omit=dev

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
