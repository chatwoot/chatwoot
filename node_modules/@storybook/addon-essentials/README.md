# Storybook Essentials

Storybook Essentials is a curated collection of addons to bring out the best of Storybook.

Each addon is documented and maintained by the core team and will be upgraded alongside Storybook as the platform evolves. We will also do our best to maintain [framework support](https://storybook.js.org/docs/react/api/frameworks-feature-support) for all of the officially supported frameworks.

## Contents

Storybook essentials includes the following addons. Addons can be disabled and re-configured as [described below](#configuration):

- [Actions](https://github.com/storybookjs/storybook/tree/next/addons/actions)
- [Backgrounds](https://github.com/storybookjs/storybook/tree/next/addons/backgrounds)
- [Controls](https://github.com/storybookjs/storybook/tree/next/addons/controls)
- [Docs](https://github.com/storybookjs/storybook/tree/next/addons/docs)
- [Viewport](https://github.com/storybookjs/storybook/tree/next/addons/viewport)
- [Toolbars](https://github.com/storybookjs/storybook/tree/next/addons/toolbars)

## Installation

You can add Essentials to your project with:

```
npm install --save-dev @storybook/addon-essentials
```

And then add the following line to your `.storybook/main.js`:

```js
module.exports = {
  addons: ['@storybook/addon-essentials'],
};
```

## Configuration

Essentials is "zero config." That means that comes with a recommended configuration out of the box.

If you want to reconfigure an addon, simply install that addon per that addon's installation instructions and configure it as normal. Essentials scans your project's `main.js` on startup and if detects one of its addons is already configured in the `addons` field, it will skip that addon's configuration entirely.

## Disabling addons

You can disable any of Essential's addons using the following configuration scheme in `.storybook/main.js`:

```js
module.exports = {
  addons: [{
    name: '@storybook/addon-essentials',
    options: {
      <addon-key>: false,
    }
  }]
};
```

Valid addon keys include: `actions`, `backgrounds`, `controls`, `docs`, `viewport`, `toolbars`.
