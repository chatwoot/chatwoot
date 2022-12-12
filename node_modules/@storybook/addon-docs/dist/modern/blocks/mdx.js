const _excluded = ["children"],
      _excluded2 = ["className", "children"],
      _excluded3 = ["href", "target", "children"],
      _excluded4 = ["as", "id", "children"],
      _excluded5 = ["as", "id", "children"];
import "core-js/modules/es.array.reduce.js";

function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import React from 'react';
import { addons } from '@storybook/addons';
import { NAVIGATE_URL } from '@storybook/core-events';
import { Source, Code, components } from '@storybook/components';
import global from 'global';
import { styled } from '@storybook/theming';
import { DocsContext } from './DocsContext';
const {
  document
} = global; // Hacky utility for asserting identifiers in MDX Story elements

export const assertIsFn = val => {
  if (typeof val !== 'function') {
    throw new Error(`Expected story function, got: ${val}`);
  }

  return val;
}; // Hacky utility for adding mdxStoryToId to the default context

export const AddContext = props => {
  const {
    children
  } = props,
        rest = _objectWithoutPropertiesLoose(props, _excluded);

  const parentContext = React.useContext(DocsContext);
  return /*#__PURE__*/React.createElement(DocsContext.Provider, {
    value: Object.assign({}, parentContext, rest)
  }, children);
};
export const CodeOrSourceMdx = _ref => {
  let {
    className,
    children
  } = _ref,
      rest = _objectWithoutPropertiesLoose(_ref, _excluded2);

  // markdown-to-jsx does not add className to inline code
  if (typeof className !== 'string' && (typeof children !== 'string' || !children.match(/[\n\r]/g))) {
    return /*#__PURE__*/React.createElement(Code, null, children);
  } // className: "lang-jsx"


  const language = className && className.split('-');
  return /*#__PURE__*/React.createElement(Source, _extends({
    language: language && language[1] || 'plaintext',
    format: false,
    code: children
  }, rest));
};

function navigate(url) {
  addons.getChannel().emit(NAVIGATE_URL, url);
} // @ts-ignore


const A = components.a;

const AnchorInPage = ({
  hash,
  children
}) => /*#__PURE__*/React.createElement(A, {
  href: hash,
  target: "_self",
  onClick: event => {
    const id = hash.substring(1);
    const element = document.getElementById(id);

    if (element) {
      navigate(hash);
    }
  }
}, children);

export const AnchorMdx = props => {
  const {
    href,
    target,
    children
  } = props,
        rest = _objectWithoutPropertiesLoose(props, _excluded3);

  if (href) {
    // Enable scrolling for in-page anchors.
    if (href.startsWith('#')) {
      return /*#__PURE__*/React.createElement(AnchorInPage, {
        hash: href
      }, children);
    } // Links to other pages of SB should use the base URL of the top level iframe instead of the base URL of the preview iframe.


    if (target !== '_blank' && !href.startsWith('https://')) {
      return /*#__PURE__*/React.createElement(A, _extends({
        href: href,
        onClick: event => {
          event.preventDefault(); // use the A element's href, which has been modified for
          // local paths without a `?path=` query param prefix

          navigate(event.currentTarget.getAttribute('href'));
        },
        target: target
      }, rest), children);
    }
  } // External URL dont need any modification.


  return /*#__PURE__*/React.createElement(A, props);
};
const SUPPORTED_MDX_HEADERS = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'];
const OcticonHeaders = SUPPORTED_MDX_HEADERS.reduce((acc, headerType) => Object.assign({}, acc, {
  // @ts-ignore
  [headerType]: styled(components[headerType])({
    '& svg': {
      visibility: 'hidden'
    },
    '&:hover svg': {
      visibility: 'visible'
    }
  })
}), {});
const OcticonAnchor = styled.a(() => ({
  float: 'left',
  paddingRight: '4px',
  marginLeft: '-20px',
  // Allow the theme's text color to override the default link color.
  color: 'inherit'
}));

const HeaderWithOcticonAnchor = _ref2 => {
  let {
    as,
    id,
    children
  } = _ref2,
      rest = _objectWithoutPropertiesLoose(_ref2, _excluded4);

  // @ts-ignore
  const OcticonHeader = OcticonHeaders[as];
  const hash = `#${id}`;
  return /*#__PURE__*/React.createElement(OcticonHeader, _extends({
    id: id
  }, rest), /*#__PURE__*/React.createElement(OcticonAnchor, {
    "aria-hidden": "true",
    href: hash,
    tabIndex: -1,
    target: "_self",
    onClick: event => {
      const element = document.getElementById(id);

      if (element) {
        navigate(hash);
      }
    }
  }, /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 16 16",
    version: "1.1",
    width: "16",
    height: "16",
    "aria-hidden": "true",
    fill: "currentColor"
  }, /*#__PURE__*/React.createElement("path", {
    fillRule: "evenodd",
    d: "M4 9h1v1H4c-1.5 0-3-1.69-3-3.5S2.55 3 4 3h4c1.45 0 3 1.69 3 3.5 0 1.41-.91 2.72-2 3.25V8.59c.58-.45 1-1.27 1-2.09C10 5.22 8.98 4 8 4H4c-.98 0-2 1.22-2 2.5S3 9 4 9zm9-3h-1v1h1c1 0 2 1.22 2 2.5S13.98 12 13 12H9c-.98 0-2-1.22-2-2.5 0-.83.42-1.64 1-2.09V6.25c-1.09.53-2 1.84-2 3.25C6 11.31 7.55 13 9 13h4c1.45 0 3-1.69 3-3.5S14.5 6 13 6z"
  }))), children);
};

export const HeaderMdx = props => {
  const {
    as,
    id,
    children
  } = props,
        rest = _objectWithoutPropertiesLoose(props, _excluded5); // An id should have been added on every header by the "remark-slug" plugin.


  if (id) {
    return /*#__PURE__*/React.createElement(HeaderWithOcticonAnchor, _extends({
      as: as,
      id: id
    }, rest), children);
  } // @ts-ignore


  const Header = components[as]; // Make sure it still work if "remark-slug" plugin is not present.

  return /*#__PURE__*/React.createElement(Header, props);
};
export const HeadersMdx = SUPPORTED_MDX_HEADERS.reduce((acc, headerType) => Object.assign({}, acc, {
  // @ts-ignore
  [headerType]: props => /*#__PURE__*/React.createElement(HeaderMdx, _extends({
    as: headerType
  }, props))
}), {});