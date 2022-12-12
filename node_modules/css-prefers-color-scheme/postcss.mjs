import postcss from 'postcss';

const mediaRegExp = /^media$/i;
const prefersInterfaceRegExp = /\(\s*prefers-color-scheme\s*:\s*(dark|light|no-preference)\s*\)/i;
const colorIndexByStyle = {
  dark: 48,
  light: 70,
  'no-preference': 22
};

const prefersInterfaceReplacer = ($0, style) => `(color-index: ${colorIndexByStyle[style.toLowerCase()]})`;

var postcss$1 = postcss.plugin('postcss-prefers-color-scheme', opts => {
  const preserve = 'preserve' in Object(opts) ? opts.preserve : true;
  return root => {
    root.walkAtRules(mediaRegExp, atRule => {
      const params = atRule.params;
      const altParams = params.replace(prefersInterfaceRegExp, prefersInterfaceReplacer);

      if (params !== altParams) {
        if (preserve) {
          atRule.cloneBefore({
            params: altParams
          });
        } else {
          atRule.params = altParams;
        }
      }
    });
  };
});

export default postcss$1;
