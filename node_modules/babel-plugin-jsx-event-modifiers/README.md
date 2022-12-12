## Event Modifiers for JSX

This babel plugin adds some syntactic sugar to JSX.

### Usage:

```bash
npm i babel-plugin-jsx-event-modifiers -D
```
or
```bash
yarn add babel-plugin-jsx-event-modifiers -D
```

Then add `jsx-event-modifiers` to your `.babelrc` file under `plugins`

example .babelrc:
```json
{
  "presets": ["es2015"],
  "plugins": ["jsx-event-modifiers", "transform-vue-jsx"]
}
```

#### Event Modifiers

Example:
```js
export default {
  render () {
    return (
      <input
        onKeyup:up={this.methodForPressingUp}
        onKeyup:down={this.methodForPressingDown}
        onKeyup:bare-shift-enter={this.methodOnlyOnShiftEnter}
        onKeyup:bare-alt-enter={this.methodOnlyOnAltEnter}
      />
    )
  }
}
```
will be transpiled into:
```js
export default {
  render() {
    return (
      <input
        {...{
          on: {
            keyup: [
              $event => {
                if (!('button' in $event) && this._k($event.keyCode, 'up', 38)) return null

                this.methodForPressingUp($event)
              },
              $event => {
                if (!('button' in $event) && this._k($event.keyCode, 'down', 40)) return null

                this.methodForPressingDown($event)
              },
              $event => {
                if (
                  ($event.ctrlKey && $event.altKey && $event.metaKey) ||
                  !$event.shiftKey ||
                  (!('button' in $event) && this._k($event.keyCode, 'enter', 13))
                )
                  return null

                this.methodOnlyOnShiftEnter($event)
              },
              $event => {
                if (
                  ($event.ctrlKey && $event.shiftKey && $event.metaKey) ||
                  !$event.altKey ||
                  (!('button' in $event) && this._k($event.keyCode, 'enter', 13))
                )
                  return null

                this.methodOnlyOnAltEnter($event)
              },
            ],
          },
        }}
      />
    )
  },
}


```

#### We try to keep API and behaviour as close to [Vue Event Modifiers](https://vuejs.org/v2/guide/events.html#Event-Modifiers) as we can. The only difference today is support for [bare](https://github.com/vuejs/vue/pull/5977) modifier and syntax.

##### Example:

Vue template:
```html
<input
  @keyup.up="methodForPressingUp"
  @keyup.down="methodForPressingDown"
  @keyup.bare.shift.enter="methodOnlyOnShiftEnter"
  @keyup.bare.alt.enter="methodOnlyOnAltEnter"
  @keyup.120="onPressKey120('some', 'arguments')"
>
```
JSX:
```js
<input
  onKeyup:up={this.methodForPressingUp}
  onKeyup:down={this.methodForPressingDown}
  onKeyup:bare-shift-enter={this.methodOnlyOnShiftEnter}
  onKeyup:bare-alt-enter={this.methodOnlyOnAltEnter}
  onKeyup:k120={() => this.onPressKey120('some', 'arguments')}
/>
```

##### Notable differences:

 * Modifiers are prefixed by `:` and separated by `-` (in vue: prefixed by `.` and separated by `.`)
 * Key codes are prefixed by `k`
 * Call expression should be wrapped in arrow functions
