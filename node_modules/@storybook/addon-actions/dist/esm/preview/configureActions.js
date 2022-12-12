import "core-js/modules/es.object.assign.js";
export var config = {
  depth: 10,
  clearOnStoryChange: true,
  limit: 50
};
export var configureActions = function configureActions() {
  var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
  Object.assign(config, options);
};