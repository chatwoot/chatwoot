// packages/themes/src/unocss/index.ts
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
var attributesVariants = (matcher) => {
  const match = matcher.match(
    new RegExp(`^formkit-(${outerAttributes.join("|")})(/[_\\d\\w]+)?[:-]`)
  );
  if (!match)
    return matcher;
  return {
    matcher: matcher.slice(match[0].length),
    selector: (s) => {
      if (match[2]) {
        return `
          [data-${match[1]}="true"].group\\${match[2]}${s},
          [data-${match[1]}="true"].group\\${match[2]} ${s}
        `;
      }
      return `
      	[data-${match[1]}="true"]:not([data-type='repeater'])${s},
        [data-${match[1]}="true"]:not([data-type='repeater']) ${s}
      `;
    }
  };
};
var FormKitVariants = () => {
  return {
    name: "unocss-preset-formkit",
    variants: [attributesVariants]
  };
};
var unocss_default = FormKitVariants;

export { unocss_default as default };
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.dev.mjs.map