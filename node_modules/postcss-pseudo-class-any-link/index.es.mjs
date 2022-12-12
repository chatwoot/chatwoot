import postcss from 'postcss';
import parser from 'postcss-selector-parser';

const anyAnyLinkMatch = /:any-link/;
var index = postcss.plugin('postcss-pseudo-class-any-link', opts => {
  const preserve = 'preserve' in Object(opts) ? Boolean(opts.preserve) : true;
  return root => {
    // walk each matching rule
    root.walkRules(anyAnyLinkMatch, rule => {
      const rawSelector = rule.raws.selector && rule.raws.selector.raw || rule.selector; // workaround for https://github.com/postcss/postcss-selector-parser/issues/28#issuecomment-171910556

      if (rawSelector[rawSelector.length - 1] !== ':') {
        // update the selector
        const updatedSelector = parser(selectors => {
          // cache variables
          let node;
          let nodeIndex;
          let selector;
          let selectorLink;
          let selectorVisited; // cache the selector index

          let selectorIndex = -1; // for each selector

          while (selector = selectors.nodes[++selectorIndex]) {
            // reset the node index
            nodeIndex = -1; // for each node

            while (node = selector.nodes[++nodeIndex]) {
              // if the node value matches the any-link value
              if (node.value === ':any-link') {
                // clone the selector
                selectorLink = selector.clone();
                selectorVisited = selector.clone(); // update the matching clone values

                selectorLink.nodes[nodeIndex].value = ':link';
                selectorVisited.nodes[nodeIndex].value = ':visited'; // replace the selector with the clones and roll back the selector index

                selectors.nodes.splice(selectorIndex--, 1, selectorLink, selectorVisited); // stop updating the selector

                break;
              }
            }
          }
        }).processSync(rawSelector);

        if (updatedSelector !== rawSelector) {
          if (preserve) {
            rule.cloneBefore({
              selector: updatedSelector
            });
          } else {
            rule.selector = updatedSelector;
          }
        }
      }
    });
  };
});

export default index;
//# sourceMappingURL=index.es.mjs.map
