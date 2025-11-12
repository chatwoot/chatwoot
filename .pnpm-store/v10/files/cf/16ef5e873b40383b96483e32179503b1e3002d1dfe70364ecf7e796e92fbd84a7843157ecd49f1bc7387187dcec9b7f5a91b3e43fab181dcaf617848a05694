# camelcase-keys

> Convert object keys to camel case using [`camelcase`](https://github.com/sindresorhus/camelcase)

## Install

```sh
npm install camelcase-keys
```

## Usage

```js
import camelcaseKeys from 'camelcase-keys';

// Convert an object
camelcaseKeys({'foo-bar': true});
//=> {fooBar: true}

// Convert an array of objects
camelcaseKeys([{'foo-bar': true}, {'bar-foo': false}]);
//=> [{fooBar: true}, {barFoo: false}]
```

```js
import {parseArgs} from 'node:util';
import camelcaseKeys from 'camelcase-keys';

const commandLineArguments = parseArgs();
//=> {_: [], 'foo-bar': true}

camelcaseKeys(commandLineArguments);
//=> {_: [], fooBar: true}
```

## API

### camelcaseKeys(input, options?)

#### input

Type: `Record<string, unknown> | ReadonlyArray<Record<string, unknown>>`

A plain object or array of plain objects to camel-case.

#### options

Type: `object`

##### exclude

Type: `Array<string | RegExp>`\
Default: `[]`

Exclude keys from being camel-cased.

##### deep

Type: `boolean`\
Default: `false`

Recurse nested objects and objects in arrays.

```js
import camelcaseKeys from 'camelcase-keys';

const object = {
	'foo-bar': true,
	nested: {
		unicorn_rainbow: true
	}
};

camelcaseKeys(object, {deep: true});
//=> {fooBar: true, nested: {unicornRainbow: true}}

camelcaseKeys(object, {deep: false});
//=> {fooBar: true, nested: {unicorn_rainbow: true}}
```

##### pascalCase

Type: `boolean`\
Default: `false`

Uppercase the first character: `bye-bye` → `ByeBye`

```js
import camelcaseKeys from 'camelcase-keys';

camelcaseKeys({'foo-bar': true}, {pascalCase: true});
//=> {FooBar: true}

camelcaseKeys({'foo-bar': true}, {pascalCase: false});
//=> {fooBar: true}
````

##### preserveConsecutiveUppercase

Type: `boolean`\
Default: `false`

Preserve consecutive uppercase characters: `foo-BAR` → `FooBAR`

```js
import camelcaseKeys from 'camelcase-keys';

camelcaseKeys({'foo-BAR': true}, {preserveConsecutiveUppercase: true});
//=> {fooBAR: true}

camelcaseKeys({'foo-BAR': true}, {preserveConsecutiveUppercase: false});
//=> {fooBar: true}
````

##### stopPaths

Type: `string[]`\
Default: `[]`

Exclude children at the given object paths in dot-notation from being camel-cased.

For example, with an object like `{a: {b: '🦄'}}`, the object path to reach the unicorn is `'a.b'`.

```js
import camelcaseKeys from 'camelcase-keys';

const object = {
	a_b: 1,
	a_c: {
		c_d: 1,
		c_e: {
			e_f: 1
		}
	}
};

camelcaseKeys(object, {
	deep: true,
	stopPaths: [
		'a_c.c_e'
	]
}),
/*
{
	aB: 1,
	aC: {
		cD: 1,
		cE: {
			e_f: 1
		}
	}
}
*/
```

## Related

- [decamelize-keys](https://github.com/sindresorhus/decamelize-keys) - The inverse of this package
- [snakecase-keys](https://github.com/bendrucker/snakecase-keys)
- [kebabcase-keys](https://github.com/mattiloh/kebabcase-keys)
