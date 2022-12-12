"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.useBaseTsSupport = void 0;

/**
 * Returns true if the framework can use the base TS config.
 * @param {string} framework
 */
var useBaseTsSupport = function (framework) {
  // These packages both have their own TS implementation.
  return !['vue', 'angular'].includes(framework);
};

exports.useBaseTsSupport = useBaseTsSupport;