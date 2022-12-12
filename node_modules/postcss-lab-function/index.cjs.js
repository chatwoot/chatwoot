'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var convertColors = require('@csstools/convert-colors');
var postcss = _interopDefault(require('postcss'));
var parser = _interopDefault(require('postcss-values-parser'));

var index = postcss.plugin('postcss-lab-function', opts => {
  const preserve = 'preserve' in Object(opts) ? Boolean(opts.preserve) : false;
  return root => {
    root.walkDecls(decl => {
      const value = decl.value;

      if (colorAnyRegExp.test(value)) {
        const ast = parser(value).parse();
        ast.walkType('func', node => {
          if (colorRegExp.test(node.value)) {
            const children = node.nodes.slice(1, -1);
            const isLab = labRegExp.test(node.value);
            const isGray = grayRegExp.test(node.value);
            const isFunctionalLAB = !isGray && matchFunctionalLAB(children);
            const isFunctionalLCH = !isGray && matchFunctionalLCH(children);
            const isFunctionalGray = isGray && matchFunctionalGray(children);

            if (isFunctionalLAB || isFunctionalLCH) {
              node.value = 'rgb';
              const slashNode = children[3];
              const alphaNode = children[4];

              if (alphaNode) {
                if (isPercentage(alphaNode) && !isCalc(alphaNode)) {
                  alphaNode.unit = '';
                  alphaNode.value = String(alphaNode.value / 100);
                }

                if (alphaNode.value === '1') {
                  slashNode.remove();
                  alphaNode.remove();
                } else {
                  node.value += 'a';
                }
              }

              if (slashNode && isSlash(slashNode)) {
                slashNode.replaceWith(newComma());
              }

              const converter = isLab ? convertColors.lab2rgb : convertColors.lch2rgb;
              const rgbValues = converter(...[children[0].value, children[1].value, children[2].value].map(number => parseFloat(number))).map(sourceValue => Math.max(Math.min(parseInt(sourceValue * 2.55), 255), 0));
              children[0].value = String(rgbValues[0]);
              children[1].value = String(rgbValues[1]);
              children[2].value = String(rgbValues[2]);
              node.nodes.splice(3, 0, [newComma()]);
              node.nodes.splice(2, 0, [newComma()]);
            } else if (isFunctionalGray) {
              node.value = 'rgb';
              const alphaNode = children[2];
              const rgbValues = convertColors.lab2rgb(...[children[0].value, 0, 0].map(number => parseFloat(number))).map(sourceValue => Math.max(Math.min(parseInt(sourceValue * 2.55), 255), 0));
              node.removeAll().append(newParen('(')).append(newNumber(rgbValues[0])).append(newComma()).append(newNumber(rgbValues[1])).append(newComma()).append(newNumber(rgbValues[2])).append(newParen(')'));

              if (alphaNode) {
                if (isPercentage(alphaNode) && !isCalc(alphaNode)) {
                  alphaNode.unit = '';
                  alphaNode.value = String(alphaNode.value / 100);
                }

                if (alphaNode.value !== '1') {
                  node.value += 'a';
                  node.insertBefore(node.last, newComma()).insertBefore(node.last, alphaNode);
                }
              }
            }
          }
        });
        const newValue = String(ast);

        if (preserve) {
          decl.cloneBefore({
            value: newValue
          });
        } else {
          decl.value = newValue;
        }
      }
    });
  };
});
const colorAnyRegExp = /(^|[^\w-])(lab|lch|gray)\(/i;
const colorRegExp = /^(lab|lch|gray)$/i;
const labRegExp = /^lab$/i;
const grayRegExp = /^gray$/i;
const alphaUnitMatch = /^%?$/i;
const calcFuncMatch = /^calc$/i;
const hueUnitMatch = /^(deg|grad|rad|turn)?$/i;

const isAlphaValue = node => isCalc(node) || node.type === 'number' && alphaUnitMatch.test(node.unit);

const isCalc = node => node.type === 'func' && calcFuncMatch.test(node.value);

const isHue = node => isCalc(node) || node.type === 'number' && hueUnitMatch.test(node.unit);

const isNumber = node => isCalc(node) || node.type === 'number' && node.unit === '';

const isPercentage = node => isCalc(node) || node.type === 'number' && node.unit === '%';

const isSlash = node => node.type === 'operator' && node.value === '/';

const functionalLABMatch = [isNumber, isNumber, isNumber, isSlash, isAlphaValue];
const functionalLCHMatch = [isNumber, isNumber, isHue, isSlash, isAlphaValue];
const functionalGrayMatch = [isNumber, isSlash, isAlphaValue];

const matchFunctionalLAB = children => children.every((child, index) => typeof functionalLABMatch[index] === 'function' && functionalLABMatch[index](child));

const matchFunctionalLCH = children => children.every((child, index) => typeof functionalLCHMatch[index] === 'function' && functionalLCHMatch[index](child));

const matchFunctionalGray = children => children.every((child, index) => typeof functionalGrayMatch[index] === 'function' && functionalGrayMatch[index](child));

const newComma = () => parser.comma({
  value: ','
});

const newNumber = value => parser.number({
  value
});

const newParen = value => parser.paren({
  value
});

module.exports = index;
//# sourceMappingURL=index.cjs.js.map
