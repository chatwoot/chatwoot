# Chatwoot

This repo is a fork of [Chatwoot](README.chatwoot.md).

See the original [Chatwoot README](README.chatwoot.md) for full documentation.

## Running UI Locally

### 1. Create `index.html` in the project root

`pnpm dev` runs Vite in client mode (`BUILD_MODE=client`), which disables the `vite-plugin-ruby` integration. Without that plugin Vite needs a plain `index.html` at the root to know what to serve and which JS entry-point to load. It also replaces the configuration that Rails normally injects into the HTML (e.g. `window.chatwootConfig`). This file is gitignored, so you must create it manually once:

```html
<!doctype html>
<html>
  <head>
    <title>Chatwoot Dev</title>
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1, shrink-to-fit=no, user-scalable=0"
    />
    <meta name="csrf-param" content="authenticity_token" />
    <meta name="csrf-token" content="dev-token" />
    <script>
      window.chatwootConfig = {
        // Chatwoot Config
      };
      window.globalConfig = {
        // Global Config
      };
      window.browserConfig = { browser_name: 'Chrome' };
      window.errorLoggingConfig = '';
    </script>
    <script type="module" src="/@vite/client"></script>
    <script
      type="module"
      src="/app/javascript/entrypoints/dashboard.js"
    ></script>
  </head>

  <body class="text-slate-600">
    <div id="app"></div>
    <noscript id="noscript"
      >This app works best with JavaScript enabled.</noscript
    >
  </body>
</html>
```

### 2. Set environment variables

Copy `.env.example` to `.env` (or set in your shell) and configure the proxy URLs:

```env
VITE_PROXY_SERVER_API_URL=
VITE_RPOXY_SERVER_WS_URL=
```

### 3. Install dependencies

```sh
pnpm install
```

### 4. Start the dev server

```sh
pnpm dev
```

> By default the localhost is expected at `localhost:5173`.
