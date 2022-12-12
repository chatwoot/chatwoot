# `babel-plugin-extract-import-names`

Babel plugin that extracts all variable names from
import statements. Used by the [MDX](https://mdxjs.com)
pragma.

## Installation

```sh
yarn add babel-plugin-extract-import-names
```

## Usage

```js
const babel = require('@babel/core')

const BabelPluginExtractImportNames = require('babel-plugin-extract-import-names')

const jsx = `
import Foo from 'bar'
import { Bar } from 'baz'
`

const plugin = new BabelPluginExtractImportNames()

const result = babel.transform(jsx, {
  configFile: false,
  plugins: [plugin.plugin]
})

console.log(plugin.state.names)
```

## License

MIT
