import postcss from 'postcss';

const gapPropertyRegExp = /^(column-gap|gap|row-gap)$/i;
var index = postcss.plugin('postcss-gap-properties', opts => {
  const preserve = 'preserve' in Object(opts) ? Boolean(opts.preserve) : true;
  return root => {
    // for each shorthand gap, column-gap, or row-gap declaration
    root.walkDecls(gapPropertyRegExp, decl => {
      // insert a grid-* fallback declaration
      decl.cloneBefore({
        prop: `grid-${decl.prop}`
      }); // conditionally remove the original declaration

      if (!preserve) {
        decl.remove();
      }
    });
  };
});

export default index;
//# sourceMappingURL=index.es.mjs.map
