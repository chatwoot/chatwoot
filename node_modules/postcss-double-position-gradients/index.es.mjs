import postcss from 'postcss';
import valueParser from 'postcss-values-parser';

var index = postcss.plugin('postcss-double-position-gradients', opts => {
  const preserve = 'preserve' in Object(opts) ? Boolean(opts.preserve) : true;
  return root => {
    // walk every declaration
    root.walkDecls(decl => {
      const originalValue = decl.value; // if the declaration value contains a gradient

      if (gradientFunctionRegExp.test(originalValue)) {
        const ast = valueParser(originalValue).parse(); // walk every function in the declaration value

        ast.walkFunctionNodes(fn => {
          // if the function is a gradient
          if (gradientFunctionNameRegExp.test(fn.value)) {
            const nodes = fn.nodes.slice(1, -1); // walk every argument to the function

            nodes.forEach((node, index) => {
              const node1back = Object(nodes[index - 1]);
              const node2back = Object(nodes[index - 2]);
              const isDoublePositionLength = node2back.type && node1back.type === 'number' && node.type === 'number'; // if the argument concludes a double-position gradient

              if (isDoublePositionLength) {
                // insert the fallback colors
                const color = node2back.clone();
                const comma = valueParser.comma({
                  value: ',',
                  raws: {
                    after: ' '
                  }
                });
                fn.insertBefore(node, comma);
                fn.insertBefore(node, color);
              }
            });
          }
        });
        const modifiedValue = ast.toString(); // if the value has changed due to double-position gradients

        if (originalValue !== modifiedValue) {
          // add the fallback value
          decl.cloneBefore({
            value: modifiedValue
          }); // conditionally remove the double-position gradient

          if (!preserve) {
            decl.remove();
          }
        }
      }
    });
  };
});
const gradientFunctionRegExp = /(repeating-)?(conic|linear|radial)-gradient\([\W\w]*\)/i;
const gradientFunctionNameRegExp = /^(repeating-)?(conic|linear|radial)-gradient$/i;

export default index;
//# sourceMappingURL=index.es.mjs.map
