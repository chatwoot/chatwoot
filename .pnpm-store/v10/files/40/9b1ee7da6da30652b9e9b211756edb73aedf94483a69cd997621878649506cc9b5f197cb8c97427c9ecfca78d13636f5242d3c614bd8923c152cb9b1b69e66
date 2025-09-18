import plugin from 'tailwindcss/plugin.js';

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
var FormKitVariants = plugin(function({ matchVariant }) {
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

export { tailwindcss_default as default };
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.mjs.map