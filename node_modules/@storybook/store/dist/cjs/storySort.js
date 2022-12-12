"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.storySort = void 0;

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.split.js");

require("core-js/modules/es.string.trim.js");

require("core-js/modules/es.function.name.js");

var STORY_KIND_PATH_SEPARATOR = /\s*\/\s*/;

var storySort = function storySort() {
  var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
  return function (a, b) {
    // If the two stories have the same story kind, then use the default
    // ordering, which is the order they are defined in the story file.
    // only when includeNames is falsy
    if (a.title === b.title && !options.includeNames) {
      return 0;
    } // Get the StorySortParameter options.


    var method = options.method || 'configure';
    var order = options.order || []; // Examine each part of the story title in turn.

    var storyTitleA = a.title.trim().split(STORY_KIND_PATH_SEPARATOR);
    var storyTitleB = b.title.trim().split(STORY_KIND_PATH_SEPARATOR);

    if (options.includeNames) {
      storyTitleA.push(a.name);
      storyTitleB.push(b.name);
    }

    var depth = 0;

    while (storyTitleA[depth] || storyTitleB[depth]) {
      // Stories with a shorter depth should go first.
      if (!storyTitleA[depth]) {
        return -1;
      }

      if (!storyTitleB[depth]) {
        return 1;
      } // Compare the next part of the story title.


      var nameA = storyTitleA[depth];
      var nameB = storyTitleB[depth];

      if (nameA !== nameB) {
        // Look for the names in the given `order` array.
        var indexA = order.indexOf(nameA);
        var indexB = order.indexOf(nameB);
        var indexWildcard = order.indexOf('*'); // If at least one of the names is found, sort by the `order` array.

        if (indexA !== -1 || indexB !== -1) {
          // If one of the names is not found and there is a wildcard, insert it at the wildcard position.
          // Otherwise, list it last.
          if (indexA === -1) {
            if (indexWildcard !== -1) {
              indexA = indexWildcard;
            } else {
              indexA = order.length;
            }
          }

          if (indexB === -1) {
            if (indexWildcard !== -1) {
              indexB = indexWildcard;
            } else {
              indexB = order.length;
            }
          }

          return indexA - indexB;
        } // Use the default configure() order.


        if (method === 'configure') {
          return 0;
        } // Otherwise, use alphabetical order.


        return nameA.localeCompare(nameB, options.locales ? options.locales : undefined, {
          numeric: true,
          sensitivity: 'accent'
        });
      } // If a nested array is provided for a name, use it for ordering.


      var index = order.indexOf(nameA);
      order = index !== -1 && Array.isArray(order[index + 1]) ? order[index + 1] : []; // We'll need to look at the next part of the name.

      depth += 1;
    } // Identical story titles. The shortcut at the start of this function prevents
    // this from ever being used.

    /* istanbul ignore next */


    return 0;
  };
};

exports.storySort = storySort;