# Builder-Webpack4

Builder implemented with `webpack4` and `webpack4`-compatible loaders/plugins/config, used by `@storybook/core-server` to build the preview iframe.

`builder-webpack4` is the default, so no configuration is necessary to use it. However, if you wan to explicitly configure your Storybook to run `builder-webpack4`, install it as a dev dependency and then update your `.storybook/main.js` configuration.

```js
module.exports = {
  core: {
    builder: 'webpack4',
  },
};
```
