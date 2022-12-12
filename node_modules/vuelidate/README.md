# vuelidate
[![codecov](https://codecov.io/gh/vuelidate/vuelidate/branch/master/graph/badge.svg)](https://codecov.io/gh/vuelidate/vuelidate)
![gzip size](http://img.badgesize.io/vuelidate/vuelidate/master/dist/vuelidate.min.js.svg?compression=gzip)

> Simple, lightweight model-based validation for Vue.js

## Sponsors

### Gold

<p align="center">
  <a href="https://vuejs.amsterdam/?utm_source=newsletter&utm_medium=logo&utm_campaign=vuejs-newsletter" target="_blank">
    <img src="https://cdn.discordapp.com/attachments/793583797454503976/793583831369646120/vuejsamsterdam.png" alt="Vuejs Amsterdam" width="380px">
  </a>
</p>
<p align="center">
  <a href="https://theroadtoenterprise.com/?utm_source=newsletter&utm_medium=logo&utm_campaign=vuejs-newsletter" target="_blank">
    <img src="https://cdn.discordapp.com/attachments/793583797454503976/809062891420123166/logo.png" alt="Vue - The Road To Enterprise" width="380px">
  </a>
</p>

### Silver

<p align="center">
  <a href="https://www.storyblok.com/developers?utm_source=newsletter&utm_medium=logo&utm_campaign=vuejs-newsletter" target="_blank">
    <img src="https://a.storyblok.com/f/51376/3856x824/fea44d52a9/colored-full.png" alt="Storyblok" width="240px">
  </a>
</p>

### Bronze

<p align="center">
  <a href="https://www.vuemastery.com/" target="_blank">
    <img src="https://cdn.discordapp.com/attachments/258614093362102272/557267759130607630/Vue-Mastery-Big.png" alt="Vue Mastery logo" width="180px">
  </a>
  <a href="https://vuejobs.com/" target="_blank">
    <img src="https://cdn.discordapp.com/attachments/560524372897562636/636900598700179456/vuejobs-logo.png" alt="Vue Mastery logo" width="140px">
  </a>
</p>

### Features & characteristics:
* Model based
* Decoupled from templates
* Dependency free, minimalistic library
* Support for collection validations
* Support for nested models
* Contextified validators
* Easy to use with custom validators (e.g. Moment.js)
* Support for function composition
* Validates different data sources: Vuex getters, computed values, etc.

## Demo & docs

[https://vuelidate.js.org/](https://vuelidate.js.org/)

## Vue 3 support

Vue 3 support is almost here with the Vuelidate 2 rewrite. Check out the [next](https://github.com/vuelidate/vuelidate/tree/next) branch to see the latest progress.

## Installation

```bash
npm install vuelidate --save
```

You can import the library and use as a Vue plugin to enable the functionality globally on all components containing validation configuration.

```javascript
import Vue from 'vue'
import Vuelidate from 'vuelidate'
Vue.use(Vuelidate)
```

Alternatively it is possible to import a mixin directly to components in which it will be used.

```javascript
import { validationMixin } from 'vuelidate'

var Component = Vue.extend({
  mixins: [validationMixin],
  validations: { ... }
})
```

The browser-ready bundle is also provided in the package.

```html
<script src="vuelidate/dist/vuelidate.min.js"></script>
<!-- The builtin validators is added by adding the following line. -->
<script src="vuelidate/dist/validators.min.js"></script>
```

```javascript
Vue.use(window.vuelidate.default)
```

## Basic usage

For each value you want to validate, you have to create a key inside validations options. You can specify when input becomes dirty by using appropriate event on your input box.

```javascript
import { required, minLength, between } from 'vuelidate/lib/validators'

export default {
  data () {
    return {
      name: '',
      age: 0
    }
  },
  validations: {
    name: {
      required,
      minLength: minLength(4)
    },
    age: {
      between: between(20, 30)
    }
  }
}
```

This will result in a validation object:

```javascript
$v: {
  name: {
    "required": false,
    "minLength": false,
    "$invalid": true,
    "$dirty": false,
    "$error": false,
    "$pending": false
  },
  age: {
    "between": false
    "$invalid": true,
    "$dirty": false,
    "$error": false,
    "$pending": false
  }
}
```

Checkout the docs for more examples: [https://vuelidate.js.org/](https://vuelidate.js.org/)

## Contributing

``` bash
# install dependencies
npm install

# serve with hot reload at localhost:8080
npm run dev

# create UMD bundle.
npm run build

# Create docs inside /gh-pages ready to be published
npm run docs

# run unit tests
npm run unit

# run all tests
npm test
```

For detailed explanation on how things work, checkout the [guide](http://vuejs-templates.github.io/webpack/) and [docs for vue-loader](http://vuejs.github.io/vue-loader).

## Contributors

### Current

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/shentao">
        <img src="https://avatars3.githubusercontent.com/u/3737591?s=460&u=6ef86c71bbbb74efae3c6224390ce9a8cba82272&v=4" width="120px;" alt="Damian Dulisz"/>
        <br />
        <sub><b>Damian Dulisz</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/NataliaTepluhina">
        <img src="https://avatars0.githubusercontent.com/u/18719025?s=460&u=2375ee8b609cb39d681cb318ed138b2f7ffe020e&v=4" width="120px;" alt="Natalia Tepluhina"/>
        <br />
        <sub><b>Natalia Tepluhina</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/dobromir-hristov">
        <img src="https://avatars3.githubusercontent.com/u/9863944?s=460&u=55b074c1589d69d17bb78322dd6900d63b186a34&v=4" width="120px;" alt="Natalia Tepluhina"/>
        <br />
        <sub><b>Dobromir Hristov</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/marina-mosti">
        <img src="https://avatars2.githubusercontent.com/u/14843771?s=460&u=1d11d62c22d38c01d73e6c92587bd567f4e51d27&v=4" width="120px;" alt="Marina Mosti"/>
        <br />
        <sub><b>Marina Mosti</b></sub>
      </a>
    </td>
  </tr>
</table>

### Emeriti

Here we honor past contributors who have been a major part on this project.

- [Monterail](https://github.com/monterail)
- [Paweł Grabarz](https://github.com/Frizi)

## License

[MIT](http://opensource.org/licenses/MIT)
