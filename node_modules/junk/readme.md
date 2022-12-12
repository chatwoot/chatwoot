# junk [![Build Status](https://travis-ci.org/sindresorhus/junk.svg?branch=master)](https://travis-ci.org/sindresorhus/junk)

> Filter out [system junk files](test.js) like `.DS_Store` and `Thumbs.db`


## Install

```
$ npm install junk
```


## Usage

```js
const {promisify} = require('util');
const fs = require('fs');
const junk = require('junk');

const pReaddir = promisify(fs.readdir);

(async () => {
	const files = await pReaddir('some/path');

	console.log(files);
	//=> ['.DS_Store', 'test.jpg']

	console.log(files.filter(junk.not));
	//=> ['test.jpg']
})();
```


## API

### junk.is(filename)

Returns `true` if `filename` matches a junk file.

### junk.not(filename)

Returns `true` if `filename` doesn't match a junk file.

### junk.regex

Regex used for matching junk files.


## License

MIT © [Sindre Sorhus](https://sindresorhus.com)
