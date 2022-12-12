import "regenerator-runtime/runtime.js";

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.object.entries.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.string.trim.js";
import "core-js/modules/es.regexp.to-string.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.regexp.exec.js";
import { _ as __awaiter, S as ScrollArea, a as __rest, A as ActionBar, w as window_1 } from './index-b45716e8.js';
import React__default, { useState, useCallback } from 'react';
import { logger } from '@storybook/client-logger';
import { styled } from '@storybook/theming';
import memoize from 'memoizerific';
import jsx from 'react-syntax-highlighter/dist/esm/languages/prism/jsx';
import bash from 'react-syntax-highlighter/dist/esm/languages/prism/bash';
import css from 'react-syntax-highlighter/dist/esm/languages/prism/css';
import jsExtras from 'react-syntax-highlighter/dist/esm/languages/prism/js-extras';
import json from 'react-syntax-highlighter/dist/esm/languages/prism/json';
import graphql from 'react-syntax-highlighter/dist/esm/languages/prism/graphql';
import html from 'react-syntax-highlighter/dist/esm/languages/prism/markup';
import md from 'react-syntax-highlighter/dist/esm/languages/prism/markdown';
import yml from 'react-syntax-highlighter/dist/esm/languages/prism/yaml';
import tsx from 'react-syntax-highlighter/dist/esm/languages/prism/tsx';
import typescript from 'react-syntax-highlighter/dist/esm/languages/prism/typescript';
import ReactSyntaxHighlighter from 'react-syntax-highlighter/dist/esm/prism-light';
import '@storybook/csf';
import 'qs';
var navigator = window_1.navigator,
    document = window_1.document,
    globalWindow = window_1.window;
ReactSyntaxHighlighter.registerLanguage('jsextra', jsExtras);
ReactSyntaxHighlighter.registerLanguage('jsx', jsx);
ReactSyntaxHighlighter.registerLanguage('json', json);
ReactSyntaxHighlighter.registerLanguage('yml', yml);
ReactSyntaxHighlighter.registerLanguage('md', md);
ReactSyntaxHighlighter.registerLanguage('bash', bash);
ReactSyntaxHighlighter.registerLanguage('css', css);
ReactSyntaxHighlighter.registerLanguage('html', html);
ReactSyntaxHighlighter.registerLanguage('tsx', tsx);
ReactSyntaxHighlighter.registerLanguage('typescript', typescript);
ReactSyntaxHighlighter.registerLanguage('graphql', graphql);
var themedSyntax = memoize(2)(function (theme) {
  return Object.entries(theme.code || {}).reduce(function (acc, _ref) {
    var _ref2 = _slicedToArray(_ref, 2),
        key = _ref2[0],
        val = _ref2[1];

    return Object.assign(Object.assign({}, acc), _defineProperty({}, "* .".concat(key), val));
  }, {});
});
var copyToClipboard = createCopyToClipboardFunction();

function createCopyToClipboardFunction() {
  var _this = this;

  if (navigator === null || navigator === void 0 ? void 0 : navigator.clipboard) {
    return function (text) {
      return navigator.clipboard.writeText(text);
    };
  }

  return function (text) {
    return __awaiter(_this, void 0, void 0, /*#__PURE__*/regeneratorRuntime.mark(function _callee() {
      var tmp, focus;
      return regeneratorRuntime.wrap(function _callee$(_context) {
        while (1) {
          switch (_context.prev = _context.next) {
            case 0:
              tmp = document.createElement('TEXTAREA');
              focus = document.activeElement;
              tmp.value = text;
              document.body.appendChild(tmp);
              tmp.select();
              document.execCommand('copy');
              document.body.removeChild(tmp);
              focus.focus();

            case 8:
            case "end":
              return _context.stop();
          }
        }
      }, _callee);
    }));
  };
}

var Wrapper = styled.div(function (_ref3) {
  var theme = _ref3.theme;
  return {
    position: 'relative',
    overflow: 'hidden',
    color: theme.color.defaultText
  };
}, function (_ref4) {
  var theme = _ref4.theme,
      bordered = _ref4.bordered;
  return bordered ? {
    border: "1px solid ".concat(theme.appBorderColor),
    borderRadius: theme.borderRadius,
    background: theme.background.content
  } : {};
});
var Scroller = styled(function (_ref5) {
  var children = _ref5.children,
      className = _ref5.className;
  return React__default.createElement(ScrollArea, {
    horizontal: true,
    vertical: true,
    className: className
  }, children);
})({
  position: 'relative'
}, function (_ref6) {
  var theme = _ref6.theme;
  return themedSyntax(theme);
});
var Pre = styled.pre(function (_ref7) {
  var theme = _ref7.theme,
      padded = _ref7.padded;
  return {
    display: 'flex',
    justifyContent: 'flex-start',
    margin: 0,
    padding: padded ? theme.layoutMargin : 0
  };
});
/*
We can't use `code` since PrismJS races for it.
See https://github.com/storybookjs/storybook/issues/18090
 */

var Code = styled.div(function (_ref8) {
  var theme = _ref8.theme;
  return {
    flex: 1,
    paddingLeft: 2,
    paddingRight: theme.layoutMargin,
    opacity: 1
  };
}); // copied from @types/react-syntax-highlighter/index.d.ts

var SyntaxHighlighter = function SyntaxHighlighter(_a) {
  var children = _a.children,
      _a$language = _a.language,
      language = _a$language === void 0 ? 'jsx' : _a$language,
      _a$copyable = _a.copyable,
      copyable = _a$copyable === void 0 ? false : _a$copyable,
      _a$bordered = _a.bordered,
      bordered = _a$bordered === void 0 ? false : _a$bordered,
      _a$padded = _a.padded,
      padded = _a$padded === void 0 ? false : _a$padded,
      _a$format = _a.format,
      format = _a$format === void 0 ? true : _a$format,
      _a$formatter = _a.formatter,
      formatter = _a$formatter === void 0 ? null : _a$formatter,
      _a$className = _a.className,
      className = _a$className === void 0 ? null : _a$className,
      _a$showLineNumbers = _a.showLineNumbers,
      showLineNumbers = _a$showLineNumbers === void 0 ? false : _a$showLineNumbers,
      rest = __rest(_a, ["children", "language", "copyable", "bordered", "padded", "format", "formatter", "className", "showLineNumbers"]);

  if (typeof children !== 'string' || !children.trim()) {
    return null;
  }

  var highlightableCode = formatter ? formatter(format, children) : children.trim();

  var _useState = useState(false),
      _useState2 = _slicedToArray(_useState, 2),
      copied = _useState2[0],
      setCopied = _useState2[1];

  var onClick = useCallback(function (e) {
    e.preventDefault();
    var selectedText = globalWindow.getSelection().toString();
    var textToCopy = e.type !== 'click' && selectedText ? selectedText : highlightableCode;
    copyToClipboard(textToCopy).then(function () {
      setCopied(true);
      globalWindow.setTimeout(function () {
        return setCopied(false);
      }, 1500);
    }).catch(logger.error);
  }, []);
  return React__default.createElement(Wrapper, {
    bordered: bordered,
    padded: padded,
    className: className,
    onCopyCapture: onClick
  }, React__default.createElement(Scroller, null, React__default.createElement(ReactSyntaxHighlighter, Object.assign({
    padded: padded || bordered,
    language: language,
    showLineNumbers: showLineNumbers,
    showInlineLineNumbers: showLineNumbers,
    useInlineStyles: false,
    PreTag: Pre,
    CodeTag: Code,
    lineNumberContainerStyle: {}
  }, rest), highlightableCode)), copyable ? React__default.createElement(ActionBar, {
    actionItems: [{
      title: copied ? 'Copied' : 'Copy',
      onClick: onClick
    }]
  }) : null);
};

export { SyntaxHighlighter, createCopyToClipboardFunction, SyntaxHighlighter as default };
