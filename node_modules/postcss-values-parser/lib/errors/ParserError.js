'use strict';

class ParserError extends Error {
  constructor(message) {
    super(message);

    this.name = this.constructor.name;
    this.message = message || 'An error ocurred while parsing.';

    if (typeof Error.captureStackTrace === 'function') {
      Error.captureStackTrace(this, this.constructor);
    }
    else {
      this.stack = (new Error(message)).stack;
    }
  }
}

module.exports = ParserError;
