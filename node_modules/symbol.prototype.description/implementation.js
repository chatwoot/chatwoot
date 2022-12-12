'use strict';

var getSymbolDescription = require('es-abstract/helpers/getSymbolDescription');

module.exports = function description() {
	return getSymbolDescription(this);
};
