# import/no-restricted-paths

<!-- end auto-generated rule header -->

Some projects contain files which are not always meant to be executed in the same environment.
For example consider a web application that contains specific code for the server and some specific code for the browser/client. In this case you don’t want to import server-only files in your client code.

In order to prevent such scenarios this rule allows you to define restricted zones where you can forbid files from imported if they match a specific path.

## Rule Details

This rule has one option. The option is an object containing the definition of all restricted `zones` and the optional `basePath` which is used to resolve relative paths within.
The default value for `basePath` is the current working directory.

Each zone consists of the `target` paths, a `from` paths, and an optional `except` and `message` attribute.

 - `target` contains the paths where the restricted imports should be applied. It can be expressed by
   - directory string path that matches all its containing files
   - glob pattern matching all the targeted files
   - an array of multiple of the two types above
 - `from` paths define the folders that are not allowed to be used in an import. It can be expressed by
   - directory string path that matches all its containing files
   - glob pattern matching all the files restricted to be imported
   - an array of multiple directory string path
   - an array of multiple glob patterns
 - `except` may be defined for a zone, allowing exception paths that would otherwise violate the related `from`. Note that it does not alter the behaviour of `target` in any way.
   - in case `from` contains only glob patterns, `except` must be an array of glob patterns as well
   - in case `from` contains only directory path, `except` is relative to `from` and cannot backtrack to a parent directory
 - `message` - will be displayed in case of the rule violation.

### Examples

Given the following folder structure:

```pt
my-project
├── client
│   └── foo.js
│   └── baz.js
└── server
    └── bar.js
```

and the current file being linted is `my-project/client/foo.js`.

The following patterns are considered problems when configuration set to `{ "zones": [ { "target": "./client", "from": "./server" } ] }`:

```js
import bar from '../server/bar';
```

The following patterns are not considered problems when configuration set to `{ "zones": [ { "target": "./client", "from": "./server" } ] }`:

```js
import baz from '../client/baz';
```

---------------

Given the following folder structure:

```pt
my-project
├── client
│   └── foo.js
│   └── baz.js
└── server
    ├── one
    │   └── a.js
    │   └── b.js
    └── two
```

and the current file being linted is `my-project/server/one/a.js`.

and the current configuration is set to:

```json
{ "zones": [ {
    "target": "./tests/files/restricted-paths/server/one",
    "from": "./tests/files/restricted-paths/server",
    "except": ["./one"]
} ] }
```

The following pattern is considered a problem:

```js
import a from '../two/a'
```

The following pattern is not considered a problem:

```js
import b from './b'

```

---------------

Given the following folder structure:

```pt
my-project
├── client
    └── foo.js
    └── sub-module
        └── bar.js
        └── baz.js

```

and the current configuration is set to:

```json
{ "zones": [ {
    "target": "./tests/files/restricted-paths/client/!(sub-module)/**/*",
    "from": "./tests/files/restricted-paths/client/sub-module/**/*",
} ] }
```

The following import is considered a problem in `my-project/client/foo.js`:

```js
import a from './sub-module/baz'
```

The following import is not considered a problem in `my-project/client/sub-module/bar.js`:

```js
import b from './baz'
```

---------------

Given the following folder structure:

```pt
my-project
└── one
   └── a.js
   └── b.js
└── two
   └── a.js
   └── b.js
└── three
   └── a.js
   └── b.js
```

and the current configuration is set to:

```json
{
  "zones": [
    {
      "target": ["./tests/files/restricted-paths/two/*", "./tests/files/restricted-paths/three/*"],
      "from": ["./tests/files/restricted-paths/one", "./tests/files/restricted-paths/three"],
    }
  ]
}
```

The following patterns are not considered a problem in `my-project/one/b.js`:

```js
import a from '../three/a'
```

```js
import a from './a'
```

The following pattern is not considered a problem in `my-project/two/b.js`:

```js
import a from './a'
```

The following patterns are considered a problem in `my-project/two/a.js`:

```js
import a from '../one/a'
```

```js
import a from '../three/a'
```

The following patterns are considered a problem in `my-project/three/b.js`:

```js
import a from '../one/a'
```

```js
import a from './a'
```
