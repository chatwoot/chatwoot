import postcss from 'postcss';

const selectorRegExp = /:focus-visible([^\w-]|$)/gi;
var index = postcss.plugin('postcss-focus-visible', opts => {
  const replaceWith = String(Object(opts).replaceWith || '.focus-visible');
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

export default index;
//# sourceMappingURL=index.es.mjs.map
