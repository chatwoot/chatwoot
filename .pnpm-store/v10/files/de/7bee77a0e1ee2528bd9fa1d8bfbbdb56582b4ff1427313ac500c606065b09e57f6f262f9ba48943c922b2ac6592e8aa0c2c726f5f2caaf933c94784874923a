# yaml-eslint-parser

A YAML parser that produces output [compatible with ESLint](https://eslint.org/docs/developer-guide/working-with-custom-parsers#all-nodes).

_This parser is backed by excellent [yaml](https://github.com/eemeli/yaml) package and it is heavily inspired by [yaml-unist-parser](https://github.com/ikatyang/yaml-unist-parser) package._

[![NPM license](https://img.shields.io/npm/l/yaml-eslint-parser.svg)](https://www.npmjs.com/package/yaml-eslint-parser)
[![NPM version](https://img.shields.io/npm/v/yaml-eslint-parser.svg)](https://www.npmjs.com/package/yaml-eslint-parser)
[![NPM downloads](https://img.shields.io/badge/dynamic/json.svg?label=downloads&colorB=green&suffix=/day&query=$.downloads&uri=https://api.npmjs.org//downloads/point/last-day/yaml-eslint-parser&maxAge=3600)](http://www.npmtrends.com/yaml-eslint-parser)
[![NPM downloads](https://img.shields.io/npm/dw/yaml-eslint-parser.svg)](http://www.npmtrends.com/yaml-eslint-parser)
[![NPM downloads](https://img.shields.io/npm/dm/yaml-eslint-parser.svg)](http://www.npmtrends.com/yaml-eslint-parser)
[![NPM downloads](https://img.shields.io/npm/dy/yaml-eslint-parser.svg)](http://www.npmtrends.com/yaml-eslint-parser)
[![NPM downloads](https://img.shields.io/npm/dt/yaml-eslint-parser.svg)](http://www.npmtrends.com/yaml-eslint-parser)
[![Build Status](https://github.com/ota-meshi/yaml-eslint-parser/workflows/CI/badge.svg?branch=master)](https://github.com/ota-meshi/yaml-eslint-parser/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/github/ota-meshi/yaml-eslint-parser/badge.svg?branch=master)](https://coveralls.io/github/ota-meshi/yaml-eslint-parser?branch=master)

## Installation

```bash
npm install --save-dev yaml-eslint-parser
```

## Usage

### Configuration

Use `.eslintrc.*` file to configure parser. See also: [https://eslint.org/docs/user-guide/configuring](https://eslint.org/docs/user-guide/configuring).

Example **.eslintrc.js**:

```js
module.exports = {
  overrides: [
    {
      files: ["*.yaml", "*.yml"],
      parser: "yaml-eslint-parser",
    },
  ],
};
```

### Advanced Configuration

The following additional configuration options are available by specifying them in [parserOptions](https://eslint.org/docs/latest/user-guide/configuring/language-options#specifying-parser-options) in your ESLint configuration file.

Example **.eslintrc.js**:

```js
module.exports = {
  overrides: [
    {
      files: ["*.yaml", "*.yml"],
      parser: "yaml-eslint-parser",
      // Additional configuration options
      parserOptions: {
        defaultYAMLVersion: "1.2",
      },
    },
  ],
};
```

#### `parserOptions.defaultYAMLVersion`

Set to `"1.2"` or `"1.1"`. Select the YAML version used by documents without a `%YAML` directive.  
If not specified, the [yaml](https://eemeli.org/yaml/)'s default `version` option (`"1.2"`) is used.  
See <https://eemeli.org/yaml/#document-options> for details.

## Usage for Custom Rules / Plugins

- [AST.md](./docs/AST.md) is AST specification.
- [block-mapping.ts](https://github.com/ota-meshi/eslint-plugin-yml/blob/master/src/rules/block-mapping.ts) is an example.
- You can see the AST on the [Online DEMO](https://ota-meshi.github.io/yaml-eslint-parser/).

## Usage for Directly

Example:

```ts
import type { AST } from "yaml-eslint-parser";
import { parseYAML, getStaticYAMLValue } from "yaml-eslint-parser";

const code = `
american:
  - Boston Red Sox
  - Detroit Tigers
  - New York Yankees
national:
  - New York Mets
  - Chicago Cubs
  - Atlanta Braves
`;

const ast: AST.YAMLProgram = parseYAML(code);
console.log(ast);

const value = getStaticYAMLValue(ast);
console.log(value);
```

## Related Packages

- [eslint-plugin-jsonc](https://github.com/ota-meshi/eslint-plugin-jsonc) ... ESLint plugin for JSON, JSON with comments (JSONC) and JSON5.
- [eslint-plugin-yml](https://github.com/ota-meshi/eslint-plugin-yml) ... ESLint plugin for YAML.
- [eslint-plugin-toml](https://github.com/ota-meshi/eslint-plugin-toml) ... ESLint plugin for TOML.
- [eslint-plugin-json-schema-validator](https://github.com/ota-meshi/eslint-plugin-json-schema-validator) ... ESLint plugin that validates data using JSON Schema Validator.
- [jsonc-eslint-parser](https://github.com/ota-meshi/jsonc-eslint-parser) ... JSON, JSONC and JSON5 parser for use with ESLint plugins.
- [toml-eslint-parser](https://github.com/ota-meshi/toml-eslint-parser) ... TOML parser for use with ESLint plugins.
