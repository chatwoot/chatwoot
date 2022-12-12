"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

class SassError extends Error {
  constructor(sassError) {
    super();
    this.name = "SassError";
    this.originalSassError = sassError;
    this.loc = {
      line: sassError.line,
      column: sassError.column
    }; // Keep original error if `sassError.formatted` is unavailable

    this.message = `${this.name}: ${this.originalSassError.message}`;

    if (this.originalSassError.formatted) {
      this.message = `${this.name}: ${this.originalSassError.formatted.replace(/^Error: /, "")}`; // Instruct webpack to hide the JS stack from the console.
      // Usually you're only interested in the SASS stack in this case.

      this.hideStack = true;
      Error.captureStackTrace(this, this.constructor);
    }
  }

}

var _default = SassError;
exports.default = _default;