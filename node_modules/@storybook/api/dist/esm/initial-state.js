import "core-js/modules/es.object.to-string.js";
import merge from './lib/merge';

// Returns the initialState of the app
var main = function main() {
  for (var _len = arguments.length, additions = new Array(_len), _key = 0; _key < _len; _key++) {
    additions[_key] = arguments[_key];
  }

  return additions.reduce(function (acc, item) {
    return merge(acc, item);
  }, {});
};

export default main;