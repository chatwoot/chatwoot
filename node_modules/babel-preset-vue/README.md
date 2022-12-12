# babel-preset-vue

Babel preset for all Vue plugins.

## Install

```bash
npm install -D babel-preset-vue
```

CDN: [UNPKG](https://unpkg.com/babel-preset-vue/)

## Usage

In your `.babelrc`:

```json
{
  "presets": ["vue"]
}
```

You can toggle specific features, by default all features are enabled, e.g.:

```json
{
  "presets": [
    ["vue", {
      "eventModifiers": false
    }]
  ]
}
```


## JSX Features

> Note that following features are not available for babel v7 currently, you may disable them if necessary.

### Event modifiers

Option name: `eventModifiers`

Uses [`babel-plugin-jsx-event-modifier`](https://github.com/nickmessing/babel-plugin-jsx-event-modifiers) for adding event modifiers support.

Example:
```js
Vue.component('hello-world', {
  methods: {
    method () {
      console.log('clicked')
    }
  },
  render () {
    return (
      <div>
        <a href="/" onClick:prevent={this.method} />
      </div>
    )
  }
})
```

### v-model

Options name: `vModel`

Uses [`babel-plugin-jsx-v-model`](https://github.com/nickmessing/babel-plugin-jsx-v-model) for adding `v-model` support.

Example:

```js
Vue.component('hello-world', {
  data: () => ({
    text: 'Hello World!'
  }),
  render () {
    return (
      <div>
        <input type="text" v-model={this.text} />
        {this.text}
      </div>
    )
  }
})
```

## License

MIT &copy; [EGOIST](https://github.com/egoist)
