# import/order

🔧 This rule is automatically fixable by the [`--fix` CLI option](https://eslint.org/docs/latest/user-guide/command-line-interface#--fix).

<!-- end auto-generated rule header -->

Enforce a convention in the order of `require()` / `import` statements.

With the [`groups`](#groups-array) option set to `["builtin", "external", "internal", "parent", "sibling", "index", "object", "type"]` the order is as shown in the following example:

```ts
// 1. node "builtin" modules
import fs from 'fs';
import path from 'path';
// 2. "external" modules
import _ from 'lodash';
import chalk from 'chalk';
// 3. "internal" modules
// (if you have configured your path or webpack to handle your internal paths differently)
import foo from 'src/foo';
// 4. modules from a "parent" directory
import foo from '../foo';
import qux from '../../foo/qux';
// 5. "sibling" modules from the same or a sibling's directory
import bar from './bar';
import baz from './bar/baz';
// 6. "index" of the current directory
import main from './';
// 7. "object"-imports (only available in TypeScript)
import log = console.log;
// 8. "type" imports (only available in Flow and TypeScript)
import type { Foo } from 'foo';
```

Unassigned imports are ignored, as the order they are imported in may be important.

Statements using the ES6 `import` syntax must appear before any `require()` statements.

## Fail

```ts
import _ from 'lodash';
import path from 'path'; // `path` import should occur before import of `lodash`

// -----

var _ = require('lodash');
var path = require('path'); // `path` import should occur before import of `lodash`

// -----

var path = require('path');
import foo from './foo'; // `import` statements must be before `require` statement
```

## Pass

```ts
import path from 'path';
import _ from 'lodash';

// -----

var path = require('path');
var _ = require('lodash');

// -----

// Allowed as ̀`babel-register` is not assigned.
require('babel-register');
var path = require('path');

// -----

// Allowed as `import` must be before `require`
import foo from './foo';
var path = require('path');
```

## Limitations of `--fix`

Unbound imports are assumed to have side effects, and will never be moved/reordered. This can cause other imports to get "stuck" around them, and the fix to fail.

```javascript
import b from 'b'
import 'format.css';  // This will prevent --fix from working.
import a from 'a'
```

As a workaround, move unbound imports to be entirely above or below bound ones.

```javascript
import 'format1.css';  // OK
import b from 'b'
import a from 'a'
import 'format2.css';  // OK
```

## Options

This rule supports the following options:

### `groups: [array]`

How groups are defined, and the order to respect. `groups` must be an array of `string` or [`string`]. The only allowed `string`s are:
`"builtin"`, `"external"`, `"internal"`, `"unknown"`, `"parent"`, `"sibling"`, `"index"`, `"object"`, `"type"`.
The enforced order is the same as the order of each element in a group. Omitted types are implicitly grouped together as the last element. Example:

```ts
[
  'builtin', // Built-in types are first
  ['sibling', 'parent'], // Then sibling and parent types. They can be mingled together
  'index', // Then the index file
  'object',
  // Then the rest: internal and external type
]
```

The default value is `["builtin", "external", "parent", "sibling", "index"]`.

You can set the options like this:

```ts
"import/order": [
  "error",
  {
    "groups": [
      "index",
      "sibling",
      "parent",
      "internal",
      "external",
      "builtin",
      "object",
      "type"
    ]
  }
]
```

### `pathGroups: [array of objects]`

To be able to group by paths mostly needed with aliases pathGroups can be defined.

Properties of the objects

| property       | required | type   | description   |
|----------------|:--------:|--------|---------------|
| pattern        |     x    | string | minimatch pattern for the paths to be in this group (will not be used for builtins or externals) |
| patternOptions |          | object | options for minimatch, default: { nocomment: true } |
| group          |     x    | string | one of the allowed groups, the pathGroup will be positioned relative to this group |
| position       |          | string | defines where around the group the pathGroup will be positioned, can be 'after' or 'before', if not provided pathGroup will be positioned like the group |

```json
{
  "import/order": ["error", {
    "pathGroups": [
      {
        "pattern": "~/**",
        "group": "external"
      }
    ]
  }]
}
```

### `distinctGroup: [boolean]`

This changes how `pathGroups[].position` affects grouping. The property is most useful when `newlines-between` is set to `always` and at least 1 `pathGroups` entry has a `position` property set.

By default, in the context of a particular `pathGroup` entry, when setting `position`, a new "group" will silently be created. That is, even if the `group` is specified, a newline will still separate imports that match that `pattern` with the rest of the group (assuming `newlines-between` is `always`). This is undesirable if your intentions are to use `position` to position _within_ the group (and not create a new one). Override this behavior by setting `distinctGroup` to `false`; this will keep imports within the same group as intended.

Note that currently, `distinctGroup` defaults to `true`. However, in a later update, the default will change to `false`

Example:

```json
{
  "import/order": ["error", {
    "newlines-between": "always",
    "pathGroups": [
      {
        "pattern": "@app/**",
        "group": "external",
        "position": "after"
      }
    ],
    "distinctGroup": false
  }]
}
```

### `pathGroupsExcludedImportTypes: [array]`

This defines import types that are not handled by configured pathGroups.
If you have added path groups with patterns that look like `"builtin"` or `"external"` imports, you have to remove this group (`"builtin"` and/or `"external"`) from the default exclusion list (e.g., `["builtin", "external", "object"]`, etc) to sort these path groups correctly.

Example:

```json
{
  "import/order": ["error", {
    "pathGroups": [
      {
        "pattern": "@app/**",
        "group": "external",
        "position": "after"
      }
    ],
    "pathGroupsExcludedImportTypes": ["builtin"]
  }]
}
```

[Import Type](https://github.com/import-js/eslint-plugin-import/blob/HEAD/src/core/importType.js#L90) is resolved as a fixed string in predefined set, it can't be a `patterns`(e.g., `react`, `react-router-dom`, etc). See [#2156] for details.

### `newlines-between: [ignore|always|always-and-inside-groups|never]`

Enforces or forbids new lines between import groups:

 - If set to `ignore`, no errors related to new lines between import groups will be reported.
 - If set to `always`, at least one new line between each group will be enforced, and new lines inside a group will be forbidden. To prevent multiple lines between imports, core `no-multiple-empty-lines` rule can be used.
 - If set to `always-and-inside-groups`, it will act like `always` except newlines are allowed inside import groups.
 - If set to `never`, no new lines are allowed in the entire import section.

The default value is `"ignore"`.

With the default group setting, the following will be invalid:

```ts
/* eslint import/order: ["error", {"newlines-between": "always"}] */
import fs from 'fs';
import path from 'path';
import index from './';
import sibling from './foo';
```

```ts
/* eslint import/order: ["error", {"newlines-between": "always-and-inside-groups"}] */
import fs from 'fs';

import path from 'path';
import index from './';
import sibling from './foo';
```

```ts
/* eslint import/order: ["error", {"newlines-between": "never"}] */
import fs from 'fs';
import path from 'path';

import index from './';

import sibling from './foo';
```

while those will be valid:

```ts
/* eslint import/order: ["error", {"newlines-between": "always"}] */
import fs from 'fs';
import path from 'path';

import index from './';

import sibling from './foo';
```

```ts
/* eslint import/order: ["error", {"newlines-between": "always-and-inside-groups"}] */
import fs from 'fs';

import path from 'path';

import index from './';

import sibling from './foo';
```

```ts
/* eslint import/order: ["error", {"newlines-between": "never"}] */
import fs from 'fs';
import path from 'path';
import index from './';
import sibling from './foo';
```

### `alphabetize: {order: asc|desc|ignore, orderImportKind: asc|desc|ignore, caseInsensitive: true|false}`

Sort the order within each group in alphabetical manner based on **import path**:

 - `order`: use `asc` to sort in ascending order, and `desc` to sort in descending order (default: `ignore`).
 - `orderImportKind`: use `asc` to sort in ascending order various import kinds, e.g. imports prefixed with `type` or `typeof`, with same import path. Use `desc` to sort in descending order (default: `ignore`).
 - `caseInsensitive`: use `true` to ignore case, and `false` to consider case (default: `false`).

Example setting:

```ts
alphabetize: {
  order: 'asc', /* sort in ascending order. Options: ['ignore', 'asc', 'desc'] */
  caseInsensitive: true /* ignore case. Options: [true, false] */
}
```

This will fail the rule check:

```ts
/* eslint import/order: ["error", {"alphabetize": {"order": "asc", "caseInsensitive": true}}] */
import React, { PureComponent } from 'react';
import aTypes from 'prop-types';
import { compose, apply } from 'xcompose';
import * as classnames from 'classnames';
import blist from 'BList';
```

While this will pass:

```ts
/* eslint import/order: ["error", {"alphabetize": {"order": "asc", "caseInsensitive": true}}] */
import blist from 'BList';
import * as classnames from 'classnames';
import aTypes from 'prop-types';
import React, { PureComponent } from 'react';
import { compose, apply } from 'xcompose';
```

### `warnOnUnassignedImports: true|false`

 - default: `false`

Warns when unassigned imports are out of order.  These warning will not be fixed
with `--fix` because unassigned imports are used for side-effects and changing the
import of order of modules with side effects can not be done automatically in a
way that is safe.

This will fail the rule check:

```ts
/* eslint import/order: ["error", {"warnOnUnassignedImports": true}] */
import fs from 'fs';
import './styles.css';
import path from 'path';
```

While this will pass:

```ts
/* eslint import/order: ["error", {"warnOnUnassignedImports": true}] */
import fs from 'fs';
import path from 'path';
import './styles.css';
```

## Related

 - [`import/external-module-folders`] setting

 - [`import/internal-regex`] setting

[`import/external-module-folders`]: ../../README.md#importexternal-module-folders

[`import/internal-regex`]: ../../README.md#importinternal-regex
