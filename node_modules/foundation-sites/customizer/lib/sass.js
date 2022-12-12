var empty = require('is-empty-object');
var format = require('util').format;
var stripIndent = require('strip-indent');

var SASS_TEMPLATE = stripIndent(`
  @charset 'utf-8';

  // Variables go here
  %s

  // Core imports go here
  @import 'foundation';
  @import 'motion-ui';

  // Modules go here
  %s

  // Motion UI goes here
  @include motion-ui-transitions;
  @include motion-ui-animations;
`);

/**
 * Generates an entry point Sass file with a custom list of CSS exports and Sass variables.
 * @param {Object} config - Customizer configuration object.
 * @param {String[]} modules - Modules to include CSS for.
 * @param {Object} variables - Sass variable overrides to include. The key is the name of the variable, and the value is the value.
 * @returns {String} Formatted Sass file.
 */
module.exports = function(config, modules, variables) {
  var variableList = [];
  var colorList = {};
  var exportList = ['@include foundation-global-styles;'];

  if (empty(modules)) {
    modules = Object.keys(config);
  }

  // Create variable overrides code
  for (var i in variables) {
    var name = i.replace('_', '-');
    if (name.match(/-color$/)) {
      var key = name.replace('-color', '');
      colorList[key] = variables[i];
    }
    else {
      variableList.push(format('$%s: %s;', name, variables[i]));
    }
  }

  if (!empty(colorList)) {
    variableList.push(createPaletteMap(colorList));
  }

  // Create module exports with @include
  for (var i in modules) {
    var name = modules[i];

    if (config[name] && config[name].sass) {
      exportList.push(format('@include foundation-%s;', config[name].sass));
    }
  }

  return format(SASS_TEMPLATE, variableList.join('\n'), exportList.join('\n'))
}

function createPaletteMap(colors) {
  var output = '$foundation-palette: (%s\n);';
  var keys = '';

  for (var i in colors) {
    keys += format('\n  %s: %s,', i, colors[i]);
  }

  return format(output, keys);
}
