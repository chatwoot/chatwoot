# jsonc-eslint-parser

[![NPM license](https://img.shields.io/npm/l/jsonc-eslint-parser.svg)](https://www.npmjs.com/package/jsonc-eslint-parser)
[![NPM version](https://img.shields.io/npm/v/jsonc-eslint-parser.svg)](https://www.npmjs.com/package/jsonc-eslint-parser)
[![NPM downloads](https://img.shields.io/npm/dw/jsonc-eslint-parser.svg)](http://www.npmtrends.com/jsonc-eslint-parser)
[![NPM downloads](https://img.shields.io/npm/dm/jsonc-eslint-parser.svg)](http://www.npmtrends.com/jsonc-eslint-parser)
[![Build Status](https://github.com/ota-meshi/jsonc-eslint-parser/workflows/CI/badge.svg?branch=master)](https://github.com/ota-meshi/jsonc-eslint-parser/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/github/ota-meshi/jsonc-eslint-parser/badge.svg?branch=master)](https://coveralls.io/github/ota-meshi/jsonc-eslint-parser?branch=master)

## :name_badge: Introduction

[JSON], [JSONC] and [JSON5] parser for use with [ESLint] plugins.

This parser allows us to lint [JSON], [JSONC] and [JSON5] files.
This parser and the rules of [eslint-plugin-jsonc] would catch some of the mistakes and code style violations.

See [eslint-plugin-jsonc] for details.

## :cd: Installation

```bash
npm i --save-dev jsonc-eslint-parser
```

## :book: Usage

In your ESLint configuration file, set the `overrides` > `parser` property:

```json5
{
  // ...
  // Add the following settings.
  "overrides": [
    {
      "files": ["*.json", "*.json5"], // Specify the extension or pattern you want to parse as JSON.
      "parser": "jsonc-eslint-parser", // Set this parser.
    },
  ],
}
```

## :gear: Configuration

The following additional configuration options are available by specifying them in [parserOptions](https://eslint.org/docs/user-guide/configuring#specifying-parser-options-1) in your ESLint configuration file.

```json5
{
  // ...
  "overrides": [
    {
      "files": ["*.json", "*.json5"],
      "parser": "jsonc-eslint-parser",
      // Additional configuration options
      "parserOptions": {
        "jsonSyntax": "JSON5"
      }
    },
  ],
}
```

### `parserOptions.jsonSyntax`

Set to `"JSON"`, `"JSONC"` or `"JSON5"`. Select the JSON syntax you are using.  
If not specified, all syntaxes that express static values ​​are accepted. For example, template literals without interpolation.  

**Note** : Recommended to loosen the syntax checking by the parser and use check rules of [eslint-plugin-jsonc] to automatically fix it.

## Usage for Custom Rules / Plugins

- [AST.md](./docs/AST.md) is AST specification.
- [Plugins.md](./docs/Plugins.md) describes using this in an ESLint plugin.
- [no-template-literals.ts](https://github.com/ota-meshi/eslint-plugin-jsonc/blob/master/lib/rules/no-template-literals.ts) is an example.
- You can see the AST on the [Online DEMO](https://ota-meshi.github.io/jsonc-eslint-parser/).

## :traffic_light: Semantic Versioning Policy

**jsonc-eslint-parser** follows [Semantic Versioning](http://semver.org/).

## :couple: Related Packages

- [eslint-plugin-jsonc](https://github.com/ota-meshi/eslint-plugin-jsonc) ... ESLint plugin for JSON, JSON with comments (JSONC) and JSON5.
- [eslint-plugin-yml](https://github.com/ota-meshi/eslint-plugin-yml) ... ESLint plugin for YAML.
- [eslint-plugin-toml](https://github.com/ota-meshi/eslint-plugin-toml) ... ESLint plugin for TOML.
- [eslint-plugin-json-schema-validator](https://github.com/ota-meshi/eslint-plugin-json-schema-validator) ... ESLint plugin that validates data using JSON Schema Validator.
- [yaml-eslint-parser](https://github.com/ota-meshi/yaml-eslint-parser) ... YAML parser for use with ESLint plugins.
- [toml-eslint-parser](https://github.com/ota-meshi/toml-eslint-parser) ... TOML parser for use with ESLint plugins.

## :lock: License

See the [LICENSE](LICENSE) file for license rights and limitations (MIT).

[JSON]: https://json.org/
[JSONC]: https://github.com/microsoft/node-jsonc-parser
[JSON5]: https://json5.org/
[ESLint]: https://eslint.org/
[eslint-plugin-jsonc]: https://www.npmjs.com/package/eslint-plugin-jsonc
