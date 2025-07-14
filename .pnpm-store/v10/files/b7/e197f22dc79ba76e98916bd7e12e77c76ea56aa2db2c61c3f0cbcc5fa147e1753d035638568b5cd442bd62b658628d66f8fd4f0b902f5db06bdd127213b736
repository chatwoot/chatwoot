# Vuex Router Sync

[![npm](https://img.shields.io/npm/v/vuex-router-sync/next.svg)](https://npmjs.com/package/vuex-router-sync)
[![ci status](https://github.com/vuejs/vuex-router-sync/workflows/test/badge.svg)](https://github.com/vuejs/vuex-router-sync/actions)
[![coverage](https://codecov.io/gh/vuejs/vuex-router-sync/branch/6.x/graph/badge.svg?token=4KJug3I5do)](https://codecov.io/gh/vuejs/vuex-router-sync)
[![license](https://img.shields.io/npm/l/vuex-router-sync.svg?sanitize=true)](http://opensource.org/licenses/MIT)

把 Vue Router 当前的 `$route` 同步为 Vuex 状态的一部分。

[English](README.md)

### 用法

```
# 最新版本需要配合 vue-router 2.0 及以上的版本使用
npm install vuex-router-sync
# 用于版本低于 2.0 的 vue-router
npm install vuex-router-sync@2
```

```javascript
import { sync } from 'vuex-router-sync'
import store from './vuex/store' // vuex store 实例
import router from './router' // vue-router 实例

const unsync = sync(store, router) // 返回值是 unsync 回调方法

// 在这里写你的代码

// 在 Vue 应用销毁时 (比如在仅部分场景使用 Vue 的应用中跳出该场景且希望销毁 Vue 的组件/资源时）
unsync() // 取消 store 和 router 中间的同步
```

你可以有选择地设定一个自定义的 vuex 模块名：

```javascript
sync(store, router, { moduleName: 'RouteModule' } )
```

### 工作原理

- 该库在 store 上增加了一个名为 `route` 的模块，用于表示当前路由的状态。

  ```javascript
  store.state.route.path   // current path (字符串类型)
  store.state.route.params // current params (对象类型)
  store.state.route.query  // current query (对象类型)
  ```

- 当被导航到一个新路由时，store 的状态会被更新。

- **`store.state.route` 是不可变更的，因为该值取自 URL，是真实的来源**。你不应该通过修改该值去触发浏览器的导航行为。取而代之的是调用 `$router.push()` 或者 `$router.go()`。另外，你可以通过 `$router.push({ query: {...}})` 来更新当前路径的查询字符串。
