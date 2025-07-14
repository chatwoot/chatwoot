# Highlight.js plugin for Vue.js

[![latest version](https://badgen.net/npm/v/@highlightjs/vue-plugin/latest?label=latest)](https://www.npmjs.com/package/@highlightjs/vue-plugin)
[![latest version](https://badgen.net/npm/v/@highlightjs/vue-plugin/next?label=next)](https://www.npmjs.com/package/@highlightjs/vue-plugin)
![vue 3](https://badgen.net/badge/vue/3/green)
![vue 2](https://badgen.net/badge/vue/2/green)
[![license](https://badgen.net/github/license/highlightjs/vue-plugin?color=cyan)](https://github.com/highlightjs/vue-plugin/blob/main/LICENSE)

[![publish size](https://badgen.net/packagephobia/publish/@highlightjs/vue-plugin?label=size)](https://packagephobia.com/result?p=@highlightjs/vue-plugin)
[![gzipped size](https://badgen.net/bundlephobia/minzip/@highlightjs/vue-plugin?label=gzipped)](https://bundlephobia.com/result?p=@highlightjs/vue-plugin)
[![slack](https://badgen.net/badge/icon/slack?icon=slack&label&color=pink)](https://join.slack.com/t/highlightjs/shared_invite/zt-mj0utgqp-TNFf4VQICnDnPg4zMHChFw)


This plugin provides a `highlightjs` component for use in your Vue.js 3 applications:

```html
<div id="app">
    <!-- bind to a data property named `code` -->
    <highlightjs autodetect :code="code" />
    <!-- or literal code works as well -->
    <highlightjs language='javascript' code="var x = 5;" />
</div>
```

Note: For Vue.js version 2 support see the [1-stable](https://github.com/highlightjs/vue-plugin/tree/1-stable) branch here on GitHub.  The `latest` tag via NPM is compatible with Vue.js v2; the `next` tag Vue.js v3.

## Using the pre-built libraries

```html
<link rel="stylesheet" href="/path/to/styles/default.css">
<script src="/path/to/highlight.min.js"></script>
<script src="/path/to/highlight-vue.min.js"></script>
```

Then simply register the plugin with Vue:

```js
const app = createApp(App)
app.use(hljsVuePlugin)
```


## Using ES6 modules / bundling

```js
import hljs from 'highlight.js/lib/core';
import javascript from 'highlight.js/lib/languages/javascript';
import hljsVuePlugin from "@highlightjs/vue-plugin";

hljs.registerLanguage('javascript', javascript);

const app = createApp(App)
app.use(hljsVuePlugin)
app.mount('#app')
```

Note: The plugin imports `highlight.js/lib/core` internally (but no languages).  Thanks to the magic of ES6 modules you can import Highlight.js anywhere to register languages or configure the library.  Any import of Highlight.js refers to the same singleton instance of the library, so configuring the library anywhere configures it everywhere.

You can also simply load all "common" languages at once (as of v11):

```js
import hljs from 'highlight.js/lib/common';
import hljsVuePlugin from "@highlightjs/vue-plugin";

const app = createApp(App)
app.use(hljsVuePlugin)
app.mount('#app')
```

## Using component locally

```vue
<template>
    <highlightjs
        language="js"
        code="console.log('Hello World');"
    />
</template>

<script>
import hljs from 'highlight.js/lib/common';
import hljsVuePlugin from "@highlightjs/vue-plugin";

export default {
    components: {
        highlightjs: hljsVuePlugin.component
    }
}
</script>
```

## Building the pre-built library from source

We use rollup to build the `dist` distributable.

```
npm run build
```
