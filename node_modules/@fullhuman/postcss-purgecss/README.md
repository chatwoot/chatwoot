# PostCSS Purgecss
![David (path)](https://img.shields.io/david/FullHuman/purgecss?path=packages%2Fpostcss-purgecss&style=for-the-badge)
![Dependabot](https://img.shields.io/badge/dependabot-enabled-%23024ea4?style=for-the-badge)
![npm](https://img.shields.io/npm/v/@fullhuman/postcss-purgecss?style=for-the-badge)
![npm](https://img.shields.io/npm/dw/@fullhuman/postcss-purgecss?style=for-the-badge)
![GitHub](https://img.shields.io/github/license/FullHuman/purgecss?style=for-the-badge)

[PostCSS] plugin for PurgeCSS.

[PostCSS]: https://github.com/postcss/postcss

## Installation

```
npm i -D @fullhuman/postcss-purgecss
```

## Usage

```js
const purgecss = require('@fullhuman/postcss-purgecss')
postcss([
  purgecss({
    content: ['./src/**/*.html']
  })
])
```

See [PostCSS] docs for examples for your environment.

## Options

All of the options of purgecss are available to use with the plugins.
You will find below the main options available. For the complete list, go to the [purgecss documentation website](https://www.purgecss.com/configuration.html#options).

### `content` (**required** or use `contentFunction` instead)
Type: `Array<string>`

You can specify content that should be analyzed by Purgecss with an array of filenames or globs. The files can be HTML, Pug, Blade, etc.

### `contentFunction` (as alternative to `content`)
Type: `(sourceInputFile: string) => Array<string>`

The function receives the current source input file. With this you may provide a specific array of globs for each input. E.g. for 
an angular application only scan the components template counterpart for every component scss file:

```js
purgecss({
  contentFunction: (sourceInputFileName: string) => {
    if (/component\.scss$/.test(sourceInputFileName))
      return [sourceInputFileName.replace(/scss$/, 'html')]
    else
      return ['./src/**/*.html']
  },
})
```

### `extractors`
Type: `Array<Object>`

Purgecss can be adapted to suit your needs. If you notice a lot of unused CSS is not being removed, you might want to use a custom extractor.
More information about extractors [here](https://www.purgecss.com/extractors.html).

### `whitelist`
Type: `Array<string>`

You can whitelist selectors to stop Purgecss from removing them from your CSS. This can be accomplished with the options whitelist and whitelistPatterns.

### `whitelistPatterns`
Type: `Array<RegExp>`

You can whitelist selectors based on a regular expression with whitelistPatterns.

### `rejected`
Type: `boolean`
Default value: `false`

If true, purged selectors will be captured and rendered as PostCSS messages.
Use with a PostCSS reporter plugin like [`postcss-reporter`](https://github.com/postcss/postcss-reporter)
to print the purged selectors to the console as they are processed.

### `keyframes`
Type: `boolean`
Default value: `false`

If you are using a CSS animation library such as animate.css, you can remove unused keyframes by setting the keyframes option to true.

#### `fontFace`
Type: `boolean`
Default value: `false`

If there are any unused @font-face rules in your css, you can remove them by setting the fontFace option to true.

## Contributing

Please read [CONTRIBUTING.md](./../../CONTRIBUTING.md) for details on our code of
conduct, and the process for submitting pull requests to us.

## Versioning

postcss-purgecss use [SemVer](http://semver.org/) for versioning.

## License

This project is licensed under the MIT License - see the [LICENSE](./../../LICENSE) file
for details.
