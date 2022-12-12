# EditorConfig JavaScript Core

[![Build Status](https://travis-ci.org/editorconfig/editorconfig-core-js.svg?branch=master)](https://travis-ci.org/editorconfig/editorconfig-core-js)
[![dependencies Status](https://david-dm.org/editorconfig/editorconfig-core-js/status.svg)](https://david-dm.org/editorconfig/editorconfig-core-js)

The EditorConfig JavaScript core will provide the same functionality as the
[EditorConfig C Core][] and [EditorConfig Python Core][].


## Installation

You need [node][] to use this package.

To install the package locally:

```bash
$ npm install editorconfig
```

To install the package system-wide:

```bash
$ npm install -g editorconfig
```

## Usage

### in Node.js:

#### parse(filePath[, options])

options is an object with the following defaults:

```js
{
  config: '.editorconfig',
  version: pkg.version,
  root: '/'
};
```

Search for `.editorconfig` starting from the current directory to the root directory.

Example:

```js
var editorconfig = require('editorconfig');
var path = require('path');
var filePath = path.join(__dirname, '/sample.js');
var promise = editorconfig.parse(filePath);
promise.then(function onFulfilled(result) {
  console.log(result);
});

/*
  {
    indent_style: 'space',
    indent_size: 2,
    end_of_line: 'lf',
    charset: 'utf-8',
    trim_trailing_whitespace: true,
    insert_final_newline: true,
    tab_width: 2
  };
*/
```

#### parseSync(filePath[, options])

Synchronous version of `editorconfig.parse()`.

#### parseString(fileContent)

The `parse()` function above uses `parseString()` under the hood. If you have your file contents
just pass it to `parseString()` and it'll return the same results as `parse()`.

#### parseFromFiles(filePath, configs[, options])

options is an object with the following defaults:

```js
{
  config: '.editorconfig',
  version: pkg.version,
  root: '/'
};
```

Specify the `.editorconfig`.

Example:

```js
var editorconfig = require('editorconfig');
var fs = require('fs');
var path = require('path');
var configPath = path.join(__dirname, '/.editorconfig');
var configs = [
  {
    name: configPath,
    contents: fs.readFileSync(configPath, 'utf8')
  }
];
var filePath = path.join(__dirname, '/sample.js');
var promise = editorconfig.parseFromFiles(filePath, configs);
promise.then(function onFulfilled(result) {
  console.log(result)
});

/*
  {
    indent_style: 'space',
    indent_size: 2,
    end_of_line: 'lf',
    charset: 'utf-8',
    trim_trailing_whitespace: true,
    insert_final_newline: true,
    tab_width: 2
  };
*/
```

#### parseFromFilesSync(filePath, configs[, options])

Synchronous version of `editorconfig.parseFromFiles()`.

### in Command Line

```bash
$ ./bin/editorconfig

    Usage: editorconfig [OPTIONS] FILEPATH1 [FILEPATH2 FILEPATH3 ...]

    EditorConfig Node.js Core Version 0.11.4-development

    FILEPATH can be a hyphen (-) if you want path(s) to be read from stdin.

    Options:

        -h, --help     output usage information
        -V, --version  output the version number
        -f <path>      Specify conf filename other than ".editorconfig"
        -b <version>   Specify version (used by devs to test compatibility)
```

Example:

```bash
$ ./bin/editorconfig /home/zoidberg/humans/anatomy.md
charset=utf-8
insert_final_newline=true
end_of_line=lf
tab_width=8
trim_trailing_whitespace=sometimes
```

## Development

To install dependencies for this package run this in the package directory:

```bash
$ npm install
```

Next, run the following commands:

```bash
$ npm run build
$ npm run copy
$ npm link ./dist
```

The global editorconfig will now point to the files in your development
repository instead of a globally-installed version from npm. You can now use
editorconfig directly to test your changes.

If you ever update from the central repository and there are errors, it might
be because you are missing some dependencies. If that happens, just run npm
link again to get the latest dependencies.

To test the command line interface:

```bash
$ editorconfig <filepath>
```

# Testing

[CMake][] must be installed to run the tests.

To run the tests:

```bash
$ npm test
```

To run the tests with increased verbosity (for debugging test failures):

```bash
$ npm run-script test-verbose
```

[EditorConfig C Core]: https://github.com/editorconfig/editorconfig-core
[EditorConfig Python Core]: https://github.com/editorconfig/editorconfig-core-py
[node]: http://nodejs.org/
[cmake]: http://www.cmake.org
