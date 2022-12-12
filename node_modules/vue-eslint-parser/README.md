# vue-eslint-parser

[![npm version](https://img.shields.io/npm/v/vue-eslint-parser.svg)](https://www.npmjs.com/package/vue-eslint-parser)
[![Downloads/month](https://img.shields.io/npm/dm/vue-eslint-parser.svg)](http://www.npmtrends.com/vue-eslint-parser)
[![Build Status](https://github.com/mysticatea/vue-eslint-parser/workflows/CI/badge.svg)](https://github.com/mysticatea/vue-eslint-parser/actions)
[![Coverage Status](https://codecov.io/gh/mysticatea/vue-eslint-parser/branch/master/graph/badge.svg)](https://codecov.io/gh/mysticatea/vue-eslint-parser)
[![Dependency Status](https://david-dm.org/mysticatea/vue-eslint-parser.svg)](https://david-dm.org/mysticatea/vue-eslint-parser)

The ESLint custom parser for `.vue` files.

## ⤴️ Motivation

This parser allows us to lint the `<template>` of `.vue` files. We can make mistakes easily on `<template>` if we use complex directives and expressions in the template. This parser and the rules of [eslint-plugin-vue](https://github.com/vuejs/eslint-plugin-vue) would catch some of the mistakes.

## 💿 Installation

```bash
$ npm install --save-dev eslint vue-eslint-parser
```

- Requires Node.js 6.5.0 or later.
- Requires ESLint 5.0.0 or later.
- Requires `babel-eslint` 8.1.1 or later if you want it. (optional)
- Requires `@typescript-eslint/parser` 1.0.0 or later if you want it. (optional)

## 📖 Usage

1. Write `parser` option into your `.eslintrc.*` file.
2. Use glob patterns or `--ext .vue` CLI option.

```json
{
    "extends": "eslint:recommended",
    "parser": "vue-eslint-parser"
}
```

```console
$ eslint "src/**/*.{js,vue}"
# or
$ eslint src --ext .vue
```

## 🔧 Options

`parserOptions` has the same properties as what [espree](https://github.com/eslint/espree#usage), the default parser of ESLint, is supporting.
For example:

```json
{
    "parser": "vue-eslint-parser",
    "parserOptions": {
        "sourceType": "module",
        "ecmaVersion": 2018,
        "ecmaFeatures": {
            "globalReturn": false,
            "impliedStrict": false,
            "jsx": false
        }
    }
}
```

### parserOptions.parser

You can use `parserOptions.parser` property to specify a custom parser to parse `<script>` tags.
Other properties than parser would be given to the specified parser.
For example:

```json
{
    "parser": "vue-eslint-parser",
    "parserOptions": {
        "parser": "babel-eslint",
        "sourceType": "module",
        "allowImportExportEverywhere": false
    }
}
```

```json
{
    "parser": "vue-eslint-parser",
    "parserOptions": {
        "parser": "@typescript-eslint/parser"
    }
}
```

If the `parserOptions.parser` is `false`, the `vue-eslint-parser` skips parsing `<script>` tags completely.
This is useful for people who use the language ESLint community doesn't provide custom parser implementation.

## 🎇 Usage for custom rules / plugins

- This parser provides `parserServices` to traverse `<template>`.
    - `defineTemplateBodyVisitor(templateVisitor, scriptVisitor)` ... returns ESLint visitor to traverse `<template>`.
    - `getTemplateBodyTokenStore()` ... returns ESLint `TokenStore` to get the tokens of `<template>`.
    - `getDocumentFragment()` ... returns the root `VDocumentFragment`.
- [ast.md](./docs/ast.md) is `<template>` AST specification.
- [mustache-interpolation-spacing.js](https://github.com/vuejs/eslint-plugin-vue/blob/b434ff99d37f35570fa351681e43ba2cf5746db3/lib/rules/mustache-interpolation-spacing.js) is an example.

## ⚠️ Known Limitations

Some rules make warnings due to the outside of `<script>` tags.
Please disable those rules for `.vue` files as necessary.

- [eol-last](http://eslint.org/docs/rules/eol-last)
- [linebreak-style](http://eslint.org/docs/rules/linebreak-style)
- [max-len](http://eslint.org/docs/rules/max-len)
- [max-lines](http://eslint.org/docs/rules/max-lines)
- [no-trailing-spaces](http://eslint.org/docs/rules/no-trailing-spaces)
- [unicode-bom](http://eslint.org/docs/rules/unicode-bom)
- Other rules which are using the source code text instead of AST might be confused as well.

## 📰 Changelog

- [GitHub Releases](https://github.com/mysticatea/vue-eslint-parser/releases)

## 🍻 Contributing

Welcome contributing!

Please use GitHub's Issues/PRs.

If you want to write code, please execute `npm install && npm run setup` after you cloned this repository.
The `npm install` command installs dependencies.
The `npm run setup` command initializes ESLint as git submodules for tests.

### Development Tools

- `npm test` runs tests and measures coverage.
- `npm run build` compiles TypeScript source code to `index.js`, `index.js.map`, and `index.d.ts`.
- `npm run coverage` shows the coverage result of `npm test` command with the default browser.
- `npm run clean` removes the temporary files which are created by `npm test` and `npm run build`.
- `npm run lint` runs ESLint.
- `npm run setup` setups submodules to develop.
- `npm run update-fixtures` updates files in `test/fixtures/ast` directory based on `test/fixtures/ast/*/source.vue` files.
- `npm run watch` runs `build`, `update-fixtures`, and tests with `--watch` option.
