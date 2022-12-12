'use strict';
const Observable = require('any-observable');

function or(option, alternate, required) {
	const result = option === false ? false : option || alternate;

	if ((required && !result) || (result && typeof result !== 'string')) {
		throw new TypeError(alternate + 'Event must be a string.');
	}

	return result;
}

module.exports = (stream, opts) => {
	opts = opts || {};

	let complete = false;
	let dataListeners = [];
	const awaited = opts.await;
	const dataEvent = or(opts.dataEvent, 'data', true);
	const errorEvent = or(opts.errorEvent, 'error');
	const endEvent = or(opts.endEvent, 'end');

	function cleanup() {
		complete = true;
		dataListeners.forEach(listener => {
			stream.removeListener(dataEvent, listener);
		});
		dataListeners = null;
	}

	const completion = new Promise((resolve, reject) => {
		function onEnd(result) {
			if (awaited) {
				awaited.then(resolve);
			} else {
				resolve(result);
			}
		}

		if (endEvent) {
			stream.once(endEvent, onEnd);
		} else if (awaited) {
			onEnd();
		}

		if (errorEvent) {
			stream.once(errorEvent, reject);
		}

		if (awaited) {
			awaited.catch(reject);
		}
	}).catch(err => {
		cleanup();
		throw err;
	}).then(result => {
		cleanup();
		return result;
	});

	return new Observable(observer => {
		completion
			.then(observer.complete.bind(observer))
			.catch(observer.error.bind(observer));

		if (complete) {
			return null;
		}

		const onData = data => {
			observer.next(data);
		};

		stream.on(dataEvent, onData);
		dataListeners.push(onData);

		return () => {
			stream.removeListener(dataEvent, onData);

			if (complete) {
				return;
			}

			const idx = dataListeners.indexOf(onData);

			if (idx !== -1) {
				dataListeners.splice(idx, 1);
			}
		};
	});
};
