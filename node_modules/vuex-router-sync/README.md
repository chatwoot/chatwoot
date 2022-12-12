# vuex-router-sync

> Effortlessly keep vue-router and vuex store in sync.

### Usage

``` bash
# the latest version works only with vue-router >= 2.0
npm install vuex-router-sync

# for usage with vue-router < 2.0:
npm install vuex-router-sync@2
```

``` js
import { sync } from 'vuex-router-sync'
import store from './vuex/store' // vuex store instance
import router from './router' // vue-router instance

sync(store, router) // done.

// bootstrap your app...
```

You can set a custom vuex module name

```js
sync(store, router, { moduleName: 'RouteModule' } )
```


### How does it work?

- It adds a `route` module into the store, which contains the state representing the current route:

  ``` js
  store.state.route.path   // current path (string)
  store.state.route.params // current params (object)
  store.state.route.query  // current query (object)
  ```

- When the router navigates to a new route, the store's state is updated.

- **`store.state.route` is immutable, because it is derived state from the URL, which is the source of truth**. You should not attempt to trigger navigations by mutating the route object. Instead, just call `$router.push()` or `$router.go()`. Note that you can do `$router.push({ query: {...}})` to update the query string on the current path.

### License

[MIT](http://opensource.org/licenses/MIT)
