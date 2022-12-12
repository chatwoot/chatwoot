# glob-promise [![version][npm-version]][npm-url] [![License][license-image]][license-url] [![Build Status][travis-image]][travis-url] [![Downloads][npm-downloads]][npm-url] [![Coverage Status][codeclimate-coverage]][codeclimate-url]

[`Promise`][Promise] version of [`glob`][glob]

> Match files using the patterns the shell uses, like stars and stuff.

## Install

```bash
# using yarn
$ yarn add glob-promise

# using npm
$ npm install --production --save glob-promise
```

###### NOTE: 

[`glob`][glob] is set as a `peerDependency` in [`package.json`](package.json)

- `npm` <= `2` will automatically install `peerDependencies` if they are not explicitly depended upon higher in the dependency tree.
- `npm` >= 3 will no longer automatically install `peerDependencies`.

You will need to manually add `glob` as a dependency to your project for `glob-promise` to work.

## API

### `glob(pattern [, options])`

Alias for `glob.promise`

### `glob.promise(pattern [, options])`

_pattern_: `String` (glob pattern)
_options_: `Object` or `String`
Return: `Object` ([Promise])

When it finishes, it will be [_fulfilled_](http://promisesaplus.com/#point-26) with an `Array` of filenames as its first argument.

When it fails to read the files, it will be [_rejected_](http://promisesaplus.com/#point-30) with an error as its first argument.

```js
glob('**/*')
  .then(function(contents) {
    contents; //=> ['lorem', 'ipsum', 'dolor']
  });

glob('{foo,bar.baz}.txt', { nobrace: true })
  .then(function(contents) {
    contents; //=> []
  });
```

### `glob.glob(pattern [, options], cb)`

> see [`glob`](https://github.com/isaacs/node-glob#globpattern-options-cb)

### `glob.sync(pattern [, options])`

> see [`glob.sync()`](https://github.com/isaacs/node-glob#globsyncpattern-options)

### `glob.hasMagic(pattern, [options])`

> see [`glob.hasMagic()`](https://github.com/isaacs/node-glob#globhasmagicpattern-options)

### `Class: glob.Glob`

> see [`Glob`](https://github.com/isaacs/node-glob#class-globglob)


#### options

The option object will be directly passed to [glob](https://github.com/isaacs/node-glob#options).

---
> License: [ISC][license-url] &bull; 
> Copyright: [ahmadnassri.com](https://www.ahmadnassri.com) &bull; 
> Github: [@ahmadnassri](https://github.com/ahmadnassri) &bull; 
> Twitter: [@ahmadnassri](https://twitter.com/ahmadnassri)

[license-url]: http://choosealicense.com/licenses/isc/
[license-image]: https://img.shields.io/github/license/ahmadnassri/glob-promise.svg?style=flat-square

[travis-url]: https://travis-ci.org/ahmadnassri/glob-promise
[travis-image]: https://img.shields.io/travis/ahmadnassri/glob-promise.svg?style=flat-square

[npm-url]: https://www.npmjs.com/package/glob-promise
[npm-version]: https://img.shields.io/npm/v/glob-promise.svg?style=flat-square
[npm-downloads]: https://img.shields.io/npm/dm/glob-promise.svg?style=flat-square

[codeclimate-url]: https://codeclimate.com/github/ahmadnassri/glob-promise
[codeclimate-coverage]: https://api.codeclimate.com/v1/badges/0eeee939931b69446450/test_coverage?style=flat-square

[glob]: https://github.com/isaacs/node-glob
[Promise]: http://promisesaplus.com/
