import parser from 'postcss-selector-parser';
import postcss from 'postcss';

const selectorRegExp = /:has/;
var postcss$1 = postcss.plugin('css-has-pseudo', opts => {
  const preserve = Boolean('preserve' in Object(opts) ? opts.preserve : true);
  return root => {
    root.walkRules(selectorRegExp, rule => {
      const modifiedSelector = parser(selectors => {
        selectors.walkPseudos(selector => {
          if (selector.value === ':has' && selector.nodes) {
            const isNotHas = checkIfParentIsNot(selector);
            selector.value = isNotHas ? ':not-has' : ':has';
            const attribute = parser.attribute({
              attribute: encodeURIComponent(String(selector)).replace(/%3A/g, ':').replace(/%5B/g, '[').replace(/%5D/g, ']').replace(/%2C/g, ',').replace(/[():%\[\],]/g, '\\$&')
            });

            if (isNotHas) {
              selector.parent.parent.replaceWith(attribute);
            } else {
              selector.replaceWith(attribute);
            }
          }
        });
      }).processSync(rule.selector);
      const clone = rule.clone({
        selector: modifiedSelector
      });

      if (preserve) {
        rule.before(clone);
      } else {
        rule.replaceWith(clone);
      }
    });
  };
});

function checkIfParentIsNot(selector) {
  return Object(Object(selector.parent).parent).type === 'pseudo' && selector.parent.parent.value === ':not';
}

export default postcss$1;
//# sourceMappingURL=postcss.mjs.map
