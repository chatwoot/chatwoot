# individual

[![build status][build-png]][build] [![Coverage Status][cover-png]][cover] [![Davis Dependency status][dep-png]][dep]

[![NPM][npm-png]][npm]

[![browser support][test-png]][test]

Garantueed individual values

## Example

```js
var Individual = require("individual")

var moduleCache = Individual("__MY_MODULE_CACHE", {})

// moduleCache is a individual variable local to this file.
// It will always be the same value and defaults to {}.
```

This gives you a singleton value by a unique name (it stores it
as a global variable).

## Use cases

Your module has an internal cache. If your module is loaded
    twice, (someone didn't npm dedup and has two copies of your
    module) you would have two seperate caches that dont talk
    to each other.

Best case your cache is less efficient. Worst case you have a
    cache because the native C++ extension you talk to crashes
    if you instantiate something twice.

You need a garantuee that this value is an individual, there is
    only one of it.

I use it myself because opening a SockJS websocket to the same
    URI twice causes an infinite loop. I need a garantuee that
    I have an individual value for the SockJS connection so I
    can see whether I already have an open connection.

## WHY GLOBALS >:(

I can't imagine any other way to do it. I hate it too. Make a
    pull request if you know the real solution

## Installation

`npm install individual`

## Contributors

 - Raynos

## MIT Licenced

  [build-png]: https://secure.travis-ci.org/Raynos/individual.png
  [build]: https://travis-ci.org/Raynos/individual
  [cover-png]: https://coveralls.io/repos/Raynos/individual/badge.png
  [cover]: https://coveralls.io/r/Raynos/individual
  [dep-png]: https://david-dm.org/Raynos/individual.png
  [dep]: https://david-dm.org/Raynos/individual
  [test-png]: https://ci.testling.com/Raynos/individual.png
  [test]: https://ci.testling.com/Raynos/individual
  [npm-png]: https://nodei.co/npm/individual.png?stars&downloads
  [npm]: https://nodei.co/npm/individual

