# common-path-prefix

Computes the longest prefix string that is common to each path, excluding the base component. Tested with Node.js 8 and above.

## Installation

```console
npm install common-path-prefix
```

## Usage

The module has one default export, the `commonPathPrefix` function:

```js
const commonPathPrefix = require('common-path-prefix')
```

Call `commonPathPrefix()` with an array of paths (strings) and an optional separator character:

```js
const paths = ['templates/main.handlebars', 'templates/_partial.handlebars']

commonPathPrefix(paths, '/') // returns 'templates/'
```

If the separator is not provided the first `/` or `\` found in any of the paths is used. Otherwise the platform-default value is used:

```js
commonPathPrefix(['templates/main.handlebars', 'templates/_partial.handlebars']) // returns 'templates/'
commonPathPrefix(['templates\\main.handlebars', 'templates\\_partial.handlebars']) // returns 'templates\\'
```

You can provide any separator, for example:

```js
commonPathPrefix(['foo$bar', 'foo$baz'], '$') // returns 'foo$''
```

An empty string is returned if no common prefix exists:

```js
commonPathPrefix(['foo/bar', 'baz/qux']) // returns ''
commonPathPrefix(['foo/bar']) // returns ''
```

Note that the following *does* have a common prefix:

```js
commonPathPrefix(['/foo/bar', '/baz/qux']) // returns '/'
```
