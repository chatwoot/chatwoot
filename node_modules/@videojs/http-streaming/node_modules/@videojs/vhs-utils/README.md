<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [@videojs/vhs-utils](#videojsvhs-utils)
  - [Installation](#installation)
  - [Usage](#usage)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# @videojs/vhs-utils

vhs-utils serves two purposes:

1. It extracts objects and functions shared throughout @videojs/http-streaming code to save on package size. See [the original @videojs/http-streaming PR](https://github.com/videojs/http-streaming/pull/637) for details.
2. It exports generic functions from VHS that may be useful to plugin authors.

## Installation

```sh
npm install --save @videojs/vhs-utils
```

## Usage

All utility functions are published under dist and can be required/imported like so:

> es import using es dist
```js
import resolveUrl from '@videojs/vhs-utils/es/resolve-url';
```

> cjs import using cjs dist
```js
const resolveUrl = require('@videojs/vhs-utils/cjs/resolve-url');
```

> depricated cjs dist
```js
const resolveUrl = require('@videojs/vhs-utils/dist/resolve-url');
```
