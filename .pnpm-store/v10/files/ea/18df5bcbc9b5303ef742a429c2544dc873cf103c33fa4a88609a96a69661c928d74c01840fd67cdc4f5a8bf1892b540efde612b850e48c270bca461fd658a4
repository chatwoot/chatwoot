'use strict';

var plugin = require('windicss/plugin');

function _interopDefault (e) { return e && e.__esModule ? e : { default: e }; }

var plugin__default = /*#__PURE__*/_interopDefault(plugin);

// packages/themes/src/windicss/index.ts
var outerAttributes = [
  "disabled",
  "invalid",
  "errors",
  "complete",
  "loading",
  "submitted",
  "checked",
  "multiple",
  "prefix-icon",
  "suffix-icon"
];
var FormKitVariants = plugin__default.default(({ addVariant }) => {
  outerAttributes.forEach((attribute) => {
    addVariant(`formkit-${attribute}`, ({ modifySelectors }) => {
      return modifySelectors(({ className }) => {
        return `[data-${attribute}='true']:not([data-type='repeater']).${className},
        [data-${attribute}='true']:not([data-type='repeater']) .${className}`;
      });
    });
  });
});
var windicss_default = FormKitVariants;

module.exports = windicss_default;
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.cjs.map