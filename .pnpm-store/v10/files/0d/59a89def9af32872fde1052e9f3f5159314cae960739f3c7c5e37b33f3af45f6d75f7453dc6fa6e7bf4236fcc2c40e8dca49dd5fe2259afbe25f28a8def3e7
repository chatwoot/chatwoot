'use strict';

var core = require('@formkit/core');

// packages/dev/src/index.ts
var errors = {
  /**
   * FormKit errors:
   */
  100: ({ data: node }) => `Only groups, lists, and forms can have children (${node.name}).`,
  101: ({ data: node }) => `You cannot directly modify the store (${node.name}). See: https://formkit.com/advanced/core#message-store`,
  102: ({
    data: [node, property]
  }) => `You cannot directly assign node.${property} (${node.name})`,
  103: ({ data: [operator] }) => `Schema expressions cannot start with an operator (${operator})`,
  104: ({ data: [operator, expression] }) => `Schema expressions cannot end with an operator (${operator} in "${expression}")`,
  105: ({ data: expression }) => `Invalid schema expression: ${expression}`,
  106: ({ data: name }) => `Cannot submit because (${name}) is not in a form.`,
  107: ({ data: [node, value] }) => `Cannot set ${node.name} to non object value: ${value}`,
  108: ({ data: [node, value] }) => `Cannot set ${node.name} to non array value: ${value}`,
  /**
   * Input specific errors:
   */
  300: ({ data: [node] }) => `Cannot set behavior prop to overscroll (on ${node.name} input) when options prop is a function.`,
  /**
   * FormKit vue errors:
   */
  600: ({ data: node }) => `Unknown input type${typeof node.props.type === "string" ? ' "' + node.props.type + '"' : ""} ("${node.name}")`,
  601: ({ data: node }) => `Input definition${typeof node.props.type === "string" ? ' "' + node.props.type + '"' : ""} is missing a schema or component property (${node.name}).`
};
var warnings = {
  /**
   * Core warnings:
   */
  150: ({ data: fn }) => `Schema function "${fn}()" is not a valid function.`,
  151: ({ data: id }) => `No form element with id: ${id}`,
  152: ({ data: id }) => `No input element with id: ${id}`,
  /**
   * Input specific warnings:
   */
  350: ({
    data: { node, inputType }
  }) => `Invalid options prop for ${node.name} input (${inputType}). See https://formkit.com/inputs/${inputType}`,
  /**
   * Vue warnings:
   */
  650: 'Schema "$get()" must use the id of an input to access.',
  651: ({ data: id }) => `Cannot setErrors() on "${id}" because no such id exists.`,
  652: ({ data: id }) => `Cannot clearErrors() on "${id}" because no such id exists.`,
  /**
   * Deprecation warnings:
   */
  800: ({ data: name }) => `${name} is deprecated.`
};
var decodeErrors = (error, next) => {
  if (error.code in errors) {
    const err = errors[error.code];
    error.message = typeof err === "function" ? err(error) : err;
  }
  return next(error);
};
var registered = false;
function register() {
  if (!registered) {
    core.errorHandler(decodeErrors);
    core.warningHandler(decodeWarnings);
    registered = true;
  }
}
var decodeWarnings = (warning, next) => {
  if (warning.code in warnings) {
    const warn = warnings[warning.code];
    warning.message = typeof warn === "function" ? warn(warning) : warn;
  }
  return next(warning);
};

exports.errors = errors;
exports.register = register;
exports.warnings = warnings;
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.cjs.map