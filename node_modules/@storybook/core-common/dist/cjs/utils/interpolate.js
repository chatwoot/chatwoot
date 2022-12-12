"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.interpolate = void 0;

/**
 * Return a string corresponding to template filled with bindings using following pattern:
 * For each (key, value) of `bindings` replace, in template, `{{key}}` by escaped version of `value`
 *
 * @param template {String} Template with `{{binding}}`
 * @param bindings {Object} key-value object use to fill the template, `{{key}}` will be replaced by `escaped(value)`
 * @returns {String} Filled template
 */
var interpolate = function (template, bindings) {
  return Object.entries(bindings).reduce(function (acc, [k, v]) {
    var escapedString = v.replace(/\\/g, '/').replace(/\$/g, '$$$');
    return acc.replace(new RegExp(`{{${k}}}`, 'g'), escapedString);
  }, template);
};

exports.interpolate = interpolate;