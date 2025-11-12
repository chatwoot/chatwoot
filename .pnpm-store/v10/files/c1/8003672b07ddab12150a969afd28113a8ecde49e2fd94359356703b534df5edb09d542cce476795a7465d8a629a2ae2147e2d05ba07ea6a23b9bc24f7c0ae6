export type GlobalDirectory = {
	/**
	The directory with globally installed packages.

	Equivalent to `npm root --global`.
	*/
	readonly packages: string;

	/**
	The directory with globally installed binaries.

	Equivalent to `npm bin --global`.
	*/
	readonly binaries: string;

	/**
	The directory with directories for packages and binaries. You probably want either of the above.

	Equivalent to `npm prefix --global`.
	*/
	readonly prefix: string;
};

declare const globalDirectory: {
	/**
	Get the directory of globally installed packages and binaries.

	@example
	```
	import globalDirectory from 'global-directory';

	console.log(globalDirectory.npm.prefix);
	//=> '/usr/local'

	console.log(globalDirectory.npm.packages);
	//=> '/usr/local/lib/node_modules'
	```
	*/
	readonly npm: GlobalDirectory;

	/**
	Get the directory of globally installed packages and binaries.

	@example
	```
	import globalDirectory from 'global-directory';

	console.log(globalDirectory.npm.binaries);
	//=> '/usr/local/bin'

	console.log(globalDirectory.yarn.packages);
	//=> '/Users/sindresorhus/.config/yarn/global/node_modules'
	```
	*/
	readonly yarn: GlobalDirectory;
};

export default globalDirectory;
