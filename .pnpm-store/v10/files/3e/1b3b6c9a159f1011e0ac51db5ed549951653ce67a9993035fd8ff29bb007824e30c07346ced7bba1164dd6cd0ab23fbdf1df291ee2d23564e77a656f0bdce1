# eslint-plugin-prettier [![Build Status](https://github.com/prettier/eslint-plugin-prettier/workflows/CI/badge.svg?branch=master)](https://github.com/prettier/eslint-plugin-prettier/actions?query=workflow%3ACI+branch%3Amaster)

Runs [Prettier](https://github.com/prettier/prettier) as an [ESLint](https://eslint.org) rule and reports differences as individual ESLint issues.

If your desired formatting does not match Prettier’s output, you should use a different tool such as [prettier-eslint](https://github.com/prettier/prettier-eslint) instead.

Please read [Integrating with linters](https://prettier.io/docs/en/integrating-with-linters.html) before installing.

## TOC <!-- omit in toc -->

- [Sample](#sample)
- [Installation](#installation)
- [Configuration (legacy: `.eslintrc*`)](#configuration-legacy-eslintrc)
- [Configuration (new: `eslint.config.js`)](#configuration-new-eslintconfigjs)
- [`Svelte` support](#svelte-support)
- [`arrow-body-style` and `prefer-arrow-callback` issue](#arrow-body-style-and-prefer-arrow-callback-issue)
- [Options](#options)
- [Sponsors](#sponsors)
- [Backers](#backers)
- [Contributing](#contributing)
- [Changelog](#changelog)
- [License](#license)

## Sample

```js
error: Insert `,` (prettier/prettier) at pkg/commons-atom/ActiveEditorRegistry.js:22:25:
  20 | import {
  21 |   observeActiveEditorsDebounced,
> 22 |   editorChangesDebounced
     |                         ^
  23 | } from './debounced';;
  24 |
  25 | import {observableFromSubscribeFunction} from '../commons-node/event';


error: Delete `;` (prettier/prettier) at pkg/commons-atom/ActiveEditorRegistry.js:23:21:
  21 |   observeActiveEditorsDebounced,
  22 |   editorChangesDebounced
> 23 | } from './debounced';;
     |                     ^
  24 |
  25 | import {observableFromSubscribeFunction} from '../commons-node/event';
  26 | import {cacheWhileSubscribed} from '../commons-node/observable';


2 errors found.
```

> `./node_modules/.bin/eslint --format codeframe pkg/commons-atom/ActiveEditorRegistry.js` (code from [nuclide](https://github.com/facebook/nuclide)).

## Installation

```sh
npm install --save-dev eslint-plugin-prettier eslint-config-prettier
npm install --save-dev --save-exact prettier
```

**_`eslint-plugin-prettier` does not install Prettier or ESLint for you._** _You must install these yourself._

This plugin works best if you disable all other ESLint rules relating to code formatting, and only enable rules that detect potential bugs. If another active ESLint rule disagrees with `prettier` about how code should be formatted, it will be impossible to avoid lint errors. Our recommended configuration automatically enables [`eslint-config-prettier`](https://github.com/prettier/eslint-config-prettier) to disable all formatting-related ESLint rules.

## Configuration (legacy: `.eslintrc*`)

For [legacy configuration](https://eslint.org/docs/latest/use/configure/configuration-files), this plugin ships with a `plugin:prettier/recommended` config that sets up both `eslint-plugin-prettier` and [`eslint-config-prettier`](https://github.com/prettier/eslint-config-prettier) in one go.

Add `plugin:prettier/recommended` as the _last_ item in the extends array in your `.eslintrc*` config file, so that `eslint-config-prettier` has the opportunity to override other configs:

```json
{
  "extends": ["plugin:prettier/recommended"]
}
```

This will:

- Enable the `prettier/prettier` rule.
- Disable the `arrow-body-style` and `prefer-arrow-callback` rules which are problematic with this plugin - see the below for why.
- Enable the `eslint-config-prettier` config which will turn off ESLint rules that conflict with Prettier.

## Configuration (new: `eslint.config.js`)

For [flat configuration](https://eslint.org/docs/latest/use/configure/configuration-files-new), this plugin ships with an `eslint-plugin-prettier/recommended` config that sets up both `eslint-plugin-prettier` and [`eslint-config-prettier`](https://github.com/prettier/eslint-config-prettier) in one go.

Import `eslint-plugin-prettier/recommended` and add it as the _last_ item in the configuration array in your `eslint.config.js` file so that `eslint-config-prettier` has the opportunity to override other configs:

```js
const eslintPluginPrettierRecommended = require('eslint-plugin-prettier/recommended');

module.exports = [
  // Any other config imports go at the top
  eslintPluginPrettierRecommended,
];
```

This will:

- Enable the `prettier/prettier` rule.
- Disable the `arrow-body-style` and `prefer-arrow-callback` rules which are problematic with this plugin - see the below for why.
- Enable the `eslint-config-prettier` config which will turn off ESLint rules that conflict with Prettier.

## `Svelte` support

We recommend to use [`eslint-plugin-svelte`](https://github.com/ota-meshi/eslint-plugin-svelte) instead of [`eslint-plugin-svelte3`](https://github.com/sveltejs/eslint-plugin-svelte3) because `eslint-plugin-svelte` has a correct [`eslint-svelte-parser`](https://github.com/ota-meshi/svelte-eslint-parser) instead of hacking.

When use with `eslint-plugin-svelte3`, `eslint-plugin-prettier` will just ignore the text passed by `eslint-plugin-svelte3`, because the text has been modified.

If you still decide to use `eslint-plugin-svelte3`, you'll need to run `prettier --write *.svelte` manually.

## `arrow-body-style` and `prefer-arrow-callback` issue

If you use [arrow-body-style](https://eslint.org/docs/rules/arrow-body-style) or [prefer-arrow-callback](https://eslint.org/docs/rules/prefer-arrow-callback) together with the `prettier/prettier` rule from this plugin, you can in some cases end up with invalid code due to a bug in ESLint’s autofix – see [issue #65](https://github.com/prettier/eslint-plugin-prettier/issues/65).

For this reason, it’s recommended to turn off these rules. The `plugin:prettier/recommended` config does that for you.

You _can_ still use these rules together with this plugin if you want, because the bug does not occur _all the time._ But if you do, you need to keep in mind that you might end up with invalid code, where you manually have to insert a missing closing parenthesis to get going again.

If you’re fixing large of amounts of previously unformatted code, consider temporarily disabling the `prettier/prettier` rule and running `eslint --fix` and `prettier --write` separately.

## Options

> Note: While it is possible to pass options to Prettier via your ESLint configuration file, it is not recommended because editor extensions such as `prettier-atom` and `prettier-vscode` **will** read [`.prettierrc`](https://prettier.io/docs/en/configuration.html), but **won't** read settings from ESLint, which can lead to an inconsistent experience.

- The first option:

  - An object representing [options](https://prettier.io/docs/en/options.html) that will be passed into prettier. Example:

    ```json
    {
      "prettier/prettier": [
        "error",
        {
          "singleQuote": true,
          "parser": "flow"
        }
      ]
    }
    ```

    NB: This option will merge and override any config set with `.prettierrc` files

- The second option:

  - An object with the following options

    - `usePrettierrc`: Enables loading of the Prettier configuration file, (default: `true`). May be useful if you are using multiple tools that conflict with each other, or do not wish to mix your ESLint settings with your Prettier configuration. And also, it is possible to run prettier without loading the prettierrc config file [via the CLI's --no-config option](https://prettier.io/docs/en/cli.html#--no-config) or through the API by [calling prettier.format() without passing through the options generated by calling resolveConfig](https://prettier.io/docs/en/api.html#prettierresolveconfigfilepath--options).

      ```json
      {
        "prettier/prettier": [
          "error",
          {},
          {
            "usePrettierrc": false
          }
        ]
      }
      ```

    - `fileInfoOptions`: Options that are passed to [prettier.getFileInfo](https://prettier.io/docs/en/api.html#prettiergetfileinfofilepath--options) to decide whether a file needs to be formatted. Can be used for example to opt-out from ignoring files located in `node_modules` directories.

      ```json
      {
        "prettier/prettier": [
          "error",
          {},
          {
            "fileInfoOptions": {
              "withNodeModules": true
            }
          }
        ]
      }
      ```

- The rule is auto fixable -- if you run `eslint` with the `--fix` flag, your code will be formatted according to `prettier` style.

---

## Sponsors

| @prettier/plugin-eslint                                                                                                                                                        | eslint-config-prettier                                                                                                                                                       | eslint-plugin-prettier                                                                                                                                     | prettier-eslint                                                                                                                                          | prettier-eslint-cli                                                                                                                                                 |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![@prettier/plugin-eslint Open Collective sponsors](https://opencollective.com/prettier-plugin-eslint/tiers/sponsors.svg)](https://opencollective.com/prettier-plugin-eslint) | [![eslint-config-prettier Open Collective backers](https://opencollective.com/eslint-config-prettier/tiers/sponsors.svg)](https://opencollective.com/eslint-config-prettier) | [![eslint-plugin-prettier Open Collective backers](https://opencollective.com/eslint-plugin-prettier/tiers/sponsors.svg)](https://opencollective.com/rxts) | [![prettier-eslint Open Collective sponsors](https://opencollective.com/prettier-eslint/tiers/sponsors.svg)](https://opencollective.com/prettier-eslint) | [![prettier-eslint-cli Open Collective backers](https://opencollective.com/prettier-eslint-cli/tiers/sponsors.svg)](https://opencollective.com/prettier-eslint-cli) |

## Backers

| @prettier/plugin-eslint                                                                                                                                                      | eslint-config-prettier                                                                                                                                                      | eslint-plugin-prettier                                                                                                                                    | prettier-eslint                                                                                                                                        | prettier-eslint-cli                                                                                                                                                |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [![@prettier/plugin-eslint Open Collective backers](https://opencollective.com/prettier-plugin-eslint/tiers/backers.svg)](https://opencollective.com/prettier-plugin-eslint) | [![eslint-config-prettier Open Collective backers](https://opencollective.com/eslint-config-prettier/tiers/backers.svg)](https://opencollective.com/eslint-config-prettier) | [![eslint-plugin-prettier Open Collective backers](https://opencollective.com/eslint-plugin-prettier/tiers/backers.svg)](https://opencollective.com/rxts) | [![prettier-eslint Open Collective backers](https://opencollective.com/prettier-eslint/tiers/backers.svg)](https://opencollective.com/prettier-eslint) | [![prettier-eslint-cli Open Collective backers](https://opencollective.com/prettier-eslint-cli/tiers/backers.svg)](https://opencollective.com/prettier-eslint-cli) |

## Contributing

See [CONTRIBUTING.md](https://github.com/prettier/eslint-plugin-prettier/blob/master/CONTRIBUTING.md)

## Changelog

Detailed changes for each release are documented in [CHANGELOG.md](./CHANGELOG.md).

## License

[MIT](http://opensource.org/licenses/MIT)
