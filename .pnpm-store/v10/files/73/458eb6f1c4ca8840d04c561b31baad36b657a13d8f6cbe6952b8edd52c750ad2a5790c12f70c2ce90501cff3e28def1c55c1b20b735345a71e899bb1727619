/*!
 /**
  * vuex-router-sync v6.0.0-rc.1
  * (c) 2021 Evan You
  * @license MIT
  */
var VuexRouterSync=function(t){"use strict";function e(t,u){var r={name:t.name,path:t.path,hash:t.hash,query:t.query,params:t.params,fullPath:t.fullPath,meta:t.meta};return u&&(r.from=e(u)),Object.freeze(r)}return t.sync=function(t,u,r){var a=(r||{}).moduleName||"route";t.registerModule(a,{namespaced:!0,state:e(u.currentRoute.value),mutations:{ROUTE_CHANGED:function(u,r){t.state[a]=e(r.to,r.from)}}});var n,o=!1,c=t.watch((function(t){return t[a]}),(function(t){var e=t.fullPath;e!==n&&(null!=n&&(o=!0,u.push(t)),n=e)}),{flush:"sync"}),f=u.afterEach((function(e,u){o?o=!1:(n=e.fullPath,t.commit(a+"/ROUTE_CHANGED",{to:e,from:u}))}));return function(){f(),c(),t.unregisterModule(a)}},Object.defineProperty(t,"__esModule",{value:!0}),t}({});
