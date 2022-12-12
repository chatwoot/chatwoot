import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.replace.js";
import "core-js/modules/es.string.split.js";
import "core-js/modules/es.array.join.js";
import "core-js/modules/es.regexp.constructor.js";
import "core-js/modules/es.regexp.to-string.js";
import "core-js/modules/es.object.get-own-property-names.js";

/* eslint-disable no-param-reassign */
import { sep } from 'path';

// Removes all user paths
function regexpEscape(str) {
  return str.replace(/[-[/{}()*+?.\\^$|]/g, "\\$&");
}

export function cleanPaths(str) {
  var separator = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : sep;
  if (!str) return str;
  var stack = process.cwd().split(separator);

  while (stack.length > 1) {
    var currentPath = stack.join(separator);
    var currentRegex = new RegExp(regexpEscape(currentPath), "g");
    str = str.replace(currentRegex, "$SNIP");
    var currentPath2 = stack.join(separator + separator);
    var currentRegex2 = new RegExp(regexpEscape(currentPath2), "g");
    str = str.replace(currentRegex2, "$SNIP");
    stack.pop();
  }

  return str;
} // Takes an Error and returns a sanitized JSON String

export function sanitizeError(error) {
  var pathSeparator = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : sep;
  // Hack because Node
  error = JSON.parse(JSON.stringify(error, Object.getOwnPropertyNames(error))); // Removes all user paths

  var errorString = cleanPaths(JSON.stringify(error), pathSeparator);
  return JSON.parse(errorString);
}