const isObject = value => typeof value === 'object' && value !== null;

// Customized for this use-case
const isObjectCustom = value =>
	isObject(value)
	&& !(value instanceof RegExp)
	&& !(value instanceof Error)
	&& !(value instanceof Date);

export const mapObjectSkip = Symbol('mapObjectSkip');

const _mapObject = (object, mapper, options, isSeen = new WeakMap()) => {
	options = {
		deep: false,
		target: {},
		...options,
	};

	if (isSeen.has(object)) {
		return isSeen.get(object);
	}

	isSeen.set(object, options.target);

	const {target} = options;
	delete options.target;

	const mapArray = array => array.map(element => isObjectCustom(element) ? _mapObject(element, mapper, options, isSeen) : element);
	if (Array.isArray(object)) {
		return mapArray(object);
	}

	for (const [key, value] of Object.entries(object)) {
		const mapResult = mapper(key, value, object);

		if (mapResult === mapObjectSkip) {
			continue;
		}

		let [newKey, newValue, {shouldRecurse = true} = {}] = mapResult;

		// Drop `__proto__` keys.
		if (newKey === '__proto__') {
			continue;
		}

		if (options.deep && shouldRecurse && isObjectCustom(newValue)) {
			newValue = Array.isArray(newValue)
				? mapArray(newValue)
				: _mapObject(newValue, mapper, options, isSeen);
		}

		target[newKey] = newValue;
	}

	return target;
};

export default function mapObject(object, mapper, options) {
	if (!isObject(object)) {
		throw new TypeError(`Expected an object, got \`${object}\` (${typeof object})`);
	}

	return _mapObject(object, mapper, options);
}
