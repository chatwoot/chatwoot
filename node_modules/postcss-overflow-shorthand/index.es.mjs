import postcss from 'postcss';

function _toArray(arr) {
  return _arrayWithHoles(arr) || _iterableToArray(arr) || _nonIterableRest();
}

function _arrayWithHoles(arr) {
  if (Array.isArray(arr)) return arr;
}

function _iterableToArray(iter) {
  if (Symbol.iterator in Object(iter) || Object.prototype.toString.call(iter) === "[object Arguments]") return Array.from(iter);
}

function _nonIterableRest() {
  throw new TypeError("Invalid attempt to destructure non-iterable instance");
}

const space = postcss.list.space; // overflow shorthand property matcher

const overflowPropertyRegExp = /^overflow$/i;
var index = postcss.plugin('postcss-overflow-shorthand', opts => {
  const preserve = 'preserve' in Object(opts) ? Boolean(opts.preserve) : true;
  return root => {
    // for each overflow declaration
    root.walkDecls(overflowPropertyRegExp, decl => {
      // split the declaration values
      const _space = space(decl.value),
            _space2 = _toArray(_space),
            overflowX = _space2[0],
            overflowY = _space2[1],
            invalidatingValues = _space2.slice(2); // if there are two values, but no invalidating values


      if (overflowY && !invalidatingValues.length) {
        // insert the overflow-* longhand declarations
        decl.cloneBefore({
          prop: `${decl.prop}-x`,
          value: overflowX
        });
        decl.cloneBefore({
          prop: `${decl.prop}-y`,
          value: overflowY
        }); // conditionally remove the original declaration

        if (!preserve) {
          decl.remove();
        }
      }
    });
  };
});

export default index;
//# sourceMappingURL=index.es.mjs.map
