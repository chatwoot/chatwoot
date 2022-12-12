"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.normalizeUrl = normalizeUrl;
exports.getFilter = getFilter;
exports.getModulesPlugins = getModulesPlugins;
exports.normalizeSourceMap = normalizeSourceMap;
exports.getPreRequester = getPreRequester;
exports.getImportCode = getImportCode;
exports.getModuleCode = getModuleCode;
exports.getExportCode = getExportCode;
exports.shouldUseModulesPlugins = shouldUseModulesPlugins;

var _path = _interopRequireDefault(require("path"));

var _loaderUtils = require("loader-utils");

var _normalizePath = _interopRequireDefault(require("normalize-path"));

var _cssesc = _interopRequireDefault(require("cssesc"));

var _postcssModulesValues = _interopRequireDefault(require("postcss-modules-values"));

var _postcssModulesLocalByDefault = _interopRequireDefault(require("postcss-modules-local-by-default"));

var _postcssModulesExtractImports = _interopRequireDefault(require("postcss-modules-extract-imports"));

var _postcssModulesScope = _interopRequireDefault(require("postcss-modules-scope"));

var _camelcase = _interopRequireDefault(require("camelcase"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/*
  MIT License http://www.opensource.org/licenses/mit-license.php
  Author Tobias Koppers @sokra
*/
const whitespace = '[\\x20\\t\\r\\n\\f]';
const unescapeRegExp = new RegExp(`\\\\([\\da-f]{1,6}${whitespace}?|(${whitespace})|.)`, 'ig');

function unescape(str) {
  return str.replace(unescapeRegExp, (_, escaped, escapedWhitespace) => {
    const high = `0x${escaped}` - 0x10000;
    /* eslint-disable line-comment-position */
    // NaN means non-codepoint
    // Workaround erroneous numeric interpretation of +"0x"
    // eslint-disable-next-line no-self-compare

    return high !== high || escapedWhitespace ? escaped : high < 0 ? // BMP codepoint
    String.fromCharCode(high + 0x10000) : // Supplemental Plane codepoint (surrogate pair)
    // eslint-disable-next-line no-bitwise
    String.fromCharCode(high >> 10 | 0xd800, high & 0x3ff | 0xdc00);
    /* eslint-enable line-comment-position */
  });
} // eslint-disable-next-line no-control-regex


const filenameReservedRegex = /[<>:"/\\|?*\x00-\x1F]/g; // eslint-disable-next-line no-control-regex

const reControlChars = /[\u0000-\u001f\u0080-\u009f]/g;
const reRelativePath = /^\.+/;

function getLocalIdent(loaderContext, localIdentName, localName, options) {
  if (!options.context) {
    // eslint-disable-next-line no-param-reassign
    options.context = loaderContext.rootContext;
  }

  const request = (0, _normalizePath.default)(_path.default.relative(options.context || '', loaderContext.resourcePath)); // eslint-disable-next-line no-param-reassign

  options.content = `${options.hashPrefix + request}+${unescape(localName)}`; // Using `[path]` placeholder outputs `/` we need escape their
  // Also directories can contains invalid characters for css we need escape their too

  return (0, _cssesc.default)((0, _loaderUtils.interpolateName)(loaderContext, localIdentName, options) // For `[hash]` placeholder
  .replace(/^((-?[0-9])|--)/, '_$1').replace(filenameReservedRegex, '-').replace(reControlChars, '-').replace(reRelativePath, '-').replace(/\./g, '-'), {
    isIdentifier: true
  }).replace(/\\\[local\\\]/gi, localName);
}

function normalizeUrl(url, isStringValue) {
  let normalizedUrl = url;

  if (isStringValue && /\\[\n]/.test(normalizedUrl)) {
    normalizedUrl = normalizedUrl.replace(/\\[\n]/g, '');
  }

  return (0, _loaderUtils.urlToRequest)(decodeURIComponent(unescape(normalizedUrl)));
}

function getFilter(filter, resourcePath, defaultFilter = null) {
  return item => {
    if (defaultFilter && !defaultFilter(item)) {
      return false;
    }

    if (typeof filter === 'function') {
      return filter(item, resourcePath);
    }

    return true;
  };
}

function shouldUseModulesPlugins(modules, resourcePath) {
  if (typeof modules === 'undefined') {
    return false;
  }

  if (typeof modules === 'boolean') {
    return modules;
  }

  if (typeof modules === 'string') {
    return true;
  }

  if (typeof modules.auto === 'boolean') {
    return modules.auto ? /\.module\.\w+$/i.test(resourcePath) : false;
  }

  if (modules.auto instanceof RegExp) {
    return modules.auto.test(resourcePath);
  }

  if (typeof modules.auto === 'function') {
    return modules.auto(resourcePath);
  }

  return true;
}

function getModulesPlugins(options, loaderContext) {
  let modulesOptions = {
    mode: 'local',
    exportGlobals: false,
    localIdentName: '[hash:base64]',
    getLocalIdent,
    hashPrefix: '',
    localIdentRegExp: null
  };

  if (typeof options.modules === 'boolean' || typeof options.modules === 'string') {
    modulesOptions.mode = typeof options.modules === 'string' ? options.modules : 'local';
  } else {
    modulesOptions = Object.assign({}, modulesOptions, options.modules);
  }

  if (typeof modulesOptions.mode === 'function') {
    modulesOptions.mode = modulesOptions.mode(loaderContext.resourcePath);
  }

  let plugins = [];

  try {
    plugins = [_postcssModulesValues.default, (0, _postcssModulesLocalByDefault.default)({
      mode: modulesOptions.mode
    }), (0, _postcssModulesExtractImports.default)(), (0, _postcssModulesScope.default)({
      generateScopedName: function generateScopedName(exportName) {
        let localIdent = modulesOptions.getLocalIdent(loaderContext, modulesOptions.localIdentName, exportName, {
          context: modulesOptions.context,
          hashPrefix: modulesOptions.hashPrefix,
          regExp: modulesOptions.localIdentRegExp
        });

        if (!localIdent) {
          localIdent = getLocalIdent(loaderContext, modulesOptions.localIdentName, exportName, {
            context: modulesOptions.context,
            hashPrefix: modulesOptions.hashPrefix,
            regExp: modulesOptions.localIdentRegExp
          });
        }

        return localIdent;
      },
      exportGlobals: modulesOptions.exportGlobals
    })];
  } catch (error) {
    loaderContext.emitError(error);
  }

  return plugins;
}

function normalizeSourceMap(map) {
  let newMap = map; // Some loader emit source map as string
  // Strip any JSON XSSI avoidance prefix from the string (as documented in the source maps specification), and then parse the string as JSON.

  if (typeof newMap === 'string') {
    newMap = JSON.parse(newMap);
  } // Source maps should use forward slash because it is URLs (https://github.com/mozilla/source-map/issues/91)
  // We should normalize path because previous loaders like `sass-loader` using backslash when generate source map


  if (newMap.file) {
    newMap.file = (0, _normalizePath.default)(newMap.file);
  }

  if (newMap.sourceRoot) {
    newMap.sourceRoot = (0, _normalizePath.default)(newMap.sourceRoot);
  }

  if (newMap.sources) {
    newMap.sources = newMap.sources.map(source => (0, _normalizePath.default)(source));
  }

  return newMap;
}

function getPreRequester({
  loaders,
  loaderIndex
}) {
  const cache = Object.create(null);
  return number => {
    if (cache[number]) {
      return cache[number];
    }

    if (number === false) {
      cache[number] = '';
    } else {
      const loadersRequest = loaders.slice(loaderIndex, loaderIndex + 1 + (typeof number !== 'number' ? 0 : number)).map(x => x.request).join('!');
      cache[number] = `-!${loadersRequest}!`;
    }

    return cache[number];
  };
}

function getImportCode(loaderContext, exportType, imports, esModule) {
  let code = '';

  if (exportType === 'full') {
    const apiUrl = (0, _loaderUtils.stringifyRequest)(loaderContext, require.resolve('./runtime/api'));
    code += esModule ? `import ___CSS_LOADER_API_IMPORT___ from ${apiUrl};\n` : `var ___CSS_LOADER_API_IMPORT___ = require(${apiUrl});\n`;
  }

  for (const item of imports) {
    const {
      importName,
      url
    } = item;
    code += esModule ? `import ${importName} from ${url};\n` : `var ${importName} = require(${url});\n`;
  }

  return code ? `// Imports\n${code}` : '';
}

function getModuleCode(result, exportType, sourceMap, apiImports, urlReplacements, icssReplacements, esModule) {
  if (exportType !== 'full') {
    return '';
  }

  const {
    css,
    map
  } = result;
  const sourceMapValue = sourceMap && map ? `,${map}` : '';
  let code = JSON.stringify(css);
  let beforeCode = '';
  beforeCode += esModule ? `var exports = ___CSS_LOADER_API_IMPORT___(${sourceMap});\n` : `exports = ___CSS_LOADER_API_IMPORT___(${sourceMap});\n`;

  for (const item of apiImports) {
    const {
      type,
      media,
      dedupe
    } = item;
    beforeCode += type === 'internal' ? `exports.i(${item.importName}${media ? `, ${JSON.stringify(media)}` : dedupe ? ', ""' : ''}${dedupe ? ', true' : ''});\n` : `exports.push([module.id, ${JSON.stringify(`@import url(${item.url});`)}${media ? `, ${JSON.stringify(media)}` : ''}]);\n`;
  }

  for (const item of urlReplacements) {
    const {
      replacementName,
      importName,
      hash,
      needQuotes
    } = item;
    const getUrlOptions = [].concat(hash ? [`hash: ${JSON.stringify(hash)}`] : []).concat(needQuotes ? 'needQuotes: true' : []);
    const preparedOptions = getUrlOptions.length > 0 ? `, { ${getUrlOptions.join(', ')} }` : '';
    beforeCode += `var ${replacementName} = ___CSS_LOADER_GET_URL_IMPORT___(${importName}${preparedOptions});\n`;
    code = code.replace(new RegExp(replacementName, 'g'), () => `" + ${replacementName} + "`);
  }

  for (const replacement of icssReplacements) {
    const {
      replacementName,
      importName,
      localName
    } = replacement;
    code = code.replace(new RegExp(replacementName, 'g'), () => `" + ${importName}.locals[${JSON.stringify(localName)}] + "`);
  }

  return `${beforeCode}// Module\nexports.push([module.id, ${code}, ""${sourceMapValue}]);\n`;
}

function dashesCamelCase(str) {
  return str.replace(/-+(\w)/g, (match, firstLetter) => firstLetter.toUpperCase());
}

function getExportCode(exports, exportType, localsConvention, icssReplacements, esModule) {
  let code = '';
  let localsCode = '';

  const addExportToLocalsCode = (name, value) => {
    if (localsCode) {
      localsCode += `,\n`;
    }

    localsCode += `\t${JSON.stringify(name)}: ${JSON.stringify(value)}`;
  };

  for (const {
    name,
    value
  } of exports) {
    switch (localsConvention) {
      case 'camelCase':
        {
          addExportToLocalsCode(name, value);
          const modifiedName = (0, _camelcase.default)(name);

          if (modifiedName !== name) {
            addExportToLocalsCode(modifiedName, value);
          }

          break;
        }

      case 'camelCaseOnly':
        {
          addExportToLocalsCode((0, _camelcase.default)(name), value);
          break;
        }

      case 'dashes':
        {
          addExportToLocalsCode(name, value);
          const modifiedName = dashesCamelCase(name);

          if (modifiedName !== name) {
            addExportToLocalsCode(modifiedName, value);
          }

          break;
        }

      case 'dashesOnly':
        {
          addExportToLocalsCode(dashesCamelCase(name), value);
          break;
        }

      case 'asIs':
      default:
        addExportToLocalsCode(name, value);
        break;
    }
  }

  for (const replacement of icssReplacements) {
    const {
      replacementName,
      importName,
      localName
    } = replacement;
    localsCode = localsCode.replace(new RegExp(replacementName, 'g'), () => exportType === 'locals' ? `" + ${importName}[${JSON.stringify(localName)}] + "` : `" + ${importName}.locals[${JSON.stringify(localName)}] + "`);
  }

  if (exportType === 'locals') {
    code += `${esModule ? 'export default' : 'module.exports ='} ${localsCode ? `{\n${localsCode}\n}` : '{}'};\n`;
  } else {
    if (localsCode) {
      code += `exports.locals = {\n${localsCode}\n};\n`;
    }

    code += `${esModule ? 'export default' : 'module.exports ='} exports;\n`;
  }

  return `// Exports\n${code}`;
}