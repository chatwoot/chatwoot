import { _ as __awaiter, S as ScrollArea, a as __rest, A as ActionBar, w as window_1 } from './index-9ef3b84b.js';
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
const {
  navigator,
  document,
  window: globalWindow
} = window_1;
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
const themedSyntax = memoize(2)(theme => Object.entries(theme.code || {}).reduce((acc, [key, val]) => Object.assign(Object.assign({}, acc), {
  [`* .${key}`]: val
}), {}));
const copyToClipboard = createCopyToClipboardFunction();

function createCopyToClipboardFunction() {
  if (navigator === null || navigator === void 0 ? void 0 : navigator.clipboard) {
    return text => navigator.clipboard.writeText(text);
  }

  return text => __awaiter(this, void 0, void 0, function* () {
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

const Wrapper = styled.div(({
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
const Scroller = styled(({
  children,
  className
}) => React__default.createElement(ScrollArea, {
  horizontal: true,
  vertical: true,
  className: className
}, children))({
  position: 'relative'
}, ({
  theme
}) => themedSyntax(theme));
const Pre = styled.pre(({
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

const Code = styled.div(({
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
      rest = __rest(_a, ["children", "language", "copyable", "bordered", "padded", "format", "formatter", "className", "showLineNumbers"]);

  if (typeof children !== 'string' || !children.trim()) {
    return null;
  }

  const highlightableCode = formatter ? formatter(format, children) : children.trim();
  const [copied, setCopied] = useState(false);
  const onClick = useCallback(e => {
    e.preventDefault();
    const selectedText = globalWindow.getSelection().toString();
    const textToCopy = e.type !== 'click' && selectedText ? selectedText : highlightableCode;
    copyToClipboard(textToCopy).then(() => {
      setCopied(true);
      globalWindow.setTimeout(() => setCopied(false), 1500);
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
      onClick
    }]
  }) : null);
};

export { SyntaxHighlighter, createCopyToClipboardFunction, SyntaxHighlighter as default };
