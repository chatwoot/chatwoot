# babel-plugin-polyfill-corejs3

## Install

Using npm:

```sh
npm install --save-dev babel-plugin-polyfill-corejs3
```

or using yarn:

```sh
yarn add babel-plugin-polyfill-corejs3 --dev
```

## Usage

Add this plugin to your Babel configuration:

```json
{
  "plugins": [["polyfill-corejs3", { "method": "usage-global" }]]
}
```

This package supports the `usage-pure`, `usage-global`, and `entry-global` methods.
When `entry-global` is used, it replaces imports to `core-js`.
