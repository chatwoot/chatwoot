# stream-to-observable [![Build Status](https://travis-ci.org/SamVerschueren/stream-to-observable.svg?branch=master)](https://travis-ci.org/SamVerschueren/stream-to-observable) [![Coverage Status](https://coveralls.io/repos/github/SamVerschueren/stream-to-observable/badge.svg?branch=master)](https://coveralls.io/github/SamVerschueren/stream-to-observable?branch=master)

> Convert Node Streams into ECMAScript-Observables

[`Observables`](https://github.com/zenparsing/es-observable) are rapidly gaining popularity. They have much in common with Streams, in that they both represent data that arrives over time. Most Observable implementations provide expressive methods for filtering and mutating incoming data. Methods like `.map()`, `.filter()`, and `.forEach` behave very similarly to their Array counterparts, so using Observables can be very intuitive.

[Learn more about Observables](#learn-about-observables)

**Note:** This module was forked from [`stream-to-observable`](https://github.com/jamestalmage/stream-to-observable) and released under a different name due to inactivity.

## Install

```
$ npm install --save @samverschueren/stream-to-observable
```

`stream-to-observable` relies on [`any-observable`](https://github.com/sindresorhus/any-observable), which will search for an available Observable implementation. You need to install one yourself:

  ```
  $ npm install --save zen-observable
  ```

  or

  ```
  $ npm install --save rxjs
  ```

If your code relies on a specific Observable implementation, you should likely specify one using `any-observable`s [registration shortcuts](https://github.com/sindresorhus/any-observable#registration-shortcuts).

## Usage

```js
const fs = require('fs');
const split = require('split');

const streamToObservable = require('@samverschueren/stream-to-observable');

const readStream = fs
  .createReadStream('./hello-world.txt', {encoding: 'utf8'})
  .pipe(split());

streamToObservable(readStream)
  .filter(chunk => /hello/i.test(chunk))
  .map(chunk => chunk.toUpperCase())
  .forEach(chunk => {
    console.log(chunk); // only the lines containing "hello" - and they will be capitalized
  });
```

The [`split`](https://github.com/dominictarr/split) module above will chunk the stream into individual lines. This is often very handy for text streams, as each observable event is guaranteed to be a line.

## API

### streamToObservable(stream, [options])

#### stream

Type: [`ReadableStream`](https://nodejs.org/api/stream.html#stream_class_stream_readable)

*Note:*
`stream` can technically be any [`EventEmitter`](https://nodejs.org/api/events.html#events_class_eventemitter) instance. By default, this module listens to the standard Stream events (`data`, `error`, and `end`), but those are configurable via the `options` parameter. If you are using this with a standard Stream, you likely won't need the `options` parameter.

#### options

##### await

Type: `Promise`

If provided, the Observable will not "complete" until `await` is resolved. If `await` is rejected, the Observable will immediately emit an `error` event and disconnect from the stream. This is mostly useful when attaching to the `stdin` or `stdout` streams of a  [`child_process`](https://nodejs.org/api/child_process.html#child_process_child_stdio). Those streams usually do not emit `error` events, even if the underlying process exits with an error. This provides a means to reject the Observable if the child process exits with an unexpected error code.

##### endEvent

Type: `String` or `false` <br>
Default: `"end"`

If you are using an `EventEmitter` or non-standard Stream, you can change which event signals that the Observable should be completed.

Setting this to `false` will avoid listening for any end events.

Setting this to `false` and providing an `await` Promise will cause the Observable to resolve immediately with the `await` Promise (the Observable will remove all it's `data` event listeners from the stream once the Promise is resolved).

##### errorEvent

Type: `String` or `false` <br>
Default: `"error"`

If you are using an `EventEmitter` or non-standard Stream, you can change which event signals that the Observable should be closed with an error.

Setting this to `false` will avoid listening for any error events.

##### dataEvent

Type: `String`<br>
Default: `"data"`

If you are using an `EventEmitter` or non-standard Stream, you can change which event causes data to be emitted to the Observable.

## Learn about Observables

 - [Overview](https://github.com/zenparsing/es-observable)
 - [Formal Spec](https://github.com/tc39/proposal-observable/)
 - [egghead.io lesson](https://egghead.io/lessons/javascript-introducing-the-observable) - Video
 - [`rxjs` observables](http://reactivex.io/rxjs/class/es6/Observable.js~Observable.html) - Observables implementation
 - [`zen-observables`](https://github.com/zenparsing/zen-observable) - Observables implementation

## Transform Streams

`data` events on the stream will be emitted as events in the Observable. Since most native streams emit `chunks` of binary data, you will likely want to use a `TransformStream` to convert those chunks of binary data into an object stream. [`split`](https://github.com/dominictarr/split) is just one popular TransformStream that splits streams into individual lines of text.

## Caveats

It's important to note that using this module disables back-pressure controls on the stream. As such, it should not be used where back-pressure throttling is required (i.e. high volume web servers). It still has value for larger projects, as it can make unit testing streams much cleaner.

## License

MIT


---

<div align="center">
	<b>
		<a href="https://tidelift.com/subscription/pkg/npm-samverschueren-stream-to-observable?utm_source=npm-samverschueren-stream-to-observable&utm_medium=referral&utm_campaign=enterprise&utm_term=repo">Get professional support for this package with a Tidelift subscription</a>
	</b>
	<br>
	<sub>
		Tidelift helps make open source sustainable for maintainers while giving companies<br>assurances about security, maintenance, and licensing for their dependencies.
	</sub>
</div>
