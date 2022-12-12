declare namespace cpFile {
	interface Options {
		/**
		Overwrite existing file.

		@default true
		*/
		readonly overwrite?: boolean;
	}

	interface ProgressData {
		/**
		Absolute path to source.
		*/
		src: string;

		/**
		Absolute path to destination.
		*/
		dest: string;

		/**
		File size in bytes.
		*/
		size: number;

		/**
		Copied size in bytes.
		*/
		written: number;

		/**
		Copied percentage, a value between `0` and `1`.
		*/
		percent: number;
	}

	interface ProgressEmitter {
		/**
		For empty files, the `progress` event is emitted only once.
		*/
		on(event: 'progress', handler: (data: ProgressData) => void): Promise<void>;
	}
}

declare const cpFile: {
	/**
	Copy a file.

	@param source - File you want to copy.
	@param destination - Where you want the file copied.
	@returns A `Promise` that resolves when the file is copied.

	@example
	```
	import cpFile = require('cp-file');

	(async () => {
		await cpFile('source/unicorn.png', 'destination/unicorn.png');
		console.log('File copied');
	})();
	```
	*/
	(source: string, destination: string, options?: cpFile.Options): Promise<void> & cpFile.ProgressEmitter;

	/**
	Copy a file synchronously.

	@param source - File you want to copy.
	@param destination - Where you want the file copied.
	*/
	sync(source: string, destination: string, options?: cpFile.Options): void;
};

export = cpFile;
