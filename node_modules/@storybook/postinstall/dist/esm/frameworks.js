import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.object.to-string.js";
var FRAMEWORKS = ['angular', 'ember', 'html', 'marko', 'mithril', 'preact', 'rax', 'react', 'react-native', 'riot', 'svelte', 'vue', 'web-components'];
export var getFrameworks = function getFrameworks(_ref) {
  var dependencies = _ref.dependencies,
      devDependencies = _ref.devDependencies;
  var allDeps = {};
  Object.assign(allDeps, dependencies || {});
  Object.assign(allDeps, devDependencies || {});
  return FRAMEWORKS.filter(function (f) {
    return !!allDeps["@storybook/".concat(f)];
  });
};