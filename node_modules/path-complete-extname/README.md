# path-complete-extname

version: 0.1.0

[![Build Status](https://travis-ci.org/ruyadorno/path-complete-extname.svg?branch=master)](https://travis-ci.org/ruyadorno/path-complete-extname)

[path.extname](http://nodejs.org/api/path.html#path_path_extname_p) implementation adapted to also include multiple dots extensions.


## About

This module contains the native implementation of [Node.js](http://nodejs.org/) `path.extname` method adapted to get complete extension names.

### Example

```js
  var path = require('path');
  var pathCompleteExtname = require('path-complete-extname');

  var filename = 'myfile.tar.gz';

  path.extname(filename); // .gz
  pathCompleteExtname(filename); // .tar.gz
```

For more information about what filenames are valid and what will be returned in each case, see the **test.js** file.


## License

Released under the [MIT License](http://www.opensource.org/licenses/mit-license.php).

