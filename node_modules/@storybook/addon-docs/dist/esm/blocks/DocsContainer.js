import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";

var _templateObject;

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/web.url.js";
import "core-js/modules/web.url-search-params.js";
import React, { useEffect } from 'react';
import global from 'global';
import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import { MDXProvider } from '@mdx-js/react';
import { ThemeProvider, ensure as ensureTheme } from '@storybook/theming';
import { DocsWrapper, DocsContent, components as htmlComponents } from '@storybook/components';
import { DocsContext } from './DocsContext';
import { anchorBlockIdFromId } from './Anchor';
import { storyBlockIdFromId } from './Story';
import { SourceContainer } from './SourceContainer';
import { CodeOrSourceMdx, AnchorMdx, HeadersMdx } from './mdx';
import { scrollToElement } from './utils';
var document = global.document,
    globalWindow = global.window;
var defaultComponents = Object.assign({}, htmlComponents, {
  code: CodeOrSourceMdx,
  a: AnchorMdx
}, HeadersMdx);
var warnOptionsTheme = deprecate(function () {}, dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Deprecated parameter: options.theme => docs.theme\n\n    https://github.com/storybookjs/storybook/blob/next/addons/docs/docs/theming.md#storybook-theming\n"]))));
export var DocsContainer = function DocsContainer(_ref) {
  var context = _ref.context,
      children = _ref.children;
  var storyId = context.id,
      storyById = context.storyById;

  var _storyById = storyById(storyId),
      _storyById$parameters = _storyById.parameters,
      _storyById$parameters2 = _storyById$parameters.options,
      options = _storyById$parameters2 === void 0 ? {} : _storyById$parameters2,
      _storyById$parameters3 = _storyById$parameters.docs,
      docs = _storyById$parameters3 === void 0 ? {} : _storyById$parameters3;

  var themeVars = docs.theme;

  if (!themeVars && options.theme) {
    warnOptionsTheme();
    themeVars = options.theme;
  }

  var theme = ensureTheme(themeVars);
  var allComponents = Object.assign({}, defaultComponents, docs.components);
  useEffect(function () {
    var url;

    try {
      url = new URL(globalWindow.parent.location);
    } catch (err) {
      return;
    }

    if (url.hash) {
      var element = document.getElementById(url.hash.substring(1));

      if (element) {
        // Introducing a delay to ensure scrolling works when it's a full refresh.
        setTimeout(function () {
          scrollToElement(element);
        }, 200);
      }
    } else {
      var _element = document.getElementById(anchorBlockIdFromId(storyId)) || document.getElementById(storyBlockIdFromId(storyId));

      if (_element) {
        var allStories = _element.parentElement.querySelectorAll('[id|="anchor-"]');

        var scrollTarget = _element;

        if (allStories && allStories[0] === _element) {
          // Include content above first story
          scrollTarget = document.getElementById('docs-root');
        } // Introducing a delay to ensure scrolling works when it's a full refresh.


        setTimeout(function () {
          scrollToElement(scrollTarget, 'start');
        }, 200);
      }
    }
  }, [storyId]);
  return /*#__PURE__*/React.createElement(DocsContext.Provider, {
    value: context
  }, /*#__PURE__*/React.createElement(SourceContainer, null, /*#__PURE__*/React.createElement(ThemeProvider, {
    theme: theme
  }, /*#__PURE__*/React.createElement(MDXProvider, {
    components: allComponents
  }, /*#__PURE__*/React.createElement(DocsWrapper, {
    className: "sbdocs sbdocs-wrapper"
  }, /*#__PURE__*/React.createElement(DocsContent, {
    className: "sbdocs sbdocs-content"
  }, children))))));
};