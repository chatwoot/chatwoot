'use strict';
const NestedError = require('nested-error-stacks');

class CpFileError extends NestedError {
	constructor(message, nested) {
		super(message, nested);
		Object.assign(this, nested);
		this.name = 'CpFileError';
	}
}

module.exports = CpFileError;
