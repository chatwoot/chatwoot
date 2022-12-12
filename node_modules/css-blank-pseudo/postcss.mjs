import postcss from 'postcss';

const selectorRegExp = /:blank([^\w-]|$)/gi;
var postcss$1 = postcss.plugin('css-blank-pseudo', opts => {
  const replaceWith = String(Object(opts).replaceWith || '[blank]');
  const preserve = Boolean('preserve' in Object(opts) ? opts.preserve : true);
  return root => {
    root.walkRules(selectorRegExp, rule => {
      const selector = rule.selector.replace(selectorRegExp, ($0, $1) => {
        return `${replaceWith}${$1}`;
      });
      const clone = rule.clone({
        selector
      });

      if (preserve) {
        rule.before(clone);
      } else {
        rule.replaceWith(clone);
      }
    });
  };
});

export default postcss$1;
//# sourceMappingURL=postcss.mjs.map
