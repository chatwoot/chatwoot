# Nano ID

<img src="https://ai.github.io/nanoid/logo.svg" align="right"
     alt="Nano ID logo by Anton Lovchikov" width="180" height="94">

A tiny, secure, URL-friendly, unique string ID generator for JavaScript.

* **Small.** 119 bytes (minified and gzipped). No dependencies.
  [Size Limit] controls the size.
* **Safe.** It uses cryptographically strong random APIs.
  Can be used in clusters.
* **Fast.** It’s 16% faster than UUID.
* **Compact.** It uses a larger alphabet than UUID (`A-Za-z0-9_-`).
  So ID size was reduced from 36 to 21 symbols.

```js
const nanoid = require('nanoid')
model.id = nanoid() //=> "V1StGXR8_Z5jdHi6B-myT"
```

Supports [all browsers], Node.js and React Native.

[all browsers]: http://caniuse.com/#feat=getrandomvalues
[Size Limit]:   https://github.com/ai/size-limit

<a href="https://evilmartians.com/?utm_source=nanoid">
  <img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg"
       alt="Sponsored by Evil Martians" width="236" height="54">
</a>

## Table of Contents

1. [Comparison with UUID](#comparison-with-uuid)
2. [Benchmark](#benchmark)
4. [Tools](#tools)
3. [Security](#security)
6. Usage
   1. [JS](#js)
   2. [React](#react)
   3. [React Native](#react-native)
   4. [Web Workers](#web-workers)
   5. [PouchDB and CouchDB](#pouchdb-and-couchdb)
   5. [Mongoose](#mongoose)
   6. [Other Programming Languages](#other-programming-languages)
7. API
   1. [Async](#async)
   2. [Non-Secure](#non-secure)
   3. [Custom Alphabet or Length](#custom-alphabet-or-length)
   4. [Custom Random Bytes Generator](#custom-random-bytes-generator)


## Comparison with UUID

Nano ID is quite comparable to UUID v4 (random-based).
It has a similar number of random bits in the ID
(126 in Nano ID and 122 in UUID), so it has a similar collision probability:

> For there to be a one in a billion chance of duplication,
> 103 trillion version 4 IDs must be generated.

There are three main differences between Nano ID and UUID v4:

1. Nano ID uses a bigger alphabet, so a similar number of random bits
   are packed in just 21 symbols instead of 36.
2. Nano ID code is 4 times less than `uuid/v4` package:
   119 bytes instead of 435.
3. Because of memory allocation tricks, Nano ID is 16% faster than UUID.


## Benchmark

```rust
$ ./test/benchmark
nanoid                    693,132 ops/sec
nanoid/generate           624,291 ops/sec
uid.sync                  487,706 ops/sec
uuid/v4                   471,299 ops/sec
secure-random-string      448,386 ops/sec
shortid                    66,809 ops/sec

Async:
nanoid/async              105,024 ops/sec
nanoid/async/generate     106,682 ops/sec
secure-random-string       94,217 ops/sec
uid                        92,026 ops/sec

Non-secure:
nanoid/non-secure       2,555,814 ops/sec
rndm                    2,413,565 ops/sec
```


## Tools

* [ID size calculator] to choice smaller ID size depends on your case.
* [`nanoid-dictionary`] with popular alphabets to use with `nanoid/generate`.
* [`nanoid-cli`] to generate ID from CLI.
* [`nanoid-good`] to be sure that your ID doesn't contain any obscene words.

[`nanoid-dictionary`]: https://github.com/CyberAP/nanoid-dictionary
[ID size calculator]:  https://zelark.github.io/nano-id-cc/
[`nanoid-cli`]:        https://github.com/twhitbeck/nanoid-cli
[`nanoid-good`]:       https://github.com/y-gagar1n/nanoid-good


## Security

*See a good article about random generators theory:
[Secure random values (in Node.js)]*


### Unpredictability

Instead of using the unsafe `Math.random()`, Nano ID uses the `crypto` module
in Node.js and the Web Crypto API in browsers. These modules use unpredictable
hardware random generator.


### Uniformity

`random % alphabet` is a popular mistake to make when coding an ID generator.
The spread will not be even; there will be a lower chance for some symbols
to appear compared to others—so it will reduce the number of tries
when brute-forcing.

Nano ID uses a [better algorithm] and is tested for uniformity.

<img src="img/distribution.png" alt="Nano ID uniformity"
     width="340" height="135">

[Secure random values (in Node.js)]: https://gist.github.com/joepie91/7105003c3b26e65efcea63f3db82dfba
[better algorithm]: https://github.com/ai/nanoid/blob/master/format.js


### Vulnerabilities

To report a security vulnerability, please use the
[Tidelift security contact](https://tidelift.com/security).
Tidelift will coordinate the fix and disclosure.


## Usage

### JS

The main module uses URL-friendly symbols (`A-Za-z0-9_-`) and returns an ID
with 21 characters (to have a collision probability similar to UUID v4).

```js
const nanoid = require('nanoid')
model.id = nanoid() //=> "Uakgb_J5m9g-0JDMbcJqLJ"
```

If you want to reduce ID length (and increase collisions probability),
you can pass the length as an argument.

```js
nanoid(10) //=> "IRFa-VaY2b"
```

Don’t forget to check the safety of your ID length
in our [ID collision probability] calculator.

You can also use [custom alphabet](#custom-alphabet-or-length)
or [random generator](#custom-random-bytes-generator).

[ID collision probability]: https://zelark.github.io/nano-id-cc/


### React

**Do not** use a nanoid for `key` prop. In React `key` should be consistence
between renders. This is bad code:

```jsx
<Item key={nanoid()} /> /* DON’T DO IT */
```

This is good code. `id` will be generated only once:

```jsx
const Element = () => {
  const [id] = React.useState(nanoid)
  return <Item key={id}>
}
```

If you want to use Nano ID for `id`, you must to set some string prefix.
Nano ID could be started from number. HTML ID can’t be started from the number.

```jsx
<input id={'id' + this.id} type="text"/>
```


### React Native

React Native doesn’t have built-in random generator.

1. Check [`expo-random`] docs and install it.
2. Use `nanoid/async` instead of synchronous `nanoid`.

```js
const nanoid = require('nanoid/async')

async function createUser () {
  user.id = await nanoid()
}
```


### PouchDB and CouchDB

In PouchDB and CouchDB, IDs can’t start with an underscore `_`.
A prefix is required to prevent this issue, as Nano ID might use a `_`
at the start of the ID by default.

Override the default ID with the following option:

```js
db.put({
  _id: 'id' + nanoid(),
  …
})
```


### Mongoose

```js
const mySchema = new Schema({
  _id: {
    type: String,
    default: () => nanoid()
  }
})
```


### Web Workers

Web Workers don’t have access to a secure random generator.

Security is important in IDs, when IDs should be unpredictable. For instance,
in “access by URL” link generation.

If you don’t need unpredictable IDs, but you need Web Workers support,
you can use non‑secure ID generator. Note, that they have bigger collision
probability.

```js
const nanoid = require('nanoid/non-secure')
nanoid() //=> "Uakgb_J5m9g-0JDMbcJqLJ"
```


### Other Programming Languages

Nano ID was ported to many languages. You can use these ports to have the same
ID generators on client and server side.

* [C#](https://github.com/codeyu/nanoid-net)
* [Clojure and ClojureScript](https://github.com/zelark/nano-id)
* [Crystal](https://github.com/mamantoha/nanoid.cr)
* [Dart](https://github.com/pd4d10/nanoid-dart)
* [Go](https://github.com/matoous/go-nanoid)
* [Elixir](https://github.com/railsmechanic/nanoid)
* [Haskell](https://github.com/4e6/nanoid-hs)
* [Java](https://github.com/aventrix/jnanoid)
* [Nim](https://github.com/icyphox/nanoid.nim)
* [PHP](https://github.com/hidehalo/nanoid-php)
* [Python](https://github.com/puyuan/py-nanoid) with [dictionaries](https://pypi.org/project/nanoid-dictionary)
* [Ruby](https://github.com/radeno/nanoid.rb)
* [Rust](https://github.com/nikolay-govorov/nanoid)
* [Swift](https://github.com/antiflasher/NanoID)

Also, [CLI tool] is available to generate IDs from a command line.

[CLI tool]: https://github.com/twhitbeck/nanoid-cli


## API

### Async

To generate hardware random bytes, CPU will collect electromagnetic noise.
During the collection, CPU doesn’t work.

If we will use asynchronous API for random generator,
another code could be executed during the entropy collection.

```js
const nanoid = require('nanoid/async')

async function createUser () {
  user.id = await nanoid()
}
```

Unfortunately, you will not have any benefits in a browser, since Web Crypto API
doesn’t have asynchronous API.


### Non-Secure

By default, Nano ID uses hardware random generator for security
and low collision probability. If you don’t need it, you can use
very fast non-secure generator.

```js
const nonSecure = require('nanoid/non-secure')
const id = nonSecure() //=> "Uakgb_J5m9g-0JDMbcJqLJ"
```

Note that it is predictable and have bigger collision probability.


### Custom Alphabet or Length

If you want to change the ID's alphabet or length
you can use the low-level `generate` module.

```js
const generate = require('nanoid/generate')
model.id = generate('1234567890abcdef', 10) //=> "4f90d13a42"
```

Check the safety of your custom alphabet and ID length
in our [ID collision probability] calculator.
You can find popular alphabets in [`nanoid-dictionary`].

Alphabet must contain 256 symbols or less.
Otherwise, the generator will not be secure.

Asynchronous and non-secure API is also available:

```js
const generate = require('nanoid/async/generate')
async function createUser () {
  user.id = await generate('1234567890abcdef', 10)
}
```

```js
const generate = require('nanoid/non-secure/generate')

user.id = generate('1234567890abcdef', 10)
```

[ID collision probability]: https://alex7kom.github.io/nano-nanoid-cc/
[`nanoid-dictionary`]:      https://github.com/CyberAP/nanoid-dictionary


### Custom Random Bytes Generator

You can replace the default safe random generator using the `format` module.
For instance, to use a seed-based generator.

```js
const format = require('nanoid/format')

function random (size) {
  const result = []
  for (let i = 0; i < size; i++) {
    result.push(randomByte())
  }
  return result
}

format(random, "abcdef", 10) //=> "fbaefaadeb"
```

`random` callback must accept the array size and return an array
with random numbers.

If you want to use the same URL-friendly symbols with `format`,
you can get the default alphabet from the `url` file.

```js
const url = require('nanoid/url')
format(random, url, 10) //=> "93ce_Ltuub"
```

Asynchronous API is also available:

```js
const format = require('nanoid/async/format')
const url = require('nanoid/url')

function random (size) {
  return new Promise(…)
}

async function createUser () {
  user.id = await format(random, url, 10)
}
```
