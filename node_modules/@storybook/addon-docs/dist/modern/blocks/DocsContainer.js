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
const {
  document,
  window: globalWindow
} = global;
const defaultComponents = Object.assign({}, htmlComponents, {
  code: CodeOrSourceMdx,
  a: AnchorMdx
}, HeadersMdx);
const warnOptionsTheme = deprecate(() => {}, dedent`
    Deprecated parameter: options.theme => docs.theme

    https://github.com/storybookjs/storybook/blob/next/addons/docs/docs/theming.md#storybook-theming
`);
export const DocsContainer = ({
  context,
  children
}) => {
  const {
    id: storyId,
    storyById
  } = context;
  const {
    parameters: {
      options = {},
      docs = {}
    }
  } = storyById(storyId);
  let themeVars = docs.theme;

  if (!themeVars && options.theme) {
    warnOptionsTheme();
    themeVars = options.theme;
  }

  const theme = ensureTheme(themeVars);
  const allComponents = Object.assign({}, defaultComponents, docs.components);
  useEffect(() => {
    let url;

    try {
      url = new URL(globalWindow.parent.location);
    } catch (err) {
      return;
    }

    if (url.hash) {
      const element = document.getElementById(url.hash.substring(1));

      if (element) {
        // Introducing a delay to ensure scrolling works when it's a full refresh.
        setTimeout(() => {
          scrollToElement(element);
        }, 200);
      }
    } else {
      const element = document.getElementById(anchorBlockIdFromId(storyId)) || document.getElementById(storyBlockIdFromId(storyId));

      if (element) {
        const allStories = element.parentElement.querySelectorAll('[id|="anchor-"]');
        let scrollTarget = element;

        if (allStories && allStories[0] === element) {
          // Include content above first story
          scrollTarget = document.getElementById('docs-root');
        } // Introducing a delay to ensure scrolling works when it's a full refresh.


        setTimeout(() => {
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