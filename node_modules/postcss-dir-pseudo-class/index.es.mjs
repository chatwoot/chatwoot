import postcss from 'postcss';
import selectorParser from 'postcss-selector-parser';

var index = postcss.plugin('postcss-dir-pseudo-class', opts => {
  const dir = Object(opts).dir;
  const preserve = Boolean(Object(opts).preserve);
  return root => {
    // walk rules using the :dir pseudo-class
    root.walkRules(/:dir\([^\)]*\)/, rule => {
      let currentRule = rule; // conditionally preserve the original rule

      if (preserve) {
        currentRule = rule.cloneBefore();
      } // update the rule selector


      currentRule.selector = selectorParser(selectors => {
        // for each (comma separated) selector
        selectors.nodes.forEach(selector => {
          // walk all selector nodes that are :dir pseudo-classes
          selector.walk(node => {
            if ('pseudo' === node.type && ':dir' === node.value) {
              // previous and next selector nodes
              const prev = node.prev();
              const next = node.next();
              const prevIsSpaceCombinator = prev && prev.type && 'combinator' === prev.type && ' ' === prev.value;
              const nextIsSpaceCombinator = next && next.type && 'combinator' === next.type && ' ' === next.value; // preserve the selector tree

              if (prevIsSpaceCombinator && (nextIsSpaceCombinator || !next)) {
                node.replaceWith(selectorParser.universal());
              } else {
                node.remove();
              } // conditionally prepend a combinator before inserting the [dir] attribute


              const first = selector.nodes[0];
              const firstIsSpaceCombinator = first && 'combinator' === first.type && ' ' === first.value;
              const firstIsHtml = first && 'tag' === first.type && 'html' === first.value;
              const firstIsRoot = first && 'pseudo' === first.type && ':root' === first.value;

              if (first && !firstIsHtml && !firstIsRoot && !firstIsSpaceCombinator) {
                selector.prepend(selectorParser.combinator({
                  value: ' '
                }));
              } // value of the :dir pseudo-class


              const value = node.nodes.toString(); // whether :dir matches the presumed direction

              const isdir = dir === value; // [dir] attribute

              const dirAttr = selectorParser.attribute({
                attribute: 'dir',
                operator: '=',
                quoteMark: '"',
                value: `"${value}"`
              }); // not[dir] attribute

              const notDirAttr = selectorParser.pseudo({
                value: `${firstIsHtml || firstIsRoot ? '' : 'html'}:not`
              });
              notDirAttr.append(selectorParser.attribute({
                attribute: 'dir',
                operator: '=',
                quoteMark: '"',
                value: `"${'ltr' === value ? 'rtl' : 'ltr'}"`
              }));

              if (isdir) {
                // if the direction is presumed
                if (firstIsHtml) {
                  // insert :root after html tag
                  selector.insertAfter(first, notDirAttr);
                } else {
                  // prepend :root
                  selector.prepend(notDirAttr);
                }
              } else if (firstIsHtml) {
                // otherwise, insert dir attribute after html tag
                selector.insertAfter(first, dirAttr);
              } else {
                // otherwise, prepend the dir attribute
                selector.prepend(dirAttr);
              }
            }
          });
        });
      }).processSync(currentRule.selector);
    });
  };
});

export default index;
//# sourceMappingURL=index.es.mjs.map
