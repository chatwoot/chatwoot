<p align="center">
  <a href="https://sentry.io" target="_blank" align="center">
    <img src="https://sentry-brand.storage.googleapis.com/sentry-logo-black.png" width="280">
  </a>
  <br />
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
});
```

### Vue 2

```javascript
import Vue from 'vue'
import App from './App'
import router from './router'
import * as Sentry from '@sentry/vue'

Sentry.init({
  Vue: Vue,
  dsn: '__PUBLIC_DSN__',
})

new Vue({
  el: '#app',
  router,
  components: { App },
  template: '<App/>'
})
```
