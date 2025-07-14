# Tiny Hash Functions

Some super-tiny implementations of common hash functions (MD5, SHA-1 and SHA-256).

## Installation

From npm:

```
npm i tiny-hashes
```

## Usage

Preferably using ES modules:

```js
import md5 from 'tiny-hashes/md5';
import sha1 from 'tiny-hashes/sha1';
import sha256 from 'tiny-hashes/sha256';

md5('hello, world'); // "e4d7f1b4ed2e42d15898f4b27b019da4", hopefully

sha1('hello, world'); // "b7e23ec29af22b0b4e41da31e868d57226121c84", hopefully

sha256('hello, world'); // "09ca7e4eaa6e8ae9c7d261167129184883644d07dfba7cbfbc4c8a2e08360d5b", hopefully
```

### Other ways of importing

The following styles should also all work, but may be less-friendly to tree-shaking:

```js
const md5 = require('tiny-hashes/md5');
const sha1 = require('tiny-hashes/sha1');
const sha256 = require('tiny-hashes/sha256');

import { md5, sha1, sha256 } from 'tiny-hashes';

const { md5, sha1, sha256 } = require('tiny-hashes');
```

## When should you use this?

Please don't use this if you absolutely rely on it being correct. There are more solid solutions out there.

Please also don't use this server-side in Node.js - the `crypto` build-in module exists for a reason.

Basically only use this if you want a super-duper-tiny hash function in the browser that you can be about 99% sure is correct and should always be self-consistent.
