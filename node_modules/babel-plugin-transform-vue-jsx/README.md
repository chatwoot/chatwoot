# babel-plugin-transform-vue-jsx [![CircleCI](https://img.shields.io/circleci/project/vuejs/babel-plugin-transform-vue-jsx.svg?maxAge=2592000)](https://circleci.com/gh/vuejs/babel-plugin-transform-vue-jsx)

> Babel plugin for Vue 2.0 JSX

### Requirements

- Assumes you are using Babel with a module bundler e.g. Webpack, because the spread merge helper is imported as a module to avoid duplication.

- This is mutually exclusive with `babel-plugin-transform-react-jsx`.

### Usage

``` bash
npm install\
  babel-plugin-syntax-jsx\
  babel-plugin-transform-vue-jsx\
  babel-helper-vue-jsx-merge-props\
  babel-preset-env\
  --save-dev
```

In your `.babelrc`:

``` json
{
  "presets": ["env"],
  "plugins": ["transform-vue-jsx"]
}
```

The plugin transpiles the following JSX:

``` jsx
<div id="foo">{this.text}</div>
```

To the following JavaScript:

``` js
h('div', {
  attrs: {
    id: 'foo'
  }
}, [this.text])
```

Note the `h` function, which is a shorthand for a Vue instance's `$createElement` method, must be in the scope where the JSX is. Since this method is passed to component render functions as the first argument, in most cases you'd do this:

``` js
Vue.component('jsx-example', {
  render (h) { // <-- h must be in scope
    return <div id="foo">bar</div>
  }
})
```

### `h` auto-injection

Starting with version 3.4.0 we automatically inject `const h = this.$createElement` in any method and getter (not functions or arrow functions) declared in ES2015 syntax that has JSX so you can drop the `(h)` parameter.

``` js

Vue.component('jsx-example', {
  render () { // h will be injected
    return <div id="foo">bar</div>
  },
  myMethod: function () { // h will not be injected
    return <div id="foo">bar</div>
  },
  someOtherMethod: () => { // h will not be injected
    return <div id="foo">bar</div>
  }
})

@Component
class App extends Vue {
  get computed () { // h will be injected
    return <div id="foo">bar</div>
  }
}
```

### Difference from React JSX

First, Vue 2.0's vnode format is different from React's. The second argument to the `createElement` call is a "data object" that accepts nested objects. Each nested object will be then processed by corresponding modules:

``` js
render (h) {
  return h('div', {
    // Component props
    props: {
      msg: 'hi'
    },
    // normal HTML attributes
    attrs: {
      id: 'foo'
    },
    // DOM props
    domProps: {
      innerHTML: 'bar'
    },
    // Event handlers are nested under "on", though
    // modifiers such as in v-on:keyup.enter are not
    // supported. You'll have to manually check the
    // keyCode in the handler instead.
    on: {
      click: this.clickHandler
    },
    // For components only. Allows you to listen to
    // native events, rather than events emitted from
    // the component using vm.$emit.
    nativeOn: {
      click: this.nativeClickHandler
    },
    // class is a special module, same API as `v-bind:class`
    class: {
      foo: true,
      bar: false
    },
    // style is also same as `v-bind:style`
    style: {
      color: 'red',
      fontSize: '14px'
    },
    // other special top-level properties
    key: 'key',
    ref: 'ref',
    // assign the `ref` is used on elements/components with v-for
    refInFor: true,
    slot: 'slot'
  })
}
```

The equivalent of the above in Vue 2.0 JSX is:

``` jsx
render (h) {
  return (
    <div
      // normal attributes or component props.
      id="foo"
      // DOM properties are prefixed with `domProps`
      domPropsInnerHTML="bar"
      // event listeners are prefixed with `on` or `nativeOn`
      onClick={this.clickHandler}
      nativeOnClick={this.nativeClickHandler}
      // other special top-level properties
      class={{ foo: true, bar: false }}
      style={{ color: 'red', fontSize: '14px' }}
      key="key"
      ref="ref"
      // assign the `ref` is used on elements/components with v-for
      refInFor
      slot="slot">
    </div>
  )
}
```

### Component Tip

If a custom element starts with lowercase, it will be treated as a string id and used to lookup a registered component. If it starts with uppercase, it will be treated as an identifier, which allows you to do:

``` js
import Todo from './Todo.js'

export default {
  render (h) {
    return <Todo/> // no need to register Todo via components option
  }
}
```

### JSX Spread

JSX spread is supported, and this plugin will intelligently merge nested data properties. For example:

``` jsx
const data = {
  class: ['b', 'c']
}
const vnode = <div class="a" {...data}/>
```

The merged data will be:

``` js
{ class: ['a', 'b', 'c'] }
```

### Vue directives

Note that almost all built-in Vue directives are not supported when using JSX, the sole exception being `v-show`, which can be used with the `v-show={value}` syntax. In most cases there are obvious programmatic equivalents, for example `v-if` is just a ternary expression, and `v-for` is just an `array.map()` expression, etc.

For custom directives, you can use the `v-name={value}` syntax. However, note that directive arguments and modifiers are not supported using this syntax. There are two workarounds:

1. Pass everything as an object via `value`, e.g. `v-name={{ value, modifier: true }}`

2. Use the raw vnode directive data format:

``` js
const directives = [
  { name: 'my-dir', value: 123, modifiers: { abc: true } }
]

return <div {...{ directives }}/>
```
