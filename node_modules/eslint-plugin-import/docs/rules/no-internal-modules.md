# import/no-internal-modules

Use this rule to prevent importing the submodules of other modules.

## Rule Details

This rule has one option, `allow` which is an array of [minimatch/glob patterns](https://github.com/isaacs/node-glob#glob-primer) patterns that whitelist paths and import statements that can be imported with reaching.

### Examples

Given the following folder structure:

```
my-project
├── actions
│   └── getUser.js
│   └── updateUser.js
├── reducer
│   └── index.js
│   └── user.js
├── redux
│   └── index.js
│   └── configureStore.js
└── app
│   └── index.js
│   └── settings.js
└── entry.js
```

And the .eslintrc file:
```
{
  ...
  "rules": {
    "import/no-internal-modules": [ "error", {
      "allow": [ "**/actions/*", "source-map-support/*" ]
    } ]
  }
}
```

The following patterns are considered problems:

```js
/**
 *  in my-project/entry.js
 */

import { settings } from './app/index'; // Reaching to "./app/index" is not allowed
import userReducer from './reducer/user'; // Reaching to "./reducer/user" is not allowed
import configureStore from './redux/configureStore'; // Reaching to "./redux/configureStore" is not allowed

export { settings } from './app/index'; // Reaching to "./app/index" is not allowed
export * from './reducer/user'; // Reaching to "./reducer/user" is not allowed
```

The following patterns are NOT considered problems:

```js
/**
 *  in my-project/entry.js
 */

import 'source-map-support/register';
import { settings } from '../app';
import getUser from '../actions/getUser';

export * from 'source-map-support/register';
export { settings } from '../app';
```
