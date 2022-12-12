# TeleJSON

A library for teleporting rich data to another place.

## Install

```sh
yarn add telejson
```

## What can it do, what can't it do:

`JSON.parse` & `JSON.stringify` have limitation by design, because there are no data formats for things like

- Date
- Function
- Class
- Symbol
- etc.

Also JSON doesn't support cyclic data structures.

This library allows you to pass in data with all all the above properties.
It will transform the properties to something that's allowed by the JSON spec whilst stringifying,
and then convert back to the cyclic data structure when parsing.

When parsing, **class instances** will be given the Class's name again.
The prototype isn't copied over.

**Functions** are supported, they are stringified and will be eval-ed when called.
This lazy eval is important for performance.
The eval happens via `eval()`
Functions are stripped of comments and whitespace.

> Obviously calling the function will only really work as expected if the functions were pure the begin with.

**Regular expressions** just work.

**Symbol** will be re-created with the same string. (resulting in a similar, but different symbol)

**Dates** are parsed back into actual Date objects.

**DOM Events** are processed to extract the internal (hidden) properties, resulting in an object containing the same properties but not being an instance of the original class.

## API

You have 2 choices:

```js
import { stringify, parse } from 'telejson';

const Foo = function () {};

const root = {
  date: new Date('2018'),
  regex1: /foo/,
  regex2: /foo/g,
  regex2: new RegExp('foo', 'i'),
  fn1: () => 'foo',
  fn2: function fn2() {
    return 'foo';
  },
  Foo: new Foo(),
};

// something cyclic
root.root = root;

const stringified = stringify(root);
const parsed = parse(stringified);
```

stringify and parse do not conform to the JSON.stringify or JSON.parse api.
they take an data object and a option object.

OR you can use use the `replacer` and `reviver`:

```js
import { replacer, reviver } from 'telejson';
import data from 'somewhere';

const stringified = JSON.stringify(data, replacer(), 2);
const parsed = JSON.parse(stringified, reviver(), 2);
```

notice that both replacer and reviver need to be called! doing the following will NOT WORK:

```
const stringified = JSON.stringify(data, replacer, 2);
const parsed = JSON.parse(stringified, reviver, 2);
```

## options

You either pass the options-object to `replacer` or as a second argument to `stringify`:

```js
replacer({ maxDepth: 10 });
stringify(date, { maxDepth: 10 });
```

### replacer

`maxDepth`: controls how deep to keep stringifying. When max depth is reach,
objects will be replaced with `"[Object]"`, arrays will be replaced with `"[Array(<length>)]"`.
default value is `10`
This option is really useful if your object is huge/complex, and you don't care about the deeply nested data.

`space`: controls how to prettify the output string.
default value is `undefined`, no white space is used.
Only relevant when using `stringify`.

`allowFunction`: When set to false, functions will not be serialized. (default = true)

`allowRegExp`: When set to false, regular expressions will not be serialized. (default = true)

`allowClass`: When set to false, class instances will not be serialized. (default = true)

`allowDate`: When set to false, Date objects will not be serialized. (default = true)

`allowUndefined`: When set to false, `undefined` will not be serialized. (default = true)

`allowSymbol`: When set to false, Symbols will not be serialized. (default = true)

### reviver

`lazyEval`: When set to false, lazy eval will be disabled. (default true)

Note: disabling lazy eval will affect performance. Consider disabling it only if you truly need to.

## Requirements

`telejson` depends on the collection type `Map`. If you support older browsers and devices which may not yet provide these natively (e.g. IE < 11) or which have non-compliant implementations (e.g. IE 11), consider including a global polyfill in your bundled application, such as `core-js` or `babel-polyfill`.

## Contributing

If you have any suggestions, please open an issue.

All contributions are welcome!

### run tests:

```sh
yarn test
```
