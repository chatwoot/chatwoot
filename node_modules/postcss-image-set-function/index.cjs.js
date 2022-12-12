'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var postcss = _interopDefault(require('postcss'));
var valueParser = _interopDefault(require('postcss-values-parser'));

// return whether a node is a valid comma
var getComma = (node => Object(node).type === 'comma');

const imageSetFunctionMatchRegExp = /^(-webkit-)?image-set$/i; // return a valid image

var getImage = (node => // <url> | <image()> | <cross-fade()> | <gradient>
// the image-set() function can not be nested inside of itself
Object(node).type === 'func' && /^(cross-fade|image|(repeating-)?(conic|linear|radial)-gradient|url)$/i.test(node.value) && !(node.parent.parent && node.parent.parent.type === 'func' && imageSetFunctionMatchRegExp.test(node.parent.parent.value)) ? String(node) : Object(node).type === 'string' ? node.value : false);

const dpiRatios = {
  dpcm: 2.54,
  dpi: 1,
  dppx: 96,
  x: 96
}; // return a valid @media rule

var getMedia = ((node, mediasByDpr) => {
  if (Object(node).type === 'number' && node.unit in dpiRatios) {
    // calculate min-device-pixel-ratio and min-resolution
    const dpi = Number(node.value) * dpiRatios[node.unit.toLowerCase()];
    const dpr = Math.floor(dpi / dpiRatios.x * 100) / 100;

    if (dpi in mediasByDpr) {
      return false;
    } else {
      const media = mediasByDpr[dpi] = postcss.atRule({
        name: 'media',
        params: `(-webkit-min-device-pixel-ratio: ${dpr}), (min-resolution: ${dpi}dpi)`
      });
      return media;
    }
  } else {
    return false;
  }
});

var handleInvalidation = ((opts, message, word) => {
  if (opts.oninvalid === 'warn') {
    opts.decl.warn(opts.result, message, {
      word: String(word)
    });
  } else if (opts.oninvalid === 'throw') {
    throw opts.decl.error(message, {
      word: String(word)
    });
  }
});

var processImageSet = ((imageSetOptionNodes, decl, opts) => {
  const parent = decl.parent;
  const mediasByDpr = {};
  let length = imageSetOptionNodes.length;
  let index = -1;

  while (index < length) {
    const _ref = [index < 0 ? true : getComma(imageSetOptionNodes[index]), getImage(imageSetOptionNodes[index + 1]), getMedia(imageSetOptionNodes[index + 2], mediasByDpr)],
          comma = _ref[0],
          value = _ref[1],
          media = _ref[2]; // handle invalidations

    if (!comma) {
      return handleInvalidation(opts, 'unexpected comma', imageSetOptionNodes[index]);
    } else if (!value) {
      return handleInvalidation(opts, 'unexpected image', imageSetOptionNodes[index + 1]);
    } else if (!media) {
      return handleInvalidation(opts, 'unexpected resolution', imageSetOptionNodes[index + 2]);
    } // prepare @media { decl: <image> }


    const parentClone = parent.clone().removeAll();
    const declClone = decl.clone({
      value
    });
    parentClone.append(declClone);
    media.append(parentClone);
    index += 3;
  }

  const medias = Object.keys(mediasByDpr).sort((a, b) => a - b).map(params => mediasByDpr[params]); // conditionally prepend previous siblings

  if (medias.length) {
    const firstDecl = medias[0].nodes[0].nodes[0];

    if (medias.length === 1) {
      decl.value = firstDecl.value;
    } else {
      const siblings = parent.nodes;
      const previousSiblings = siblings.slice(0, siblings.indexOf(decl)).concat(firstDecl);

      if (previousSiblings.length) {
        const parentClone = parent.cloneBefore().removeAll();
        parentClone.append(previousSiblings);
      } // prepend any @media { decl: <image> } rules


      parent.before(medias.slice(1)); // conditionally remove the current rule

      if (!opts.preserve) {
        decl.remove(); // and then conditionally remove its parent

        if (!parent.nodes.length) {
          parent.remove();
        }
      }
    }
  }
});

const imageSetValueMatchRegExp = /(^|[^\w-])(-webkit-)?image-set\(/;
const imageSetFunctionMatchRegExp$1 = /^(-webkit-)?image-set$/i;
var index = postcss.plugin('postcss-image-set-function', opts => {
  // prepare options
  const preserve = 'preserve' in Object(opts) ? Boolean(opts.preserve) : true;
  const oninvalid = 'oninvalid' in Object(opts) ? opts.oninvalid : 'ignore';
  return (root, result) => {
    // for every declaration
    root.walkDecls(decl => {
      const value = decl.value; // if a declaration likely uses an image-set() function

      if (imageSetValueMatchRegExp.test(value)) {
        const valueAST = valueParser(value).parse(); // process every image-set() function

        valueAST.walkType('func', node => {
          if (imageSetFunctionMatchRegExp$1.test(node.value)) {
            processImageSet(node.nodes.slice(1, -1), decl, {
              decl,
              oninvalid,
              preserve,
              result
            });
          }
        });
      }
    });
  };
});

module.exports = index;
//# sourceMappingURL=index.cjs.js.map
