# Storybook Addon Actions

Storybook Addon Actions can be used to display data received by event handlers in [Storybook](https://storybook.js.org).

[Framework Support](https://storybook.js.org/docs/react/api/frameworks-feature-support)

![Screenshot](https://raw.githubusercontent.com/storybookjs/storybook/next/addons/actions/docs/screenshot.png)

## Installation

Actions is part of [essentials](https://storybook.js.org/docs/react/essentials/introduction) and so is installed in all new Storybooks by default. If you need to add it to your Storybook, you can run:

```sh
npm i -D @storybook/addon-actions
```

Then, add following content to [`.storybook/main.js`](https://storybook.js.org/docs/react/configure/overview#configure-your-storybook-project):

```js
module.exports = {
  addons: ['@storybook/addon-actions'],
};
```

## Usage

The basic usage is documented in the [documentation](https://storybook.js.org/docs/react/essentials/actions). For legacy usage, see the [advanced README](./ADVANCED.md).
