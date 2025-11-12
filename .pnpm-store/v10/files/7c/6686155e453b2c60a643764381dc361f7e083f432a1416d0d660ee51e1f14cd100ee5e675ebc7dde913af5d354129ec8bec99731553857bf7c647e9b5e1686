import plugin from 'windicss/plugin';

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
var FormKitVariants = plugin(({ addVariant }) => {
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

export { windicss_default as default };
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.dev.mjs.map