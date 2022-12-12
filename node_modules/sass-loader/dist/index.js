"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _path = _interopRequireDefault(require("path"));

var _schemaUtils = require("schema-utils");

var _loaderUtils = require("loader-utils");

var _options = _interopRequireDefault(require("./options.json"));

var _utils = require("./utils");

var _SassError = _interopRequireDefault(require("./SassError"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * The sass-loader makes node-sass and dart-sass available to webpack modules.
 *
 * @this {object}
 * @param {string} content
 */
async function loader(content) {
  const options = (0, _loaderUtils.getOptions)(this);
  (0, _schemaUtils.validate)(_options.default, options, {
    name: "Sass Loader",
    baseDataPath: "options"
  });
  const callback = this.async();
  const implementation = (0, _utils.getSassImplementation)(this, options.implementation);

  if (!implementation) {
    callback();
    return;
  }

  const useSourceMap = typeof options.sourceMap === "boolean" ? options.sourceMap : this.sourceMap;
  const sassOptions = await (0, _utils.getSassOptions)(this, options, content, implementation, useSourceMap);
  const shouldUseWebpackImporter = typeof options.webpackImporter === "boolean" ? options.webpackImporter : true;

  if (shouldUseWebpackImporter) {
    const {
      includePaths
    } = sassOptions;
    sassOptions.importer.push((0, _utils.getWebpackImporter)(this, implementation, includePaths));
  }

  const render = (0, _utils.getRenderFunctionFromSassImplementation)(implementation);
  render(sassOptions, (error, result) => {
    if (error) {
      // There are situations when the `file` property do not exist
      if (error.file) {
        // `node-sass` returns POSIX paths
        this.addDependency(_path.default.normalize(error.file));
      }

      callback(new _SassError.default(error));
      return;
    }

    let map = result.map ? JSON.parse(result.map) : null; // Modify source paths only for webpack, otherwise we do nothing

    if (map && useSourceMap) {
      map = (0, _utils.normalizeSourceMap)(map, this.rootContext);
    }

    result.stats.includedFiles.forEach(includedFile => {
      const normalizedIncludedFile = _path.default.normalize(includedFile); // Custom `importer` can return only `contents` so includedFile will be relative


      if (_path.default.isAbsolute(normalizedIncludedFile)) {
        this.addDependency(normalizedIncludedFile);
      }
    });
    callback(null, result.css.toString(), map);
  });
}

var _default = loader;
exports.default = _default;