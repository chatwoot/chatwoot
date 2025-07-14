This is June's JS SDK, based on Analytics-Next by Segment.

# Getting Started

- `make dev` should start a development server after a `yarn install`.
- The writeKey is a valid June API key. You can make one in interim by going into the database (`api_keys` table) and inserting a new row.

# Components

- Tester (`example`): NextJS app used to generate and emit mock events to a test or production event ingress.
- Analytics.js (`src`): Analytics library source for both brower, NodeJS

# Understanding Analytics-Next

To start understanding this codebase, you need to look at a couple crucial folders within `src`:

- `plugins`: analytics-next is implemented in a modular fashion, so there’s many plugins that perform separate functions.
  - To be honest, the most important plugins are `segmentio` and `analytics-node`.
  - The `segmentio` plugin practically handles event sending for browser clients.
  - The `analytics-node` plugin handles event sending for Node clients.
  - These plugins are both enabled in the entrypoint for the library, although e.g. configuration settings to both don’t necessarily get passed down to them raw.

# Testing Locally

## The Easy Way (Tester App)

The tester app provides a convenient way to test out small changes to the Analytics-Next codebase, reloading your changes on the fly.

To use the tester app, configure `sdk/example/config.js` and change whether to use the local or remote API.

The SDK tester app is ran automatically by Docker Compose. You should be able to visit at `localhost:3002`.

The local remote for Analytics-Node is different, as the tester is proxied via Docker. See the configuration file for more information.

## Standalone Build

To change API endpoints for the standalone build, a full rebuild must be issued with the endpoint changes. There’s currently no mechanism to change apiHost on the fly (although, considering it uses the same code as the NPM build, this shouldn’t be tested separately anyways).

## Browser (React, NPM)

To test the browser build, pass the `apiHost` parameter when instantiating. An example:

```jsx
// Import June SDK:
import { AnalyticsBrowser } from '@june-so/analytics-next'

// Near the entrypoint of your app, instantiate AnalyticsBrowser:
let [analytics] = await AnalyticsBrowser.load({
  writeKey: 'MY-API-KEY',
  apiHost: 'http://localhost:3001',
})
```

## Node (NPM)

To test the Node build, pass the `apiHost` and `httpScheme` parameter when instantiating. An example:

```jsx
// Import June SDK:
import { AnalyticsNode } from '@june-so/analytics-next'

// Instantiate AnalyticsNode:
const [nodeAnalytics] = await AnalyticsNode.load({
  writeKey: 'MY-KEY',
  httpScheme: 'http',
  apiHost: 'localhost:3001/sdk',
})
```

# Building & Publishing

- The build process emits a couple of files, useful for production:
  - The build file used in the browser script is `dist/umd/standalone.js`. With some additional code (slightly cloned) from the official Segment documentation, we can easily activate this in the client using a snippet:
    ```jsx
    <script>
        window.analytics = {};
        function juneify(writeKey) {
            window.analytics._writeKey = writeKey;
            var script = document.createElement("script");
            script.type = "application/javascript";
            script.onload = function () {
                window.analytics.page();
            }
            script.src = "https://unpkg.com/@june-so/analytics-next/dist/umd/standalone.js";
            var first = document.getElementsByTagName('script')[0];
            first.parentNode.insertBefore(script, first);
        }
        juneify("API_KEY");
    </script>
    ```
  - Then there’s the NPM package, alongside any custom scripts.
    - `scripts/sdk_release` should publish the package to NPM.
    - You’ll need publish credentials (see https://github.com/juneHQ/june/issues/2837)

# Annotated Source

The core event emission code is distributed between two plugins: `segmentio` and `analytics-node`. Here are some documented changes that make `analytics-next` send events to June:

## segmentio/fetch-dispatcher.ts

```jsx
function dispatch(url: string, body: object): Promise<unknown> {
  return fetch(url, {
    headers: { 'Content-Type': 'application/json' }, // <----
    method: 'post',
    body: JSON.stringify(body),
  })
}
```

An important change from vanilla is the changing of content-type: the original Analytics-Next sends events in plaintext by default. Instead, vanilla code will silently error out.

## segmentio/batched-dispatcher.ts

```jsx
export default function batch(apiHost: string, config?: BatchingConfig) {
...
}
```

Some changes to note in the batched dispatcher include `application/json` content types, alongside a crucial bit: changing the `apiHost` from a hardcoded Segment API link to June’s endpoint (around L65 and some repetitions in the file).

We’ve never seen this dispatcher used, but keep it updated for compatibility purposes. The next file is the most important for browser usage.

## segmentio/index.ts

This plugin defines all visible behavior of the browser integration. This is where the critical bits lie: there are custom type definitions for June’s SDK settings (most notably the addition of an apiHost parameter not present in vanilla).

```jsx
export function segmentio(
  analytics: Analytics,
  settings?: SegmentioSettings,
  integrations?: LegacySettings['integrations']
): Plugin {
  const buffer = new PersistedPriorityQueue(
    analytics.queue.queue.maxAttempts,
    `dest-Segment.io`
  )
  const flushing = false

  const apiHost = settings?.apiHost ?? 'api.june.so/sdk'
  const remote = apiHost.includes('localhost')
    ? `http://${apiHost}`
    : `https://${apiHost}`

  const client =
    settings?.deliveryStrategy?.strategy === 'batching'
      ? batch(apiHost, settings?.deliveryStrategy?.config)
      : standard()

  async function send(ctx: Context): Promise<Context> {
    if (isOffline()) {
      buffer.push(ctx)
      // eslint-disable-next-line @typescript-eslint/no-use-before-define
      scheduleFlush(flushing, buffer, segmentio, scheduleFlush)
      return ctx
    }

    const path = ctx.event.type //.charAt(0)
    let json = toFacade(ctx.event).json()

    if (ctx.event.type === 'track') {
      delete json.traits
    }

    if (ctx.event.type === 'alias') {
      json = onAlias(analytics, json)
    }

    return client
      .dispatch(
        `${remote}/${path}`,
        normalize(analytics, json, settings, integrations)
      )
      .then(() => ctx)
      .catch((err) => {
        if (err.type === 'error' || err.message === 'Failed to fetch') {
          buffer.push(ctx)
          // eslint-disable-next-line @typescript-eslint/no-use-before-define
          scheduleFlush(flushing, buffer, segmentio, scheduleFlush)
        }
        return ctx
      })
  }

  const segmentio: Plugin = {
    name: 'Segment.io',
    type: 'after',
    version: '0.1.0',
    isLoaded: (): boolean => true,
    load: (): Promise<void> => Promise.resolve(),
    track: send,
    identify: send,
    page: send,
    alias: send,
    group: send,
  }

  return segmentio
}
```

Aside from configuration changes, the most important line that enables sending to our SDK endpoints is the following:

```jsx
const apiHost = settings?.apiHost ?? 'api.june.so/sdk'
const remote = apiHost.includes('localhost')
  ? `http://${apiHost}`
  : `https://${apiHost}`
```

When passing in settings and initializing the SDK, you can pass an apiHost to test locally. This also works with the tester app.

## analytics-node/index.ts

Most changes to this SDK are almost identical to the browser changes (content-type, etc).

The Node SDK has some modifications in the type signature for configuration parameters: most notably (and usefully), you can pass in an apiHost and httpScheme. This allows for local testing.

## standalone.ts & standalone-analytics.ts

These files contain the code that gets run for the Standalone build (that is, the script tag we provide for easy installs).

The most important thing to make sure when loading the browser script is to initialize [`window.analytics`](http://window.analytics) to an empty object and then set `window.analytics._writeKey` with the API key.

## analytics.ts

This file contains the API surface for the analytics package, which is standard (the only thing that changes is the underlying dispatcher).

## analytics-node.ts & browser.ts

This file contains the modules imported when the NPM package is installed. There’s some modified type signatures, in particular to make sure passing an `httpScheme` and `apiHost` is allowed.
