"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.pitch = pitch;
exports.default = _default;

var _module = _interopRequireDefault(require("module"));

var _path = _interopRequireDefault(require("path"));

var _loaderUtils = _interopRequireDefault(require("loader-utils"));

var _NodeTemplatePlugin = _interopRequireDefault(require("webpack/lib/node/NodeTemplatePlugin"));

var _NodeTargetPlugin = _interopRequireDefault(require("webpack/lib/node/NodeTargetPlugin"));

var _LibraryTemplatePlugin = _interopRequireDefault(require("webpack/lib/LibraryTemplatePlugin"));

var _SingleEntryPlugin = _interopRequireDefault(require("webpack/lib/SingleEntryPlugin"));

var _LimitChunkCountPlugin = _interopRequireDefault(require("webpack/lib/optimize/LimitChunkCountPlugin"));

var _schemaUtils = _interopRequireDefault(require("schema-utils"));

var _CssDependency = _interopRequireDefault(require("./CssDependency"));

var _options = _interopRequireDefault(require("./options.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); if (enumerableOnly) symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; }); keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; if (i % 2) { ownKeys(Object(source), true).forEach(function (key) { _defineProperty(target, key, source[key]); }); } else if (Object.getOwnPropertyDescriptors) { Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)); } else { ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

const pluginName = 'mini-css-extract-plugin';

function hotLoader(content, context) {
  const accept = context.locals ? '' : 'module.hot.accept(undefined, cssReload);';
  return `${content}
    if(module.hot) {
      // ${Date.now()}
      var cssReload = require(${_loaderUtils.default.stringifyRequest(context.context, _path.default.join(__dirname, 'hmr/hotModuleReplacement.js'))})(module.id, ${JSON.stringify(_objectSpread({}, context.options, {
    locals: !!context.locals
  }))});
      module.hot.dispose(cssReload);
      ${accept}
    }
  `;
}

function evalModuleCode(loaderContext, code, filename) {
  const module = new _module.default(filename, loaderContext);
  module.paths = _module.default._nodeModulePaths(loaderContext.context); // eslint-disable-line no-underscore-dangle

  module.filename = filename;

  module._compile(code, filename); // eslint-disable-line no-underscore-dangle


  return module.exports;
}

function findModuleById(modules, id) {
  for (const module of modules) {
    if (module.id === id) {
      return module;
    }
  }

  return null;
}

function pitch(request) {
  const options = _loaderUtils.default.getOptions(this) || {};
  (0, _schemaUtils.default)(_options.default, options, 'Mini CSS Extract Plugin Loader');
  const loaders = this.loaders.slice(this.loaderIndex + 1);
  this.addDependency(this.resourcePath);
  const childFilename = '*';
  const publicPath = typeof options.publicPath === 'string' ? options.publicPath === '' || options.publicPath.endsWith('/') ? options.publicPath : `${options.publicPath}/` : typeof options.publicPath === 'function' ? options.publicPath(this.resourcePath, this.rootContext) : this._compilation.outputOptions.publicPath;
  const outputOptions = {
    filename: childFilename,
    publicPath
  };

  const childCompiler = this._compilation.createChildCompiler(`${pluginName} ${request}`, outputOptions);

  new _NodeTemplatePlugin.default(outputOptions).apply(childCompiler);
  new _LibraryTemplatePlugin.default(null, 'commonjs2').apply(childCompiler);
  new _NodeTargetPlugin.default().apply(childCompiler);
  new _SingleEntryPlugin.default(this.context, `!!${request}`, pluginName).apply(childCompiler);
  new _LimitChunkCountPlugin.default({
    maxChunks: 1
  }).apply(childCompiler);
  childCompiler.hooks.thisCompilation.tap(`${pluginName} loader`, compilation => {
    compilation.hooks.normalModuleLoader.tap(`${pluginName} loader`, (loaderContext, module) => {
      // eslint-disable-next-line no-param-reassign
      loaderContext.emitFile = this.emitFile;

      if (module.request === request) {
        // eslint-disable-next-line no-param-reassign
        module.loaders = loaders.map(loader => {
          return {
            loader: loader.path,
            options: loader.options,
            ident: loader.ident
          };
        });
      }
    });
  });
  let source;
  childCompiler.hooks.afterCompile.tap(pluginName, compilation => {
    source = compilation.assets[childFilename] && compilation.assets[childFilename].source(); // Remove all chunk assets

    compilation.chunks.forEach(chunk => {
      chunk.files.forEach(file => {
        delete compilation.assets[file]; // eslint-disable-line no-param-reassign
      });
    });
  });
  const callback = this.async();
  childCompiler.runAsChild((err, entries, compilation) => {
    const addDependencies = dependencies => {
      if (!Array.isArray(dependencies) && dependencies != null) {
        throw new Error(`Exported value was not extracted as an array: ${JSON.stringify(dependencies)}`);
      }

      const identifierCountMap = new Map();

      for (const dependency of dependencies) {
        const count = identifierCountMap.get(dependency.identifier) || 0;

        this._module.addDependency(new _CssDependency.default(dependency, dependency.context, count));

        identifierCountMap.set(dependency.identifier, count + 1);
      }
    };

    if (err) {
      return callback(err);
    }

    if (compilation.errors.length > 0) {
      return callback(compilation.errors[0]);
    }

    compilation.fileDependencies.forEach(dep => {
      this.addDependency(dep);
    }, this);
    compilation.contextDependencies.forEach(dep => {
      this.addContextDependency(dep);
    }, this);

    if (!source) {
      return callback(new Error("Didn't get a result from child compiler"));
    }

    let locals;

    try {
      let dependencies;
      let exports = evalModuleCode(this, source, request); // eslint-disable-next-line no-underscore-dangle

      exports = exports.__esModule ? exports.default : exports;
      locals = exports && exports.locals;

      if (!Array.isArray(exports)) {
        dependencies = [[null, exports]];
      } else {
        dependencies = exports.map(([id, content, media, sourceMap]) => {
          const module = findModuleById(compilation.modules, id);
          return {
            identifier: module.identifier(),
            context: module.context,
            content,
            media,
            sourceMap
          };
        });
      }

      addDependencies(dependencies);
    } catch (e) {
      return callback(e);
    }

    const esModule = typeof options.esModule !== 'undefined' ? options.esModule : false;
    const result = locals ? `\n${esModule ? 'export default' : 'module.exports ='} ${JSON.stringify(locals)};` : '';
    let resultSource = `// extracted by ${pluginName}`;
    resultSource += options.hmr ? hotLoader(result, {
      context: this.context,
      options,
      locals
    }) : result;
    return callback(null, resultSource);
  });
}

function _default() {}