declare const junk: {
	/**
	Returns `true` if `filename` matches a junk file.
	*/
	is(filename: string): boolean;

	/**
	Returns `true` if `filename` doesn't match a junk file.

	@example
	```
	import {promisify} from 'util';
	import * as fs from 'fs';
	import junk = require('junk');

	const pReaddir = promisify(fs.readdir);

	(async () => {
		const files = await pReaddir('some/path');

		console.log(files);
		//=> ['.DS_Store', 'test.jpg']

		console.log(files.filter(junk.not));
		//=> ['test.jpg']
	})();
	```
	*/
	not(filename: string): boolean;

	/**
	Regex used for matching junk files.
	*/
	readonly regex: RegExp;

	// TODO: Remove this for the next major release
	default: typeof junk;
};

export = junk;
