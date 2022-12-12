# Description

Write minimal node index.js files that require and export siblings by file basename

# Latest Version

1.2.0

# Installation
```
npm install requireindex
```

or in package.json

```json
{
  ...
  "dependencies": {
    "requireindex": "1.1.x"
  }
}
```

# Usage
Check the [test directory](https://github.com/stephenhandley/requireindex/tree/master/test) for example usage. The [test/lib](https://github.com/stephenhandley/requireindex/tree/master/test/lib) looks like:

```
lib/
  index.js
  Foo.js
  bar/
    index.js
    f.js
    fing.js
    fed/
      again.js
      ignored.js
      index.js
      somemore.js
  bam.js
  _private.js

```

The index.js files in [test/lib/](https://github.com/stephenhandley/requireindex/tree/master/test/lib/index.js) and [test/lib/bar/](https://github.com/stephenhandley/requireindex/tree/master/test/lib/bar/index.js) contain:

```js
module.exports = require('requireindex')(__dirname);
```

and the index.js file in [test/lib/bar/fed/](https://github.com/stephenhandley/requireindex/tree/master/test/lib/bar/fed/index.js) contains:

```js
module.exports = require('requireindex')(__dirname, ['again', 'somemore']);
```

The optional second argument allows you to explicitly specify the required files using their basename. In this example [test/lib/bar/fed/ignored.js](https://github.com/stephenhandley/requireindex/tree/master/test/lib/bar/fed/ignored.js) is not included as a public module. The other way to make a module/file private without the need for explicitly naming all the other included files is to prefix the filename with an underscore, as demonstrated by [test/lib/_private.js](https://github.com/stephenhandley/requireindex/tree/master/test/lib/_private.js) which is not exported.

So, with these index.js files, the result of

```js
require('lib');
```

is:

```js
{
  bam: {
    m: [Function],
    n: [Function]
  },
  bar: {
    f: [Function],
    fed: {
      again: [Function],
      somemore: [Function]
    },
    fing: [Function]
  },
  Foo: {
    l: [Function],
    ls: [Function]
  }
}
```

#Build status
[![build status](https://secure.travis-ci.org/stephenhandley/requireindex.png)](http://travis-ci.org/stephenhandley/requireindex)
