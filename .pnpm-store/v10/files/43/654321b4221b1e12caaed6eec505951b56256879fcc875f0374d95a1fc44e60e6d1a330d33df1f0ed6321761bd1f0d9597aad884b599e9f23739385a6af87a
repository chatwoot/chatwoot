'use strict';

var plugin = require('tailwindcss/plugin.js');

function _interopDefault (e) { return e && e.__esModule ? e : { default: e }; }

var plugin__default = /*#__PURE__*/_interopDefault(plugin);

// packages/themes/src/tailwindcss/index.ts
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
var FormKitVariants = plugin__default.default(function({ matchVariant }) {
  const attributes = outerAttributes.reduce((a, v) => ({ ...a, [v]: v }), {});
  matchVariant(
    "formkit",
    (value = "", { modifier }) => {
      return modifier ? [
        `[data-${value}='true']:merge(.group\\/${modifier})&`,
        `[data-${value}='true']:merge(.group\\/${modifier}) &`
      ] : [
        `[data-${value}='true']:not([data-type='repeater'])&`,
        `[data-${value}='true']:not([data-type='repeater']) &`
      ];
    },
    { values: attributes }
  );
});
var tailwindcss_default = FormKitVariants;

module.exports = tailwindcss_default;
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.cjs.map