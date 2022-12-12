<center>
  <img src="https://raw.githubusercontent.com/storybookjs/storybook/main/addons/docs/docs/media/hero.png" width="100%" />
</center>

# Storybook Docs

> migration guide: This page documents the method to configure storybook introduced recently in 5.3.0, consult the [migration guide](https://github.com/storybookjs/storybook/blob/next/MIGRATION.md) if you want to migrate to this format of configuring storybook.

Storybook Docs transforms your Storybook stories into world-class component documentation.

**DocsPage.** Out of the box, all your stories get a `DocsPage`. `DocsPage` is a zero-config aggregation of your component stories, text descriptions, docgen comments, props tables, and code examples into clean, readable pages.

**MDX.** If you want more control, `MDX` allows you to write long-form markdown documentation and stories in one file. You can also use it to write pure documentation pages and embed them inside your Storybook alongside your stories.

Just like Storybook, Docs supports every major view layer including React, Vue, Angular, HTML, Web components, Svelte, and many more.

Read on to learn more:

- [Storybook Docs](#storybook-docs)
  - [DocsPage](#docspage)
  - [MDX](#mdx)
  - [Framework support](#framework-support)
  - [Installation](#installation)
    - [Be sure to check framework specific installation needs](#be-sure-to-check-framework-specific-installation-needs)
  - [Preset options](#preset-options)
  - [Manual configuration](#manual-configuration)
  - [TypeScript configuration](#typescript-configuration)
  - [More resources](#more-resources)

## DocsPage

When you [install Docs](#installation), every story gets a `DocsPage`. `DocsPage` pulls information from your stories, components, source code, and story metadata to construct a sensible, zero-config default.

Click on the `Docs` tab to see it:

<center>
  <img src="https://raw.githubusercontent.com/storybookjs/storybook/main/addons/docs/docs/media/docs-tab.png" width="100%" />
</center>

For more information on how it works, see the [`DocsPage` reference](https://github.com/storybookjs/storybook/tree/next/addons/docs/docs/docspage.md).

## MDX

`MDX` is a syntax for writing long-form documentation and stories side-by-side in the same file. In contrast to `DocsPage`, which provides smart documentation out of the box, `MDX` gives you full control over your component documentation.

Here's an example file:

```md
import { Meta, Story, Canvas } from '@storybook/addon-docs';
import { Checkbox } from './Checkbox';

<Meta title="MDX/Checkbox" component={Checkbox} />

# Checkbox

With `MDX` we can define a story for `Checkbox` right in the middle of our
markdown documentation.

<Canvas>
  <Story name="all checkboxes">
    <form>
      <Checkbox id="Unchecked" label="Unchecked" />
      <Checkbox id="Checked" label="Checked" checked />
      <Checkbox appearance="secondary" id="second" label="Secondary" checked />
    </form>
  </Story>
</Canvas>
```

And here's how that's rendered in Storybook:

<center>
  <img src="https://raw.githubusercontent.com/storybookjs/storybook/main/addons/docs/docs/media/mdx-simple.png" width="100%" />
</center>

For more information on `MDX`, see the [`MDX` reference](https://github.com/storybookjs/storybook/tree/next/addons/docs/docs/mdx.md).

## Framework support

Storybook Docs supports all view layers that Storybook supports except for React Native (currently). There are some framework-specific features as well, such as props tables and inline story rendering. The following page captures the current state of support:

[Framework Support](https://storybook.js.org/docs/react/api/frameworks-feature-support)


**Note:** `#` = WIP support

Want to add enhanced features to your favorite framework? Check out this [dev guide](https://github.com/storybookjs/storybook/tree/next/addons/docs/docs/multiframework.md)

## Installation

First add the package. Make sure that the versions for your `@storybook/*` packages match:

```sh
yarn add -D @storybook/addon-docs
```

Docs has peer dependencies on `react`. If you want to write stories in MDX, you may need to add this dependency as well:

```sh
yarn add -D react
```

Then add the following to your `.storybook/main.js`:

```js
module.exports = {
  stories: ['../src/**/*.stories.@(js|mdx)'],
  addons: ['@storybook/addon-docs'],
};
```

If using in conjunction with the [storyshots add-on](https://github.com/storybookjs/storybook/blob/next/addons/storyshots/storyshots-core/README.md), you will need to
configure Jest to transform MDX stories into something Storyshots can understand:

Add the following to your Jest configuration:

```json
{
  "transform": {
    "^.+\\.[tj]sx?$": "babel-jest",
    "^.+\\.mdx$": "@storybook/addon-docs/jest-transform-mdx"
  }
}
```

### Be sure to check framework specific installation needs

- [React](https://github.com/storybookjs/storybook/tree/next/addons/docs/react) (covered here)
- [Vue](https://github.com/storybookjs/storybook/tree/next/addons/docs/vue)
- [Angular](https://github.com/storybookjs/storybook/tree/next/addons/docs/angular)
- [Ember](https://github.com/storybookjs/storybook/tree/next/addons/docs/ember)
- [Web Components](https://github.com/storybookjs/storybook/tree/next/addons/docs/web-components)
- [Common setup (all other frameworks)](https://github.com/storybookjs/storybook/tree/next/addons/docs/common)

## Preset options

The `addon-docs` preset has a few configuration options that can be used to configure its babel/webpack loading behavior. Here's an example of how to use the preset with options:

```js
module.exports = {
  addons: [
    {
      name: '@storybook/addon-docs',
      options: {
        configureJSX: true,
        babelOptions: {},
        sourceLoaderOptions: null,
        transcludeMarkdown: true,
      },
    },
  ],
};
```

The `configureJSX` option is useful when you're writing your docs in MDX and your project's babel config isn't already set up to handle JSX files. `babelOptions` is a way to further configure the babel processor when you're using `configureJSX`.

`sourceLoaderOptions` is an object for configuring `@storybook/source-loader`. When set to `null` it tells docs not to run the `source-loader` at all, which can be used as an optimization, or if you're already using `source-loader` in your `main.js`.

The `transcludeMarkdown` option enables mdx files to import `.md` files and render them as a component.

```mdx
import { Meta } from '@storybook/addon-docs';
import Changelog from '../CHANGELOG.md';

<Meta title="Changelog" />

<Changelog />
```

## Manual configuration

We recommend using the preset, which should work out of the box. If you don't want to use the preset, and prefer to configure "the long way" add the following configuration to `.storybook/main.js` (see comments inline for explanation):

```js
const createCompiler = require('@storybook/addon-docs/mdx-compiler-plugin');

module.exports = {
  // 1. register the docs panel (as opposed to '@storybook/addon-docs' which
  //    will configure everything with a preset)
  addons: ['@storybook/addon-docs/register'],
  // 2. manually configure webpack, since you're not using the preset
  webpackFinal: async (config) => {
    config.module.rules.push({
      // 2a. Load `.stories.mdx` / `.story.mdx` files as CSF and generate
      //     the docs page from the markdown
      test: /\.(stories|story)\.mdx$/,
      use: [
        {
          // Need to add babel-loader as dependency: `yarn add -D babel-loader`
          loader: require.resolve('babel-loader'),
          // may or may not need this line depending on your app's setup
          options: {
            plugins: ['@babel/plugin-transform-react-jsx'],
          },
        },
        {
          loader: '@mdx-js/loader',
          options: {
            compilers: [createCompiler({})],
          },
        },
      ],
    });
    // 2b. Run `source-loader` on story files to show their source code
    //     automatically in `DocsPage` or the `Source` doc block.
    config.module.rules.push({
      test: /\.(stories|story)\.[tj]sx?$/,
      loader: require.resolve('@storybook/source-loader'),
      exclude: [/node_modules/],
      enforce: 'pre',
    });
    return config;
  },
};
```

You'll also need to set up the docs parameter in `.storybook/preview.js`. This includes the `DocsPage` for rendering the page, a container, and various configuration options, such as `extractComponentDescription` for manually extracting a component description:

```js
import { addParameters } from '@storybook/react';
import { DocsPage, DocsContainer } from '@storybook/addon-docs';

addParameters({
  docs: {
    container: DocsContainer,
    page: DocsPage,
  },
});
```

## TypeScript configuration

As of SB6 [TypeScript is zero-config](https://storybook.js.org/docs/react/configure/typescript) and should work with SB Docs out of the box. For advanced configuration options, refer to the [Props documentation](https://github.com/storybookjs/storybook/tree/next/addons/docs/docs/props-tables.md).

## More resources

Want to learn more? Here are some more articles on Storybook Docs:

- References: [DocsPage](https://github.com/storybookjs/storybook/tree/next/addons/docs/docs/docspage.md) / [MDX](https://github.com/storybookjs/storybook/tree/next/addons/docs/docs/mdx.md) / [FAQ](https://github.com/storybookjs/storybook/tree/next/addons/docs/docs/faq.md) / [Recipes](https://github.com/storybookjs/storybook/tree/next/addons/docs/docs/recipes.md) / [Theming](https://github.com/storybookjs/storybook/tree/next/addons/docs/docs/theming.md) / [Props](https://github.com/storybookjs/storybook/tree/next/addons/docs/docs/props-tables.md)
- Announcements: [Vision](https://medium.com/storybookjs/storybook-docs-sneak-peak-5be78445094a) / [DocsPage](https://medium.com/storybookjs/storybook-docspage-e185bc3622bf) / [MDX](https://medium.com/storybookjs/rich-docs-with-storybook-mdx-61bc145ae7bc) / [Framework support](https://medium.com/storybookjs/storybook-docs-for-new-frameworks-b1f6090ee0ea)
- Example: [Storybook Design System](https://github.com/storybookjs/design-system)
