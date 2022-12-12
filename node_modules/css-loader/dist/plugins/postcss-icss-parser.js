"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _postcss = _interopRequireDefault(require("postcss"));

var _icssUtils = require("icss-utils");

var _loaderUtils = require("loader-utils");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function makeRequestableIcssImports(icssImports) {
  return Object.keys(icssImports).reduce((accumulator, url) => {
    const tokensMap = icssImports[url];
    const tokens = Object.keys(tokensMap);

    if (tokens.length === 0) {
      return accumulator;
    }

    const normalizedUrl = (0, _loaderUtils.urlToRequest)(url);

    if (!accumulator[normalizedUrl]) {
      // eslint-disable-next-line no-param-reassign
      accumulator[normalizedUrl] = tokensMap;
    } else {
      // eslint-disable-next-line no-param-reassign
      accumulator[normalizedUrl] = { ...accumulator[normalizedUrl],
        ...tokensMap
      };
    }

    return accumulator;
  }, {});
}

var _default = _postcss.default.plugin('postcss-icss-parser', options => (css, result) => {
  const importReplacements = Object.create(null);
  const extractedICSS = (0, _icssUtils.extractICSS)(css);
  const icssImports = makeRequestableIcssImports(extractedICSS.icssImports);

  for (const [importIndex, url] of Object.keys(icssImports).entries()) {
    const importName = `___CSS_LOADER_ICSS_IMPORT_${importIndex}___`;
    result.messages.push({
      type: 'import',
      value: {
        importName,
        url: options.urlHandler ? options.urlHandler(url) : url
      }
    }, {
      type: 'api-import',
      value: {
        type: 'internal',
        importName,
        dedupe: true
      }
    });
    const tokenMap = icssImports[url];
    const tokens = Object.keys(tokenMap);

    for (const [replacementIndex, token] of tokens.entries()) {
      const replacementName = `___CSS_LOADER_ICSS_IMPORT_${importIndex}_REPLACEMENT_${replacementIndex}___`;
      const localName = tokenMap[token];
      importReplacements[token] = replacementName;
      result.messages.push({
        type: 'icss-replacement',
        value: {
          replacementName,
          importName,
          localName
        }
      });
    }
  }

  if (Object.keys(importReplacements).length > 0) {
    (0, _icssUtils.replaceSymbols)(css, importReplacements);
  }

  const {
    icssExports
  } = extractedICSS;

  for (const name of Object.keys(icssExports)) {
    const value = (0, _icssUtils.replaceValueSymbols)(icssExports[name], importReplacements);
    result.messages.push({
      type: 'export',
      value: {
        name,
        value
      }
    });
  }
});

exports.default = _default;