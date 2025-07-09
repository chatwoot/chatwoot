# vuelidate

> Simple, lightweight model-based validation for Vue.js 2.x & 3.0

Visit [Vuelidate Docs](https://vuelidate-next.netlify.app) for detailed instructions.

## Sponsors

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
</p>

## Installation

You can use Vuelidate just by itself, but we suggest you use it along `@vuelidate/validators`, as it gives a nice collection of commonly used
validators.

**Vuelidate supports both Vue 3.0 and Vue 2.x**

```bash
npm install @vuelidate/core @vuelidate/validators
# or
yarn add @vuelidate/core @vuelidate/validators
```

## Usage with Options API

To use Vuelidate with the Options API, you just need to return an empty Vuelidate instance from `setup`.

Your validation state lives in the `data` and the rules are in `validations` function.

```js
import { email, required } from '@vuelidate/validators'
import { useVuelidate } from '@vuelidate/core'

export default {
  name: 'UsersPage',
  data: () => ({
    form: {
      name: '',
      email: ''
    }
  }),
  setup: () => ({ v$: useVuelidate() }),
  validations () {
    return {
      form: {
        name: { required },
        email: { required, email }
      }
    }
  }
}
```

## Usage with Composition API

To use Vuelidate with the Composition API, you need to provide it a state and set of validation rules, for that state.

The state can be a `reactive` object or a collection of `refs`.

```js
import { reactive } from 'vue' // or '@vue/composition-api' in Vue 2.x
import { useVuelidate } from '@vuelidate/core'
import { email, required } from '@vuelidate/validators'

export default {
  setup () {
    const state = reactive({
      name: '',
      emailAddress: ''
    })
    const rules = {
      name: { required },
      emailAddress: { required, email }
    }

    const v$ = useVuelidate(rules, state)

    return { state, v$ }
  }
}
```

## Providing global config to your Vuelidate instance

You can provide global configs to your Vuelidate instance using the third parameter of `useVuelidate` or by using the `validationsConfig`. These
config options are used to change some core Vuelidate functionality, like `$autoDirty`, `$lazy`, `$scope` and more. Learn all about them
in [Validation Configuration](https://vuelidate-next.netlify.app/api.html#validation-configuration).

### Config with Options API

```vue
<script>
import { useVuelidate } from '@vuelidate/core'

export default {
  data () {
    return { ...state }
  },
  validations () {
    return { ...validations }
  },
  setup: () => ({ v$: useVuelidate() }),
  validationConfig: {
    $lazy: true,
  }
}
</script>
```

### Config with Composition API

```js
import { reactive } from 'vue' // or '@vue/composition-api' in Vue 2.x
import { useVuelidate } from '@vuelidate/core'
import { email, required } from '@vuelidate/validators'

export default {
  setup () {
    const state = reactive({})
    const rules = {}
    const v$ = useVuelidate(rules, state, { $lazy: true })

    return { state, v$ }
  }
}
```

## The validation object, aka `v$` object

```ts
interface ValidationState {
  $dirty: false, // validations will only run when $dirty is true
  $touch: Function, // call to turn the $dirty state to true
  $reset: Function, // call to turn the $dirty state to false
  $errors: [], // contains all the current errors { $message, $params, $pending, $invalid }
  $error: false, // true if validations have not passed
  $invalid: false, // as above for compatibility reasons
  // there are some other properties here, read the docs for more info
}
```

## Validations rules are on by default

Validation in Vuelidate 2 is by default on, meaning validators are called on initialisation, but an error is considered active, only after a field is dirty, so after `$touch()` is called or by using `$model`.

If you wish to make a validation lazy, meaning it only runs validations once it a field is dirty, you can pass a `{ $lazy: true }` property to
Vuelidate. This saves extra invocations for async validators as well as makes the initial validation setup a bit more performant.

```js
const v = useVuelidate(rules, state, { $lazy: true })
```

### Resetting dirty state

If you wish to reset a form's `$dirty` state, you can do so by using the appropriately named `$reset` method. For example when closing a create/edit
modal, you dont want the validation state to persist.

```vue

<app-modal @closed="v$.$reset()">
<!-- some inputs  -->
</app-modal>
```

## Displaying error messages

The validation state holds useful data, like the invalid state of each property validator, along with extra properties, like an error message or extra
parameters.

Error messages come out of the box with the bundled validators in `@vuelidate/validators` package. You can check how change those them over at
the [Custom Validators page](https://vuelidate-next.netlify.app/custom_validators.html)

The easiest way to display errors is to use the form's top level `$errors` property. It is an array of validation objects, that you can iterate over.

```vue

<p
  v-for="(error, index) of $v.$errors"
  :key="index"
>
<strong>{{ error.$validator }}</strong>
<small> on property</small>
<strong>{{ error.$property }}</strong>
<small> says:</small>
<strong>{{ error.$message }}</strong>
</p>
```

You can also check for errors on each form property:

```vue
<p
  v-for="(error, index) of $v.name.$errors"
  :key="index"
>
<!-- Same as above -->
</p>
```

For more info, visit the [Vuelidate Docs](https://vuelidate-next.netlify.org).

## Development

To test the package run

``` bash
# install dependencies
yarn install

# create bundles.
yarn build

# Create docs inside /docs package
yarn dev

# run unit tests for entire monorepo
yarn test:unit

# You can also run for same command per package
```
