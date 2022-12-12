# `babel-plugin-apply-mdx-type-prop`

Babel plugin that applies the `mdxType` prop which is
used by the [MDX](https://mdxjs.com) pragma.

It also stores all components encountered as `names` in
the plugin state.

## Installation

```sh
yarn add babel-plugin-apply-mdx-type-prop
```

## Usage

```js
const babel = require('@babel/core')

const BabelPluginApplyMdxTypeProp = require('babel-plugin-apply-mdx-type-prop')

const jsx = `
export const Foo = () => (
  <div>
    <Button />
  </div>
)

export default () => (
  <>
    <h1>Hello!</h1>
    <TomatoBox />
  </>
)
`

const plugin = new BabelPluginApplyMdxTypeProp()

const result = babel.transform(jsx, {
  configFile: false,
  plugins: ['@babel/plugin-syntax-jsx', plugin.plugin]
})

console.log(result.code)
console.log(plugin.state.names)
```

### Input

```js
export const Foo = () => (
  <div>
    <Button />
  </div>
)

export default () => (
  <>
    <h1>Hello!</h1>
    <TomatoBox />
  </>
)
```

### Output

```js
export const Foo = () => (
  <div>
    <Button mdxType="Button" />
  </div>
)

export default () => (
  <>
    <h1>Hello!</h1>
    <TomatoBox mdxType="Button" />
  </>
)
```

## License

MIT
