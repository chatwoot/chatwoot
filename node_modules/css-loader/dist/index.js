"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = loader;

var _loaderUtils = require("loader-utils");

var _postcss = _interopRequireDefault(require("postcss"));

var _package = _interopRequireDefault(require("postcss/package.json"));

var _schemaUtils = _interopRequireDefault(require("schema-utils"));

var _semver = require("semver");

var _CssSyntaxError = _interopRequireDefault(require("./CssSyntaxError"));

var _Warning = _interopRequireDefault(require("./Warning"));

var _options = _interopRequireDefault(require("./options.json"));

var _plugins = require("./plugins");

var _utils = require("./utils");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/*
  MIT License http://www.opensource.org/licenses/mit-license.php
  Author Tobias Koppers @sokra
*/
function loader(content, map, meta) {
  const options = (0, _loaderUtils.getOptions)(this) || {};
  (0, _schemaUtils.default)(_options.default, options, {
    name: 'CSS Loader',
    baseDataPath: 'options'
  });
  const callback = this.async();
  const sourceMap = options.sourceMap || false;
  const plugins = [];

  if ((0, _utils.shouldUseModulesPlugins)(options.modules, this.resourcePath)) {
    plugins.push(...(0, _utils.getModulesPlugins)(options, this));
  }

  const exportType = options.onlyLocals ? 'locals' : 'full';
  const preRequester = (0, _utils.getPreRequester)(this);

  const urlHandler = url => (0, _loaderUtils.stringifyRequest)(this, preRequester(options.importLoaders) + url);

  plugins.push((0, _plugins.icssParser)({
    urlHandler
  }));

  if (options.import !== false && exportType === 'full') {
    plugins.push((0, _plugins.importParser)({
      filter: (0, _utils.getFilter)(options.import, this.resourcePath),
      urlHandler
    }));
  }

  if (options.url !== false && exportType === 'full') {
    plugins.push((0, _plugins.urlParser)({
      filter: (0, _utils.getFilter)(options.url, this.resourcePath, value => (0, _loaderUtils.isUrlRequest)(value)),
      urlHandler: url => (0, _loaderUtils.stringifyRequest)(this, url)
    }));
  } // Reuse CSS AST (PostCSS AST e.g 'postcss-loader') to avoid reparsing


  if (meta) {
    const {
      ast
    } = meta;

    if (ast && ast.type === 'postcss' && (0, _semver.satisfies)(ast.version, `^${_package.default.version}`)) {
      // eslint-disable-next-line no-param-reassign
      content = ast.root;
    }
  }

  (0, _postcss.default)(plugins).process(content, {
    from: this.resourcePath,
    to: this.resourcePath,
    map: options.sourceMap ? {
      // Some loaders (example `"postcss-loader": "1.x.x"`) always generates source map, we should remove it
      prev: sourceMap && map ? (0, _utils.normalizeSourceMap)(map) : null,
      inline: false,
      annotation: false
    } : false
  }).then(result => {
    for (const warning of result.warnings()) {
      this.emitWarning(new _Warning.default(warning));
    }

    const imports = [];
    const apiImports = [];
    const urlReplacements = [];
    const icssReplacements = [];
    const exports = [];

    for (const message of result.messages) {
      // eslint-disable-next-line default-case
      switch (message.type) {
        case 'import':
          imports.push(message.value);
          break;

        case 'api-import':
          apiImports.push(message.value);
          break;

        case 'url-replacement':
          urlReplacements.push(message.value);
          break;

        case 'icss-replacement':
          icssReplacements.push(message.value);
          break;

        case 'export':
          exports.push(message.value);
          break;
      }
    }

    const {
      localsConvention
    } = options;
    const esModule = typeof options.esModule !== 'undefined' ? options.esModule : false;
    const importCode = (0, _utils.getImportCode)(this, exportType, imports, esModule);
    const moduleCode = (0, _utils.getModuleCode)(result, exportType, sourceMap, apiImports, urlReplacements, icssReplacements, esModule);
    const exportCode = (0, _utils.getExportCode)(exports, exportType, localsConvention, icssReplacements, esModule);
    return callback(null, `${importCode}${moduleCode}${exportCode}`);
  }).catch(error => {
    if (error.file) {
      this.addDependency(error.file);
    }

    callback(error.name === 'CssSyntaxError' ? new _CssSyntaxError.default(error) : error);
  });
}