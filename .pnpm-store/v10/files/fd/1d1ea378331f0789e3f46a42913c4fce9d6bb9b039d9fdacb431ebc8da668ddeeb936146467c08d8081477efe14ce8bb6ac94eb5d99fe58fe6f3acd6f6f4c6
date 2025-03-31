# Vuex Router Sync

[![npm](https://img.shields.io/npm/v/vuex-router-sync/next.svg)](https://npmjs.com/package/vuex-router-sync)
[![ci status](https://github.com/vuejs/vuex-router-sync/workflows/test/badge.svg)](https://github.com/vuejs/vuex-router-sync/actions)
[![coverage](https://codecov.io/gh/vuejs/vuex-router-sync/branch/6.x/graph/badge.svg?token=4KJug3I5do)](https://codecov.io/gh/vuejs/vuex-router-sync)
[![license](https://img.shields.io/npm/l/vuex-router-sync.svg?sanitize=true)](http://opensource.org/licenses/MIT)

---

:fire: **HEADS UP!** You're currently looking at Vuex Router Synx 6 branch which supports Vue 3. If you're looking for Vuex Router Sync 5 for Vue 2 support, [please check out `master` branch](https://github.com/vuejs/vuex-router-sync).

---

Sync Vue Router's current `$route` as part of Vuex store's state.

[中文版本 (Chinese Version)](README.zh-cn.md)

## Usage

``` bash
npm install vuex-router-sync@next
```

``` js
import { sync } from 'vuex-router-sync'
import store from './store' // vuex store instance
import router from './router' // vue-router instance

const unsync = sync(store, router) // done. returns an unsync callback fn

// bootstrap your app...

// during app/Vue teardown (e.g., you only use Vue.js in a portion of your app
// and you navigate away from that portion and want to release/destroy
// Vue components/resources)
unsync() // unsyncs store from router
```

You can optionally set a custom vuex module name:

```js
sync(store, router, { moduleName: 'RouteModule' } )
```

## How does it work?

- It adds a `route` module into the store, which contains the state representing the current route:

  ``` js
  store.state.route.path   // current path (string)
  store.state.route.params // current params (object)
  store.state.route.query  // current query (object)
  ...
  ```

- When the router navigates to a new route, the store's state is updated.

- **`store.state.route` is immutable, because it is derived state from the URL, which is the source of truth**. You should not attempt to trigger navigations by mutating the route object. Instead, just call `$router.push()` or `$router.go()`. Note that you can do `$router.push({ query: {...}})` to update the query string on the current path.

## License

[MIT](http://opensource.org/licenses/MIT)
