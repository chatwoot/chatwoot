# is-window

> Checks if the given value is a window object.

[![MIT License](https://img.shields.io/badge/license-MIT_License-green.svg?style=flat-square)](https://github.com/gearcase/is-window/blob/master/LICENSE)

[![build:?](https://img.shields.io/travis/gearcase/is-window/master.svg?style=flat-square)](https://travis-ci.org/gearcase/is-window)
[![coverage:?](https://img.shields.io/coveralls/gearcase/is-window/master.svg?style=flat-square)](https://coveralls.io/github/gearcase/is-window)


## Install

```
$ npm install --save is-window 
```


## Usage

```js
var isWindow = require('is-window');

isWindow();               // => false
isWindow(1);              // => false
isWindow('1');            // => false
isWindow(true);           // => false
isWindow(null);           // => false
isWindow({});             // => false
isWindow(function () {}); // => false
isWindow([]);             // => false
isWindow([1, 2, 3]);      // => false
```

## Related

- [is-nil](https://github.com/gearcase/is-nil) - Checks if the given value is null or undefined.
- [is-null](https://github.com/gearcase/is-null) - Checks if the given value is null.
- [is-native](https://github.com/gearcase/is-native) - Checks if the given value is a native function.
- [is-index](https://github.com/gearcase/is-index) - Checks if the given value is a valid array-like index.
- [is-length](https://github.com/gearcase/is-length) - Checks if the given value is a valid array-like length.
- [is-array-like](https://github.com/gearcase/is-array-like) - Checks if the given value is an array or an array-like object.

## Contributing

Pull requests and stars are highly welcome.

For bugs and feature requests, please [create an issue](https://github.com/gearcase/is-window/issues/new).
