<p align="center">
  <a href="https://sentry.io/?utm_source=github&utm_medium=logo" target="_blank">
    <img src="https://sentry-brand.storage.googleapis.com/sentry-wordmark-dark-280x84.png" alt="Sentry" width="280" height="84">
  </a>
</p>

# Official Sentry SDK for Vue.js

## Links

- [Official SDK Docs](https://docs.sentry.io/platforms/javascript/guides/vue/)
- [TypeDoc](http://getsentry.github.io/sentry-javascript/)

## General

This package is a wrapper around `@sentry/browser`, with added functionality related to Vue.js. All methods available in
`@sentry/browser` can be imported from `@sentry/vue`.

To use this SDK, call `Sentry.init(options)` as early in your application as possible.

### Vue 3

```javascript
const app = createApp({
  // ...
});

Sentry.init({
  app,
  dsn: '__PUBLIC_DSN__',
  integrations: [
    // Or omit `router` if you're not using vue-router
    Sentry.browserTracingIntegration({ router }),
  ],
});
```

### Vue 2

```javascript
import Vue from 'vue';
import App from './App';
import router from './router';
import * as Sentry from '@sentry/vue';

Sentry.init({
  Vue: Vue,
  dsn: '__PUBLIC_DSN__',
  integrations: [
    // Or omit `router` if you're not using vue-router
    Sentry.browserTracingIntegration({ router }),
  ],
});

new Vue({
  el: '#app',
  router,
  components: { App },
  template: '<App/>',
});
```
