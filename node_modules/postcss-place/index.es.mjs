import postcss from 'postcss';
import parser from 'postcss-values-parser';

const placeMatch = /^place-(content|items|self)/;
var index = postcss.plugin('postcss-place', opts => {
  // prepare options
  const preserve = 'preserve' in Object(opts) ? Boolean(opts.prefix) : true;
  return root => {
    // walk each matching declaration
    root.walkDecls(placeMatch, decl => {
      // alignment
      const alignment = decl.prop.match(placeMatch)[1]; // value ast and child nodes

      const value = parser(decl.value).parse();
      const children = value.nodes[0].nodes; // new justify-[alignment] and align-[alignment] declarations

      const alignValue = children.length === 1 ? decl.value : String(children.slice(0, 1)).trim();
      const justifyValue = children.length === 1 ? decl.value : String(children.slice(1)).trim();
      decl.cloneBefore({
        prop: `align-${alignment}`,
        value: alignValue
      });
      decl.cloneBefore({
        prop: `justify-${alignment}`,
        value: justifyValue
      }); // conditionally remove place-[alignment]

      if (!preserve) {
        decl.remove();
      }
    });
  };
});

export default index;
//# sourceMappingURL=index.es.mjs.map
