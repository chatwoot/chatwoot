import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";

var _templateObject;

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

import dedent from 'ts-dedent';
var hasWarned = false;
export function LinkTo() {
  if (!hasWarned) {
    // eslint-disable-next-line no-console
    console.error(dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n      LinkTo has moved to addon-links/react:\n      import LinkTo from '@storybook/addon-links/react';\n    "]))));
    hasWarned = true;
  }

  return null;
}
export { linkTo, hrefTo, withLinks, navigate } from './utils';

if (module && module.hot && module.hot.decline) {
  module.hot.decline();
}