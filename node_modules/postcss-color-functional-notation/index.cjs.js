'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var postcss = _interopDefault(require('postcss'));
var valuesParser = _interopDefault(require('postcss-values-parser'));

var index = postcss.plugin('postcss-color-functional-notation', opts => {
  const preserve = 'preserve' in Object(opts) ? Boolean(opts.preserve) : false;
  return root => {
    root.walkDecls(decl => {
      const originalValue = decl.value;

      if (colorAnyRegExp.test(originalValue)) {
        const valueAST = valuesParser(originalValue).parse();
        valueAST.walkType('func', node => {
          if (colorRegExp.test(node.value)) {
            const children = node.nodes.slice(1, -1);
            const isFunctionalHSL = matchFunctionalHSL(node, children);
            const isFunctionalRGB1 = matchFunctionalRGB1(node, children);
            const isFunctionalRGB2 = matchFunctionalRGB2(node, children);

            if (isFunctionalHSL || isFunctionalRGB1 || isFunctionalRGB2) {
              const slashNode = children[3];
              const alphaNode = children[4];

              if (alphaNode) {
                if (isPercentage(alphaNode) && !isCalc(alphaNode)) {
                  alphaNode.unit = '';
                  alphaNode.value = String(alphaNode.value / 100);
                }

                if (isHslRgb(node)) {
                  node.value += 'a';
                }
              } else if (isHslaRgba(node)) {
                node.value = node.value.slice(0, -1);
              }

              if (slashNode && isSlash(slashNode)) {
                slashNode.replaceWith(newComma());
              }

              if (isFunctionalRGB2) {
                children[0].unit = children[1].unit = children[2].unit = '';
                children[0].value = String(Math.floor(children[0].value * 255 / 100));
                children[1].value = String(Math.floor(children[1].value * 255 / 100));
                children[2].value = String(Math.floor(children[2].value * 255 / 100));
              }

              node.nodes.splice(3, 0, [newComma()]);
              node.nodes.splice(2, 0, [newComma()]);
            }
          }
        });
        const modifiedValue = String(valueAST);

        if (modifiedValue !== originalValue) {
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
});
const alphaUnitMatch = /^%?$/i;
const calcFuncMatch = /^calc$/i;
const colorAnyRegExp = /(^|[^\w-])(hsla?|rgba?)\(/i;
const colorRegExp = /^(hsla?|rgba?)$/i;
const hslishRegExp = /^hsla?$/i;
const hslRgbFuncMatch = /^(hsl|rgb)$/i;
const hslaRgbaFuncMatch = /^(hsla|rgba)$/i;
const hueUnitMatch = /^(deg|grad|rad|turn)?$/i;
const rgbishRegExp = /^rgba?$/i;

const isAlphaValue = node => isCalc(node) || node.type === 'number' && alphaUnitMatch.test(node.unit);

const isCalc = node => node.type === 'func' && calcFuncMatch.test(node.value);

const isHue = node => isCalc(node) || node.type === 'number' && hueUnitMatch.test(node.unit);

const isNumber = node => isCalc(node) || node.type === 'number' && node.unit === '';

const isPercentage = node => isCalc(node) || node.type === 'number' && (node.unit === '%' || node.unit === '' && node.value === '0');

const isHslish = node => node.type === 'func' && hslishRegExp.test(node.value);

const isHslRgb = node => node.type === 'func' && hslRgbFuncMatch.test(node.value);

const isHslaRgba = node => node.type === 'func' && hslaRgbaFuncMatch.test(node.value);

const isRgbish = node => node.type === 'func' && rgbishRegExp.test(node.value);

const isSlash = node => node.type === 'operator' && node.value === '/';

const functionalHSLMatch = [isHue, isPercentage, isPercentage, isSlash, isAlphaValue];
const functionalRGB1Match = [isNumber, isNumber, isNumber, isSlash, isAlphaValue];
const functionalRGB2Match = [isPercentage, isPercentage, isPercentage, isSlash, isAlphaValue];

const matchFunctionalHSL = (node, children) => isHslish(node) && children.every((child, index) => typeof functionalHSLMatch[index] === 'function' && functionalHSLMatch[index](child));

const matchFunctionalRGB1 = (node, children) => isRgbish(node) && children.every((child, index) => typeof functionalRGB1Match[index] === 'function' && functionalRGB1Match[index](child));

const matchFunctionalRGB2 = (node, children) => isRgbish(node) && children.every((child, index) => typeof functionalRGB2Match[index] === 'function' && functionalRGB2Match[index](child));

const newComma = () => valuesParser.comma({
  value: ','
});

module.exports = index;
//# sourceMappingURL=index.cjs.js.map
