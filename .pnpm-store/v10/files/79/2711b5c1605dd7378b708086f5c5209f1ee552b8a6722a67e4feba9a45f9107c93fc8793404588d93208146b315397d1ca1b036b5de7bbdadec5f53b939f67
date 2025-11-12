'use strict';

module.exports = function isFullyPopulatedPropertyDescriptor(ES, Desc) {
	return !!Desc
		&& typeof Desc === 'object'
		&& '[[Enumerable]]' in Desc
		&& '[[Configurable]]' in Desc
		&& (ES.IsAccessorDescriptor(Desc) || ES.IsDataDescriptor(Desc));
};
