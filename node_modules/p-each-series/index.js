'use strict';

const pEachSeries = async (iterable, iterator) => {
	let index = 0;

	for (const value of iterable) {
		// eslint-disable-next-line no-await-in-loop
		const returnValue = await iterator(await value, index++);

		if (returnValue === pEachSeries.stop) {
			break;
		}
	}

	return iterable;
};

pEachSeries.stop = Symbol('pEachSeries.stop');

module.exports = pEachSeries;
// TODO: Remove this for the next major release
module.exports.default = pEachSeries;
