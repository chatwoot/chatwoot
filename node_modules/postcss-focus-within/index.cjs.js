'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var postcss = _interopDefault(require('postcss'));

const selectorRegExp = /:focus-within([^\w-]|$)/gi;
var index = postcss.plugin('postcss-focus-within', opts => {
  const replaceWith = String(Object(opts).replaceWith || '[focus-within]');
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

module.exports = index;
//# sourceMappingURL=index.cjs.js.map
