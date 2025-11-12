# rust-result.js

Mimic Rust's [`std::result`][result].

## Installation

```sh
npm install rust-result
```

## Usage

```js
var fs = require('fs');
var Result = require('./');


// If you want async just get a promise or something.
var readFile = function (path, encoding) {
  try {
    return Result.Ok(fs.readFileSync(path, encoding))
  }
  catch (ex) {
    return Result.Err(ex)
  }
}

var result = readFile(__filename);
var v, err;

if (Result.isOk(result)) {
  v = Result.Ok(result);
  console.log('got ' + v.length + ' bytes')
}
else if (Result.isErr(result)) {
  err = Result.Err(result);
  console.error('oops!', err.message)
}

result = readFile(__filename + 'I do not exist')
if (Result.isOk(result)) {
  v = Result.Ok(result)
  console.log('got ' + v.length + ' bytes')
}
else if (Result.isErr(result)) {
  err = Result.Err(result)
  console.error('oops!', err.message)
}

```

## Documentation

```jsig
type OkResult<T> : {
  v: T
}
type ErrResult<E <: Error> : {
  err: E
}

rust-result : {
  Ok: ((T) => OkResult<T>) |
    ((OkResult<T>) => T) |
    ((ErrResult<E>) => void),
  isOk: ((OkResult<T>) => true) |
    ((ErrResult<E>) => false)
  Err: ((E <: Error) => ErrResult<E>) |
    ((ErrResult<E>) => E) |
    ((OkResult<T>) => void),
  isErr: ((ErrResult<E>) => true) |
    ((OkResult<T>) => false)
}
```

### `Result.Ok`

The `Result.Ok` function is overloaded to do one of two things.
  It can create a new `Ok` instance or it can check whether
  the argument is an instance of `Ok`

If you call `Result.Ok` with a plain value it will return an
  instance of `Ok` that boxes your plain value.

If you call `Result.Ok` with either an `Err` or an `Ok` instance
  then it will return `undefined` for the `Err` and return the
  value boxed in the `Ok`

### `Result.isOk`

The `Result.isOk` function just checks whether the argument
  is an instance of `Ok`.

This predicate function returns true if you pass it an `Ok` and
  returns false if you pass it an `Err`

### `Result.Err`

The `Result.Err` function is overloaded to do one of two things.
  It can create a new `Err` instance or it can check whether
  the argument is an instance of `Err`

If you call `Result.Err` with a plain error it will return an
  instance of `Err` that boxes your plain error.

If you call `Result.Err` with either an `Err` or an `Ok` instance
  then it will return `undefined` for the `Ok` and return the
  value err in the `Err`

### `Result.isErr`

The `Result.isErr` function just checks whether the argument
  is an instance of `Err`.

This predicate function returns true if you pass it an `Err` and
  returns false if you pass it an `Ok`

## MIT Licenced.

  [result]: http://doc.rust-lang.org/std/result/
