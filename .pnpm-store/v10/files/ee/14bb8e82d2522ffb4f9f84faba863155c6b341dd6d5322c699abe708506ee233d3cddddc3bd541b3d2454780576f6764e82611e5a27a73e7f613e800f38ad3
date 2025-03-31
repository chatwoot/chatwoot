# Vuelidate Validators

This is the standalone validators package for [Vuelidate](https://github.com/vuelidate/vuelidate).

## Installation

You need to install both this package and Vuelidate.

```bash
npm install @vuelidate/core @vuelidate/validators
```
or with yarn
```bash
yarn add @vuelidate/core @vuelidate/validators
```

## Usage

After adding the Vuelidate plugin, you can use the validators by importing them directly.
These validators come with error messages out of the box.

```js
import { required, email } from '@vuelidate/validators'

export default {
  data: () => ({
    name: '',
    email: ''
  }),
  validations: {
    name: { required },
    email: { required, email }
  }
}
```

### Raw, no message validators

If you want to use validators without error messages, you can import the raw validators.

```js
import { required, email } from '@vuelidate/validators/dist/raw.esm'
```

### Extending a validator with custom message

You can attach a validation message to a validator via tha `withMessage` method.

```js
import { common, required } from '@vuelidate/validators'

const requiredWithMessage = common.withMessage(required, 'This field is required and must be filled in')

export default {
  ...,
  validations: {
    name: { requiredWithMessage }
  }
}
```

### Attaching extra data to a validator

If you want to attach extra data properties to validator, so you can use them in the messages and when validating, use the `withParams` helper.

```js
import { common } from '@vuelidate/validators'

const atLeast = (number) => common.withParams({ number }, (value) => value.length <= number) // just an example

export default {
  ...,
  validations: {
    name: { atLeast: atLeast(5) }
  }
}
```

### Combining params and messages

You can combine both helpers to build a validator.

```js
import { common } from '@vuelidate/validators'

const customMinLength = (number) => common.withMessage((value) => value.length <= number, ({ $params }) => `The field must be at least ${$params.number} chars long`)
const atLeast = (number) => common.withParams({ number }, customMinLength(number)) // just an example

export default {
  ...,
  validations: {
    name: { atLeast: atLeast(5) }
  }
}
```

## Development
To test the package run

```bash
yarn test:unit
```

To link the package run

```bash
yarn link
```

To build run the package, run: 

```bash
npm run build
```
