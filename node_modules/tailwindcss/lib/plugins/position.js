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
    addUtilities({
      '.static': {
        position: 'static'
      },
      '.fixed': {
        position: 'fixed'
      },
      '.absolute': {
        position: 'absolute'
      },
      '.relative': {
        position: 'relative'
      },
      ...(target('position') === 'ie11' ? {} : {
        '.sticky': {
          position: 'sticky'
        }
      })
    }, variants('position'));
  };
}