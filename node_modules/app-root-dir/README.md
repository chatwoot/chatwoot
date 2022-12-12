node-app-root-dir
=================

Simple module to infer the root directory of the currently running node application

## Usage
```javascript
// get the application's root directory
var appRootDir = require('app-root-dir').get();

// set the application's root directory
// (this will set a global so that no matter
// how many instances of app-root-dir module are
// installed, they will all return the same
// directory)
require('app-root-dir').set(__dirname);
```


## How it Works
The following strategy is used to find the application's root directory (the directory in your project that contains the main package.json file):

* If **package.json** exists at `process.cwd()` then use `process.cwd()` as the application root directory.
* Else if, the **app-root-dir** module has **node_modules** directory in its path then use the directory above this as the application root directory. NOTE: The parent directory of the _first_ **node_modules** directory in the path is used if the **app-root-dir** module is installed as a submodule of another module.
* Else, use the directory of **app-root-dir** module as the application root directory.

For example, consider this directory structure for the scenarios below:
+ my-project
  + package.json
  + server.js
  + node_modules
    + app-root-dir
      + lib
        + index.js

### Scenario 1:
Application is ran as:
`node server.js`

The application root directory will be **my-project** because **package.json** exists at `process.cwd()`

### Scenario 2:
Application is ran as:
`node my-project/server.js`

There is no **package.json** at `process.cwd()`. The application root directory will still be **my-project** because **my-project/node_modules/app-root-dir/lib/index.js** has **node_modules** in its path and the directory above **node_modules** is the application's root directory.
