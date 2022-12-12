function arrayClear(array) {
  return array.filter(function (v) { return !!v });
}

/**
 * Return the import path/name of an UMD module for the given module format.
 *
 * @param {string} name - name of the module, used if no other no import path/name can be found.
 * @param {object|string} config - external configuration.
 *  - If a string, returns it (we consider this is the path or name).
 *  - If an object, returns the property within it according to the given `format`,
 *    or the "default" property.
 * @param {string} format - format of the module to look for, if the configuration is an object.
 *
 * @return The found import path/name for the module.
 */
function getUmdEntry(name, config, format) {
  if (typeof config === 'string') {
    return config;
  }
  if (typeof config === 'object') {
    if (config[format] != null) return config[format];
    if (config.default != null) return config.default;
  }
  return name;
}

/**
 * Generate an configuration object for Webpack Externals for UMD modules.
 * See: https://webpack.js.org/configuration/externals/#object
 *
 * @param {object} externals - Configuration object for external UMD modules.
 *  For each entry, a string or an object can be provided.
 *  - If a string, it is used for all module formats.
 *  - If an object, it is used as is and the "default" property or the module
 *    name is used for missing formats.
 * @param {object} {} options- Additional options:
 *  - namespace {string} '' - Global variable in which the modules must be
 *    searched in instead of the root for module-less environments.
 *
 * @return {object} Generated configuration for Webpack Externals
 */
module.exports.umdExternals = function(externals, options) {
  options = Object.assign({ namespace: '' }, options);

  var config = {};

  Object.keys(externals).forEach(function (name) {
    var entryConfig = externals[name];

    config[name] = {
      root:       arrayClear([ options.namespace, getUmdEntry(name, entryConfig, 'root') ]),
      amd:        getUmdEntry(name, entryConfig, 'amd'),
      commonjs:   getUmdEntry(name, entryConfig, 'commonjs'),
      commonjs2:  getUmdEntry(name, entryConfig, 'commonjs2'),
    };
  }, {});

  return config;
};

