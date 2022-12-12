'use strict';

var index = require('./index-967d55af.js');

var React = require('react');

var clientLogger = require('@storybook/client-logger');

var theming = require('@storybook/theming');

var memoize = require('memoizerific');

var jsx = require('react-syntax-highlighter/dist/esm/languages/prism/jsx');

var bash = require('react-syntax-highlighter/dist/esm/languages/prism/bash');

var css = require('react-syntax-highlighter/dist/esm/languages/prism/css');

var jsExtras = require('react-syntax-highlighter/dist/esm/languages/prism/js-extras');

var json = require('react-syntax-highlighter/dist/esm/languages/prism/json');

var graphql = require('react-syntax-highlighter/dist/esm/languages/prism/graphql');

var html = require('react-syntax-highlighter/dist/esm/languages/prism/markup');

var md = require('react-syntax-highlighter/dist/esm/languages/prism/markdown');

var yml = require('react-syntax-highlighter/dist/esm/languages/prism/yaml');

var tsx = require('react-syntax-highlighter/dist/esm/languages/prism/tsx');

var typescript = require('react-syntax-highlighter/dist/esm/languages/prism/typescript');

var ReactSyntaxHighlighter = require('react-syntax-highlighter/dist/esm/prism-light');

require('@storybook/csf');

require('qs');

function _interopDefaultLegacy(e) {
  return e && typeof e === 'object' && 'default' in e ? e : {
    'default': e
  };
}

var React__default = /*#__PURE__*/_interopDefaultLegacy(React);

var memoize__default = /*#__PURE__*/_interopDefaultLegacy(memoize);

var jsx__default = /*#__PURE__*/_interopDefaultLegacy(jsx);

var bash__default = /*#__PURE__*/_interopDefaultLegacy(bash);

var css__default = /*#__PURE__*/_interopDefaultLegacy(css);

var jsExtras__default = /*#__PURE__*/_interopDefaultLegacy(jsExtras);

var json__default = /*#__PURE__*/_interopDefaultLegacy(json);

var graphql__default = /*#__PURE__*/_interopDefaultLegacy(graphql);

var html__default = /*#__PURE__*/_interopDefaultLegacy(html);

var md__default = /*#__PURE__*/_interopDefaultLegacy(md);

var yml__default = /*#__PURE__*/_interopDefaultLegacy(yml);

var tsx__default = /*#__PURE__*/_interopDefaultLegacy(tsx);

var typescript__default = /*#__PURE__*/_interopDefaultLegacy(typescript);

var ReactSyntaxHighlighter__default = /*#__PURE__*/_interopDefaultLegacy(ReactSyntaxHighlighter);

const {
  navigator,
  document,
  window: globalWindow
} = index.window_1;
ReactSyntaxHighlighter__default["default"].registerLanguage('jsextra', jsExtras__default["default"]);
ReactSyntaxHighlighter__default["default"].registerLanguage('jsx', jsx__default["default"]);
ReactSyntaxHighlighter__default["default"].registerLanguage('json', json__default["default"]);
ReactSyntaxHighlighter__default["default"].registerLanguage('yml', yml__default["default"]);
ReactSyntaxHighlighter__default["default"].registerLanguage('md', md__default["default"]);
ReactSyntaxHighlighter__default["default"].registerLanguage('bash', bash__default["default"]);
ReactSyntaxHighlighter__default["default"].registerLanguage('css', css__default["default"]);
ReactSyntaxHighlighter__default["default"].registerLanguage('html', html__default["default"]);
ReactSyntaxHighlighter__default["default"].registerLanguage('tsx', tsx__default["default"]);
ReactSyntaxHighlighter__default["default"].registerLanguage('typescript', typescript__default["default"]);
ReactSyntaxHighlighter__default["default"].registerLanguage('graphql', graphql__default["default"]);
const themedSyntax = memoize__default["default"](2)(theme => Object.entries(theme.code || {}).reduce((acc, [key, val]) => Object.assign(Object.assign({}, acc), {
  [`* .${key}`]: val
}), {}));
const copyToClipboard = createCopyToClipboardFunction();

function createCopyToClipboardFunction() {
  if (navigator === null || navigator === void 0 ? void 0 : navigator.clipboard) {
    return text => navigator.clipboard.writeText(text);
  }

  return text => index.__awaiter(this, void 0, void 0, function* () {
    const tmp = document.createElement('TEXTAREA');
    const focus = document.activeElement;
    tmp.value = text;
    document.body.appendChild(tmp);
    tmp.select();
    document.execCommand('copy');
    document.body.removeChild(tmp);
    focus.focus();
  });
}

const Wrapper = theming.styled.div(({
  theme
}) => ({
  position: 'relative',
  overflow: 'hidden',
  color: theme.color.defaultText
}), ({
  theme,
  bordered
}) => bordered ? {
  border: `1px solid ${theme.appBorderColor}`,
  borderRadius: theme.borderRadius,
  background: theme.background.content
} : {});
const Scroller = theming.styled(({
  children,
  className
}) => React__default["default"].createElement(index.ScrollArea, {
  horizontal: true,
  vertical: true,
  className: className
}, children))({
  position: 'relative'
}, ({
  theme
}) => themedSyntax(theme));
const Pre = theming.styled.pre(({
  theme,
  padded
}) => ({
  display: 'flex',
  justifyContent: 'flex-start',
  margin: 0,
  padding: padded ? theme.layoutMargin : 0
}));
/*
We can't use `code` since PrismJS races for it.
See https://github.com/storybookjs/storybook/issues/18090
 */

const Code = theming.styled.div(({
  theme
}) => ({
  flex: 1,
  paddingLeft: 2,
  paddingRight: theme.layoutMargin,
  opacity: 1
})); // copied from @types/react-syntax-highlighter/index.d.ts

const SyntaxHighlighter = _a => {
  var {
    children,
    language = 'jsx',
    copyable = false,
    bordered = false,
    padded = false,
    format = true,
    formatter = null,
    className = null,
    showLineNumbers = false
  } = _a,
      rest = index.__rest(_a, ["children", "language", "copyable", "bordered", "padded", "format", "formatter", "className", "showLineNumbers"]);

  if (typeof children !== 'string' || !children.trim()) {
    return null;
  }

  const highlightableCode = formatter ? formatter(format, children) : children.trim();
  const [copied, setCopied] = React.useState(false);
  const onClick = React.useCallback(e => {
    e.preventDefault();
    const selectedText = globalWindow.getSelection().toString();
    const textToCopy = e.type !== 'click' && selectedText ? selectedText : highlightableCode;
    copyToClipboard(textToCopy).then(() => {
      setCopied(true);
      globalWindow.setTimeout(() => setCopied(false), 1500);
    }).catch(clientLogger.logger.error);
  }, []);
  return React__default["default"].createElement(Wrapper, {
    bordered: bordered,
    padded: padded,
    className: className,
    onCopyCapture: onClick
  }, React__default["default"].createElement(Scroller, null, React__default["default"].createElement(ReactSyntaxHighlighter__default["default"], Object.assign({
    padded: padded || bordered,
    language: language,
    showLineNumbers: showLineNumbers,
    showInlineLineNumbers: showLineNumbers,
    useInlineStyles: false,
    PreTag: Pre,
    CodeTag: Code,
    lineNumberContainerStyle: {}
  }, rest), highlightableCode)), copyable ? React__default["default"].createElement(index.ActionBar, {
    actionItems: [{
      title: copied ? 'Copied' : 'Copy',
      onClick
    }]
  }) : null);
};

exports.SyntaxHighlighter = SyntaxHighlighter;
exports.createCopyToClipboardFunction = createCopyToClipboardFunction;
exports["default"] = SyntaxHighlighter;
