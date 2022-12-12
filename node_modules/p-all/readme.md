# p-all [![Build Status](https://travis-ci.org/sindresorhus/p-all.svg?branch=master)](https://travis-ci.org/sindresorhus/p-all)

> Run promise-returning & async functions concurrently with optional limited concurrency

Similar to `Promise.all()`, but accepts functions instead of promises directly so you can limit the concurrency.

If you're doing the same work in each function, use [`p-map`](https://github.com/sindresorhus/p-map) instead.

See [`p-series`](https://github.com/sindresorhus/p-series) for a serial counterpart.


## Install

```
$ npm install p-all
```


## Usage

```js
const pAll = require('p-all');
const got = require('got');

(async () => {
	const actions = [
		() => got('https://sindresorhus.com'),
		() => got('https://ava.li'),
		() => checkSomething(),
		() => doSomethingElse()
	];

	console.log(await pAll(actions, {concurrency: 2}));
})();
```


## API

### pAll(tasks, [options])

Returns a `Promise` that is fulfilled when all promises returned from calling the functions in `tasks` are fulfilled, or rejects if any of the promises reject. The fulfilled value is an `Array` of the fulfilled values in `tasks` order.

#### tasks

Type: `Iterable<Function>`

Iterable with promise-returning/async functions.

#### options

Type: `Object`

##### concurrency

Type: `number`<br>
Default: `Infinity`<br>
Minimum: `1`

Number of concurrent pending promises.


## Related

- [p-map](https://github.com/sindresorhus/p-map) - Map over promises concurrently
- [p-series](https://github.com/sindresorhus/p-series) - Run promise-returning & async functions in series
- [p-props](https://github.com/sindresorhus/p-props) - Like `Promise.all()` but for `Map` and `Object`
- [p-queue](https://github.com/sindresorhus/p-queue) - Promise queue with concurrency control
- [p-limit](https://github.com/sindresorhus/p-limit) - Run multiple promise-returning & async functions with limited concurrency
- [More…](https://github.com/sindresorhus/promise-fun)


## License

MIT © [Sindre Sorhus](https://sindresorhus.com)
