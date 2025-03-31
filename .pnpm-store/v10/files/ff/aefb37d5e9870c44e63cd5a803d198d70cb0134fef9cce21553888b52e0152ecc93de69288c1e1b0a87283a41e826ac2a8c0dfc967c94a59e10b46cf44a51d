import {createReadStream, readFileSync} from 'node:fs';
import {isStream} from 'is-stream';
import getStream from 'get-stream';
import mergeStream from 'merge-stream';

const validateInputOptions = input => {
	if (input !== undefined) {
		throw new TypeError('The `input` and `inputFile` options cannot be both set.');
	}
};

const getInputSync = ({input, inputFile}) => {
	if (typeof inputFile !== 'string') {
		return input;
	}

	validateInputOptions(input);
	return readFileSync(inputFile);
};

// `input` and `inputFile` option in sync mode
export const handleInputSync = options => {
	const input = getInputSync(options);

	if (isStream(input)) {
		throw new TypeError('The `input` option cannot be a stream in sync mode');
	}

	return input;
};

const getInput = ({input, inputFile}) => {
	if (typeof inputFile !== 'string') {
		return input;
	}

	validateInputOptions(input);
	return createReadStream(inputFile);
};

// `input` and `inputFile` option in async mode
export const handleInput = (spawned, options) => {
	const input = getInput(options);

	if (input === undefined) {
		return;
	}

	if (isStream(input)) {
		input.pipe(spawned.stdin);
	} else {
		spawned.stdin.end(input);
	}
};

// `all` interleaves `stdout` and `stderr`
export const makeAllStream = (spawned, {all}) => {
	if (!all || (!spawned.stdout && !spawned.stderr)) {
		return;
	}

	const mixed = mergeStream();

	if (spawned.stdout) {
		mixed.add(spawned.stdout);
	}

	if (spawned.stderr) {
		mixed.add(spawned.stderr);
	}

	return mixed;
};

// On failure, `result.stdout|stderr|all` should contain the currently buffered stream
const getBufferedData = async (stream, streamPromise) => {
	// When `buffer` is `false`, `streamPromise` is `undefined` and there is no buffered data to retrieve
	if (!stream || streamPromise === undefined) {
		return;
	}

	stream.destroy();

	try {
		return await streamPromise;
	} catch (error) {
		return error.bufferedData;
	}
};

const getStreamPromise = (stream, {encoding, buffer, maxBuffer}) => {
	if (!stream || !buffer) {
		return;
	}

	if (encoding) {
		return getStream(stream, {encoding, maxBuffer});
	}

	return getStream.buffer(stream, {maxBuffer});
};

// Retrieve result of child process: exit code, signal, error, streams (stdout/stderr/all)
export const getSpawnedResult = async ({stdout, stderr, all}, {encoding, buffer, maxBuffer}, processDone) => {
	const stdoutPromise = getStreamPromise(stdout, {encoding, buffer, maxBuffer});
	const stderrPromise = getStreamPromise(stderr, {encoding, buffer, maxBuffer});
	const allPromise = getStreamPromise(all, {encoding, buffer, maxBuffer: maxBuffer * 2});

	try {
		return await Promise.all([processDone, stdoutPromise, stderrPromise, allPromise]);
	} catch (error) {
		return Promise.all([
			{error, signal: error.signal, timedOut: error.timedOut},
			getBufferedData(stdout, stdoutPromise),
			getBufferedData(stderr, stderrPromise),
			getBufferedData(all, allPromise),
		]);
	}
};
