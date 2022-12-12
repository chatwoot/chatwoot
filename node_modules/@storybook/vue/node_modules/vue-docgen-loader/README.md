# vue-docgen-loader

[![Current status of Test and Lint workflow](https://github.com/pocka/vue-docgen-loader/workflows/Test%20and%20Lint/badge.svg)](https://github.com/pocka/vue-docgen-loader/actions)
[![Current status of Publish package workflow](https://github.com/pocka/vue-docgen-loader/workflows/Publish%20package/badge.svg)](https://github.com/pocka/vue-docgen-loader/actions)

[![npm](https://img.shields.io/npm/v/vue-docgen-loader)](https://www.npmjs.com/package/vue-docgen-loader)
[![npm](https://img.shields.io/npm/dm/vue-docgen-loader)](https://www.npmjs.com/package/vue-docgen-loader)

This package allows parsing Vue component file with [vue-docgen-api](https://github.com/vue-styleguidist/vue-styleguidist/tree/dev/packages/vue-docgen-api) then injecting the result into the output file.

## Getting Started

First, install the loader and vue-docgen-api.

```sh
$ yarn add -D vue-docgen-loader vue-docgen-api
# or npm
# $ npm i -D vue-docgen-loader vue-docgen-api
```

Then add the loader to your webpack config file.
**Please make sure to run the loader at the last of the loader chain**.

```js
import MyComponent from './my-component.vue'

Vue.extend({
  // You can use the components as usual
  components: { MyComponent }
})
```

```js
// webpack.config.js
module.exports = {
  module: {
    rules: [
      {
        test: /\.vue$/,
        use: 'vue-loader'
      },
      {
        // You also can put this loader above, but I recommend to use
        // a separeted rule with enforce: 'post' for maintainability
        // and simplicity. For example, you can enable the loader only
        // for development build.
        test: /\.vue$/,
        use: 'vue-docgen-loader',
        enforce: 'post'
      }
    ]
  },
  plugins: [new VueLoaderPlugin()]
}
```

If you want to apply this loader to non-SFC files like below, you also need to
setup a rule for them. This works only with vue-docgen-api >= 4.0.0.

```js
// my-button.js
import Vue from 'vue'

export const MyButton = Vue.extend({
  props: {
    foo: {
      type: String
    }
  },
  template: '<button/>'
})
```

```js
// other.js
import MyButton from './my-button.js?component'
```

```js
// webpack.config.js
module.exports = {
  module: {
    rules: [
      // Please make sure to apply the loader only for Vue components: In this
      // sample, only modules imported with ?component query will match.
      //
      // IMPORTANT!
      // Do not use ?vue query if you're using vue-loader. It will sliently inject
      // .js?vue rule into rules array and it breaks the module.
      {
        test: /\.js$/,
        resourceQuery: /component/,
        use: 'vue-docgen-loader',
        enforce: 'post'
      }
    ]
  }
}
```

## Options

You can pass options for vue-docgen-api through `docgenOptions` and specify the property name the loader inject docgen result at.

```js
{
  test: /\.vue$/,
    loader: 'vue-docgen-loader',
    options: {
      docgenOptions: {
        // options for vue-docgen-api...
      },
      // Injected property name
      injectAt: '__docgenInfo' // default
    },
    enforce: 'post'
}
```

## Contributing

Please read our contributing guidelines.

[CONTRIBUTING](./CONTRIBUTING.md)
