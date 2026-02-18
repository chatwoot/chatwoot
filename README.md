# Chatwoot UI — Local Development

This repo is a fork of [Chatwoot](README.chatwoot.md).

See the original [Chatwoot README](README.chatwoot.md) for full documentation.

## Running UI Locally

### 1. Set environment variables

Copy `.env.example` to `.env` (or set in your shell) and configure the proxy URLs:

```env
VITE_PROXY_SERVER_API_URL=
VITE_RPOXY_SERVER_WS_URL=
```

### 2. Install dependencies

```sh
pnpm install
```

### 3. Start the dev server

```sh
pnpm dev
```

> By default the localhost is expected at `localhost:3036`.
