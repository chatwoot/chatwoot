import "core-js/modules/es.array.includes.js";
import "core-js/modules/es.string.includes.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.match.js";
import "core-js/modules/es.function.name.js";
import pickBy from 'lodash/pickBy';

var matches = function matches(name, descriptor) {
  return Array.isArray(descriptor) ? descriptor.includes(name) : name.match(descriptor);
};

export var filterArgTypes = function filterArgTypes(argTypes, include, exclude) {
  if (!include && !exclude) {
    return argTypes;
  }

  return argTypes && pickBy(argTypes, function (argType, key) {
    var name = argType.name || key;
    return (!include || matches(name, include)) && (!exclude || !matches(name, exclude));
  });
};