import "core-js/modules/es.array.join.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.split.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.array.includes.js";
import "core-js/modules/es.string.includes.js";
import "core-js/modules/es.function.name.js";

/* eslint-disable no-underscore-dangle */
var titleCase = function titleCase(str) {
  return str.split('-').map(function (part) {
    return part.charAt(0).toUpperCase() + part.slice(1);
  }).join('');
};

export var getComponentName = function getComponentName(component) {
  if (!component) {
    return undefined;
  }

  if (typeof component === 'string') {
    if (component.includes('-')) {
      return titleCase(component);
    }

    return component;
  }

  if (component.__docgenInfo && component.__docgenInfo.displayName) {
    return component.__docgenInfo.displayName;
  }

  return component.name;
};
export function scrollToElement(element) {
  var block = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 'start';
  element.scrollIntoView({
    behavior: 'smooth',
    block: block,
    inline: 'nearest'
  });
}