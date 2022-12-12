# Storybook Addon Backgrounds

Storybook Addon Backgrounds can be used to change background colors inside the preview in [Storybook](https://storybook.js.org).

[Framework Support](https://storybook.js.org/docs/react/api/frameworks-feature-support)

![React Storybook Screenshot](https://raw.githubusercontent.com/storybookjs/storybook/next/addons/backgrounds/docs/addon-backgrounds.gif)

## Installation

Backgrounds is part of [essentials](https://storybook.js.org/docs/react/essentials/introduction) and so is installed in all new Storybooks by default. If you need to add it to your Storybook, you can run:

```sh
npm i -D @storybook/addon-backgrounds
```

## Configuration

Then, add following content to [`.storybook/main.js`](https://storybook.js.org/docs/react/configure/overview#configure-your-storybook-project):

```js
module.exports = {
  addons: ['@storybook/addon-backgrounds'],
};
```

## Usage

The usage is documented in the [documentation](https://storybook.js.org/docs/react/essentials/backgrounds).
