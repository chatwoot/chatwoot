"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

function _default() {
  return function ({
    addUtilities,
    variants,
    target
  }) {
    if (target('placeItems') === 'ie11') {
      return;
    }

    addUtilities({
      '.place-items-auto': {
        'place-items': 'auto'
      },
      '.place-items-start': {
        'place-items': 'start'
      },
      '.place-items-end': {
        'place-items': 'end'
      },
      '.place-items-center': {
        'place-items': 'center'
      },
      '.place-items-stretch': {
        'place-items': 'stretch'
      }
    }, variants('placeItems'));
  };
}