# any-observable [![Build Status](https://travis-ci.org/sindresorhus/any-observable.svg?branch=master)](https://travis-ci.org/sindresorhus/any-observable)

> Support any [Observable](https://github.com/zenparsing/es-observable) library and polyfill

Like [`any-promise`](https://github.com/kevinbeaty/any-promise). *(Docs are lacking here, so refer to those docs for now)*


## Install

```
$ npm install any-observable
```

You must also install the Observable library you want:

```
$ npm install zen-observable
```


## Usage

```js
const Observable = require('any-observable'); // Using `zen-observable` since it's installed

Observable.of(1, 2).forEach(x => console.log(x));
//=> 1
//=> 2
```

## Registration Shortcuts

This adds the following shortcut registrations:

- `rxjs-min`: Bare bones [RxJs](https://github.com/ReactiveX/rxjs) Observable implementation. See the [RxJs Installation Instructions](http://reactivex.io/rxjs/manual/installation.html) for details on patching additional methods into that implementation.
- `rxjs`: Same as `rxjs-min`, but adds the somewhat standard `Observable.of` and `Observable.from`.
- `rxjs-all`: The kitchen sink approach to Observables.
- `zen`: The [`zen-observable`](https://github.com/zenparsing/zen-observable) implementation.

Shortcut registration can be done as follows:

```js
import 'any-observable/register/zen';
```

It's especially handy for more recent versions of Node.js (and many test runners), that offer a `--require` flag:

```
$ ava --require=any-observable/register/zen test.js
```


## Related

- [is-observable](https://github.com/sindresorhus/is-observable) - Check if a value is an Observable
- [observable-to-promise](https://github.com/sindresorhus/observable-to-promise) - Convert an Observable to a Promise


## License

MIT © [Sindre Sorhus](https://sindresorhus.com)
