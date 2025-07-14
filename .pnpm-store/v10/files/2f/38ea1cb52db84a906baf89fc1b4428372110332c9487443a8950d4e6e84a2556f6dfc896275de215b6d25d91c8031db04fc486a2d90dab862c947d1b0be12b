**💛 You can help the author become a full-time open-source maintainer by [sponsoring him on GitHub](https://github.com/sponsors/egoist).**

---

# @egoist/tailwindcss-icons

> Use any icon from [Iconify](https://iconify.design/)

[![npm version](https://badgen.net/npm/v/@egoist/tailwindcss-icons)](https://npm.im/@egoist/tailwindcss-icons) [![npm downloads](https://badgen.net/npm/dm/@egoist/tailwindcss-icons)](https://npm.im/@egoist/tailwindcss-icons)

<img src="https://user-images.githubusercontent.com/8784712/219618866-e5632d23-b948-4fa1-b3d6-00581a704bca.png" alt="preview" width="700" />

## Install

```bash
npm i @egoist/tailwindcss-icons -D
```

## Usage

In your `tailwind.config.js`:

```js
const { iconsPlugin, getIconCollections } = require("@egoist/tailwindcss-icons")

module.exports = {
  plugins: [
    iconsPlugin({
      // Select the icon collections you want to use
      // You can also ignore this option to automatically discover all individual icon packages you have installed
      // If you install @iconify/json, you should explicitly specify the collections you want to use, like this:
      collections: getIconCollections(["mdi", "lucide"]),
      // If you want to use all icons from @iconify/json, you can do this:
      // collections: getIconCollections("all"),
      // and the more recommended way is to use `dynamicIconsPlugin`, see below.
    }),
  ],
}
```

You also need to install `@iconify/json` (full icon collections, 50MB) or `@iconify-json/{collection_name}` (individual icon package):

```bash
# install every icon:
npm i @iconify/json -D

# or install individual packages like this:
npm i @iconify-json/mdi @iconify-json/lucide -D
```

Then you can use the icons in your HTML:

```html
<!-- pattern: i-{collection_name}-{icon_name} -->
<span class="i-mdi-home"></span>
```

Search the icon you want to use here: https://icones.js.org

> [!TIP]
> To get the full list of icon names as typescript type, you can refer to [this issue](https://github.com/egoist/tailwindcss-icons/issues/18#issuecomment-1987191833).

### Plugin Options

| Option               | Type                              | Default     | Description                                              |
| -------------------- | --------------------------------- | ----------- | -------------------------------------------------------- |
| prefix               | string                            | `i`         | Class prefix for matching icon rules                     |
| scale                | number                            | `1`         | Scale relative to the current font size                  |
| strokeWidth          | number                            | `undefined` | Stroke width for icons (this may not work for all icons) |
| extraProperties      | Record<string, string>            | `{}`        | Extra CSS properties applied to the generated CSS.       |
| collectionNamesAlias | [key in CollectionNames]?: string | `{}`        | Alias to customize collection names.                     |

### Custom Icons

You can also use custom icons with this plugin, for example:

```js
module.exports = {
  plugins: [
    iconsPlugin({
      collections: {
        foo: {
          icons: {
            "arrow-left": {
              // svg body
              body: '<path d="M10 19l-7-7m0 0l7-7m-7 7h18"/>',
              // svg width and height, optional
              width: 24,
              height: 24,
            },
          },
        },
      },
    }),
  ],
}
```

Then you can use this custom icon as class name: `i-foo-arrow-left`.

> [!TIP]
> To read custom icons from directory, you can refer to [Load svgs from filesystem](https://github.com/egoist/tailwindcss-icons/issues/37)

### Generate Icon Dynamically

The idea is from [@iconify/tailwind](https://iconify.design/docs/usage/css/tailwind),
thanks to the author of Iconify for the great work!

If you want to install `@iconify/json` and use whatever icon you want,
you should add another plugin to your `tailwind.config.js`.

This is because we can not provide autocomplete for all icons from `@iconify/json`,
it will make your editor slow.

```js
const { iconsPlugin, dynamicIconsPlugin } = require("@egoist/tailwindcss-icons")

module.exports = {
  plugins: [iconsPlugin(), dynamicIconsPlugin()],
}
```

Then you can use icons dynamically like `<span class="i-[mdi-light--home]"></span>`.

## Sponsors

[![sponsors](https://sponsors-images.egoist.dev/sponsors.svg)](https://github.com/sponsors/egoist)

## License

MIT &copy; [EGOIST](https://github.com/sponsors/egoist)
