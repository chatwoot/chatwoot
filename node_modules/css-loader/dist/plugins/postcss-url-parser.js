"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _postcss = _interopRequireDefault(require("postcss"));

var _postcssValueParser = _interopRequireDefault(require("postcss-value-parser"));

var _utils = require("../utils");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const pluginName = 'postcss-url-parser';
const isUrlFunc = /url/i;
const isImageSetFunc = /^(?:-webkit-)?image-set$/i;
const needParseDecl = /(?:url|(?:-webkit-)?image-set)\(/i;

function getNodeFromUrlFunc(node) {
  return node.nodes && node.nodes[0];
}

function walkUrls(parsed, callback) {
  parsed.walk(node => {
    if (node.type !== 'function') {
      return;
    }

    if (isUrlFunc.test(node.value)) {
      const {
        nodes
      } = node;
      const isStringValue = nodes.length !== 0 && nodes[0].type === 'string';
      const url = isStringValue ? nodes[0].value : _postcssValueParser.default.stringify(nodes);
      callback(getNodeFromUrlFunc(node), url, false, isStringValue); // Do not traverse inside `url`
      // eslint-disable-next-line consistent-return

      return false;
    }

    if (isImageSetFunc.test(node.value)) {
      for (const nNode of node.nodes) {
        const {
          type,
          value
        } = nNode;

        if (type === 'function' && isUrlFunc.test(value)) {
          const {
            nodes
          } = nNode;
          const isStringValue = nodes.length !== 0 && nodes[0].type === 'string';
          const url = isStringValue ? nodes[0].value : _postcssValueParser.default.stringify(nodes);
          callback(getNodeFromUrlFunc(nNode), url, false, isStringValue);
        }

        if (type === 'string') {
          callback(nNode, value, true, true);
        }
      } // Do not traverse inside `image-set`
      // eslint-disable-next-line consistent-return


      return false;
    }
  });
}

var _default = _postcss.default.plugin(pluginName, options => (css, result) => {
  const importsMap = new Map();
  const replacementsMap = new Map();
  let hasHelper = false;
  css.walkDecls(decl => {
    if (!needParseDecl.test(decl.value)) {
      return;
    }

    const parsed = (0, _postcssValueParser.default)(decl.value);
    walkUrls(parsed, (node, url, needQuotes, isStringValue) => {
      // https://www.w3.org/TR/css-syntax-3/#typedef-url-token
      if (url.replace(/^[\s]+|[\s]+$/g, '').length === 0) {
        result.warn(`Unable to find uri in '${decl ? decl.toString() : decl.value}'`, {
          node: decl
        });
        return;
      }

      if (options.filter && !options.filter(url)) {
        return;
      }

      const splittedUrl = url.split(/(\?)?#/);
      const [urlWithoutHash, singleQuery, hashValue] = splittedUrl;
      const hash = singleQuery || hashValue ? `${singleQuery ? '?' : ''}${hashValue ? `#${hashValue}` : ''}` : '';
      const normalizedUrl = (0, _utils.normalizeUrl)(urlWithoutHash, isStringValue);
      const importKey = normalizedUrl;
      let importName = importsMap.get(importKey);

      if (!importName) {
        importName = `___CSS_LOADER_URL_IMPORT_${importsMap.size}___`;
        importsMap.set(importKey, importName);

        if (!hasHelper) {
          const urlToHelper = require.resolve('../runtime/getUrl.js');

          result.messages.push({
            pluginName,
            type: 'import',
            value: {
              importName: '___CSS_LOADER_GET_URL_IMPORT___',
              url: options.urlHandler ? options.urlHandler(urlToHelper) : urlToHelper
            }
          });
          hasHelper = true;
        }

        result.messages.push({
          pluginName,
          type: 'import',
          value: {
            importName,
            url: options.urlHandler ? options.urlHandler(normalizedUrl) : normalizedUrl
          }
        });
      }

      const replacementKey = JSON.stringify({
        importKey,
        hash,
        needQuotes
      });
      let replacementName = replacementsMap.get(replacementKey);

      if (!replacementName) {
        replacementName = `___CSS_LOADER_URL_REPLACEMENT_${replacementsMap.size}___`;
        replacementsMap.set(replacementKey, replacementName);
        result.messages.push({
          pluginName,
          type: 'url-replacement',
          value: {
            replacementName,
            importName,
            hash,
            needQuotes
          }
        });
      } // eslint-disable-next-line no-param-reassign


      node.type = 'word'; // eslint-disable-next-line no-param-reassign

      node.value = replacementName;
    }); // eslint-disable-next-line no-param-reassign

    decl.value = parsed.toString();
  });
});

exports.default = _default;