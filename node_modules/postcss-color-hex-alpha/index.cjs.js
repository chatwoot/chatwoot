'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var postcss = _interopDefault(require('postcss'));
var valueParser = _interopDefault(require('postcss-values-parser'));

var index = postcss.plugin('postcss-color-hex-alpha', opts => {
  // whether to preserve the original hexa
  const preserve = 'preserve' in Object(opts) ? Boolean(opts.preserve) : false;
  return root => {
    // for each declaration with a hexa
    root.walkDecls(decl => {
      if (hasAlphaHex(decl)) {
        // replace instances of hexa with rgba()
        const ast = valueParser(decl.value).parse();
        walk(ast, node => {
          if (isAlphaHex(node)) {
            node.replaceWith(hexa2rgba(node));
          }
        }); // conditionally update the declaration

        const modifiedValue = String(ast);

        if (decl.value !== modifiedValue) {
          if (preserve) {
            decl.cloneBefore({
              value: modifiedValue
            });
          } else {
            decl.value = modifiedValue;
          }
        }
      }
    });
  };
}); // match any hexa

const alphaHexRegExp = /#([0-9A-Fa-f]{4}(?:[0-9A-Fa-f]{4})?)\b/; // whether a node has a hexa

const hasAlphaHex = node => alphaHexRegExp.test(node.value); // match an exact hexa


const alphaHexValueRegExp = /^#([0-9A-Fa-f]{4}(?:[0-9A-Fa-f]{4})?)$/; // walk all nodes in a value

const walk = (node, fn) => {
  if (Object(node.nodes).length) {
    node.nodes.slice().forEach(child => {
      fn(child);
      walk(child, fn);
    });
  }
}; // decimal precision


const alphaDecimalPrecision = 100000; // match a hexa node

const isAlphaHex = node => node.type === 'word' && alphaHexValueRegExp.test(node.value);

const hexa2rgba = node => {
  // hex is the node value
  const hex = node.value; // conditionally expand a hex

  const hex8 = `0x${hex.length === 5 ? hex.slice(1).replace(/[0-9A-f]/g, '$&$&') : hex.slice(1)}`; // extract the red, blue, green, and alpha values from the hex

  const _ref = [parseInt(hex8.slice(2, 4), 16), parseInt(hex8.slice(4, 6), 16), parseInt(hex8.slice(6, 8), 16), Math.round(parseInt(hex8.slice(8, 10), 16) / 255 * alphaDecimalPrecision) / alphaDecimalPrecision],
        r = _ref[0],
        g = _ref[1],
        b = _ref[2],
        a = _ref[3]; // return a new rgba function, preserving the whitespace of the original node

  const rgbaFunc = valueParser.func({
    value: 'rgba',
    raws: Object.assign({}, node.raws)
  });
  rgbaFunc.append(valueParser.paren({
    value: '('
  }));
  rgbaFunc.append(valueParser.number({
    value: r
  }));
  rgbaFunc.append(valueParser.comma({
    value: ','
  }));
  rgbaFunc.append(valueParser.number({
    value: g
  }));
  rgbaFunc.append(valueParser.comma({
    value: ','
  }));
  rgbaFunc.append(valueParser.number({
    value: b
  }));
  rgbaFunc.append(valueParser.comma({
    value: ','
  }));
  rgbaFunc.append(valueParser.number({
    value: a
  }));
  rgbaFunc.append(valueParser.paren({
    value: ')'
  }));
  return rgbaFunc;
};

module.exports = index;
//# sourceMappingURL=index.cjs.js.map
