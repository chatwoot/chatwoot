'use strict';
const NestedError = require('nested-error-stacks');

class CpyError extends NestedError {
	constructor(message, nested) {
		super(message, nested);
		Object.assign(this, nested);
		this.name = 'CpyError';
	}
}

module.exports = CpyError;
