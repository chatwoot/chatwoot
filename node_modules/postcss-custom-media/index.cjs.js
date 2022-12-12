'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var postcss = _interopDefault(require('postcss'));
var fs = _interopDefault(require('fs'));
var path = _interopDefault(require('path'));

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) {
  try {
    var info = gen[key](arg);
    var value = info.value;
  } catch (error) {
    reject(error);
    return;
  }

  if (info.done) {
    resolve(value);
  } else {
    Promise.resolve(value).then(_next, _throw);
  }
}

function _asyncToGenerator(fn) {
  return function () {
    var self = this,
        args = arguments;
    return new Promise(function (resolve, reject) {
      var gen = fn.apply(self, args);

      function _next(value) {
        asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value);
      }

      function _throw(err) {
        asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err);
      }

      _next(undefined);
    });
  };
}

function _defineProperty(obj, key, value) {
  if (key in obj) {
    Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      configurable: true,
      writable: true
    });
  } else {
    obj[key] = value;
  }

  return obj;
}

function _objectSpread(target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i] != null ? arguments[i] : {};
    var ownKeys = Object.keys(source);

    if (typeof Object.getOwnPropertySymbols === 'function') {
      ownKeys = ownKeys.concat(Object.getOwnPropertySymbols(source).filter(function (sym) {
        return Object.getOwnPropertyDescriptor(source, sym).enumerable;
      }));
    }

    ownKeys.forEach(function (key) {
      _defineProperty(target, key, source[key]);
    });
  }

  return target;
}

function _slicedToArray(arr, i) {
  return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _nonIterableRest();
}

function _arrayWithHoles(arr) {
  if (Array.isArray(arr)) return arr;
}

function _iterableToArrayLimit(arr, i) {
  var _arr = [];
  var _n = true;
  var _d = false;
  var _e = undefined;

  try {
    for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {
      _arr.push(_s.value);

      if (i && _arr.length === i) break;
    }
  } catch (err) {
    _d = true;
    _e = err;
  } finally {
    try {
      if (!_n && _i["return"] != null) _i["return"]();
    } finally {
      if (_d) throw _e;
    }
  }

  return _arr;
}

function _nonIterableRest() {
  throw new TypeError("Invalid attempt to destructure non-iterable instance");
}

function parse(string, splitByAnd) {
  const array = [];
  let buffer = '';
  let split = false;
  let func = 0;
  let i = -1;

  while (++i < string.length) {
    const char = string[i];

    if (char === '(') {
      func += 1;
    } else if (char === ')') {
      if (func > 0) {
        func -= 1;
      }
    } else if (func === 0) {
      if (splitByAnd && andRegExp.test(buffer + char)) {
        split = true;
      } else if (!splitByAnd && char === ',') {
        split = true;
      }
    }

    if (split) {
      array.push(splitByAnd ? new MediaExpression(buffer + char) : new MediaQuery(buffer));
      buffer = '';
      split = false;
    } else {
      buffer += char;
    }
  }

  if (buffer !== '') {
    array.push(splitByAnd ? new MediaExpression(buffer) : new MediaQuery(buffer));
  }

  return array;
}

class MediaQueryList {
  constructor(string) {
    this.nodes = parse(string);
  }

  invert() {
    this.nodes.forEach(node => {
      node.invert();
    });
    return this;
  }

  clone() {
    return new MediaQueryList(String(this));
  }

  toString() {
    return this.nodes.join(',');
  }

}

class MediaQuery {
  constructor(string) {
    const _string$match = string.match(spaceWrapRegExp),
          _string$match2 = _slicedToArray(_string$match, 4),
          before = _string$match2[1],
          media = _string$match2[2],
          after = _string$match2[3];

    const _ref = media.match(mediaRegExp) || [],
          _ref2 = _slicedToArray(_ref, 9),
          _ref2$ = _ref2[1],
          modifier = _ref2$ === void 0 ? '' : _ref2$,
          _ref2$2 = _ref2[2],
          afterModifier = _ref2$2 === void 0 ? ' ' : _ref2$2,
          _ref2$3 = _ref2[3],
          type = _ref2$3 === void 0 ? '' : _ref2$3,
          _ref2$4 = _ref2[4],
          beforeAnd = _ref2$4 === void 0 ? '' : _ref2$4,
          _ref2$5 = _ref2[5],
          and = _ref2$5 === void 0 ? '' : _ref2$5,
          _ref2$6 = _ref2[6],
          beforeExpression = _ref2$6 === void 0 ? '' : _ref2$6,
          _ref2$7 = _ref2[7],
          expression1 = _ref2$7 === void 0 ? '' : _ref2$7,
          _ref2$8 = _ref2[8],
          expression2 = _ref2$8 === void 0 ? '' : _ref2$8;

    const raws = {
      before,
      after,
      afterModifier,
      originalModifier: modifier || '',
      beforeAnd,
      and,
      beforeExpression
    };
    const nodes = parse(expression1 || expression2, true);
    Object.assign(this, {
      modifier,
      type,
      raws,
      nodes
    });
  }

  clone(overrides) {
    const instance = new MediaQuery(String(this));
    Object.assign(instance, overrides);
    return instance;
  }

  invert() {
    this.modifier = this.modifier ? '' : this.raws.originalModifier;
    return this;
  }

  toString() {
    const raws = this.raws;
    return `${raws.before}${this.modifier}${this.modifier ? `${raws.afterModifier}` : ''}${this.type}${raws.beforeAnd}${raws.and}${raws.beforeExpression}${this.nodes.join('')}${this.raws.after}`;
  }

}

class MediaExpression {
  constructor(string) {
    const _ref3 = string.match(andRegExp) || [null, string],
          _ref4 = _slicedToArray(_ref3, 5),
          value = _ref4[1],
          _ref4$ = _ref4[2],
          after = _ref4$ === void 0 ? '' : _ref4$,
          _ref4$2 = _ref4[3],
          and = _ref4$2 === void 0 ? '' : _ref4$2,
          _ref4$3 = _ref4[4],
          afterAnd = _ref4$3 === void 0 ? '' : _ref4$3;

    const raws = {
      after,
      and,
      afterAnd
    };
    Object.assign(this, {
      value,
      raws
    });
  }

  clone(overrides) {
    const instance = new MediaExpression(String(this));
    Object.assign(instance, overrides);
    return instance;
  }

  toString() {
    const raws = this.raws;
    return `${this.value}${raws.after}${raws.and}${raws.afterAnd}`;
  }

}

const modifierRE = '(not|only)';
const typeRE = '(all|print|screen|speech)';
const noExpressionRE = '([\\W\\w]*)';
const expressionRE = '([\\W\\w]+)';
const noSpaceRE = '(\\s*)';
const spaceRE = '(\\s+)';
const andRE = '(?:(\\s+)(and))';
const andRegExp = new RegExp(`^${expressionRE}(?:${andRE}${spaceRE})$`, 'i');
const spaceWrapRegExp = new RegExp(`^${noSpaceRE}${noExpressionRE}${noSpaceRE}$`);
const mediaRegExp = new RegExp(`^(?:${modifierRE}${spaceRE})?(?:${typeRE}(?:${andRE}${spaceRE}${expressionRE})?|${expressionRE})$`, 'i');
var mediaASTFromString = (string => new MediaQueryList(string));

var getCustomMediaFromRoot = ((root, opts) => {
  // initialize custom selectors
  const customMedias = {}; // for each custom selector atrule that is a child of the css root

  root.nodes.slice().forEach(node => {
    if (isCustomMedia(node)) {
      // extract the name and selectors from the params of the custom selector
      const _node$params$match = node.params.match(customMediaParamsRegExp),
            _node$params$match2 = _slicedToArray(_node$params$match, 3),
            name = _node$params$match2[1],
            selectors = _node$params$match2[2]; // write the parsed selectors to the custom selector


      customMedias[name] = mediaASTFromString(selectors); // conditionally remove the custom selector atrule

      if (!Object(opts).preserve) {
        node.remove();
      }
    }
  });
  return customMedias;
}); // match the custom selector name

const customMediaNameRegExp = /^custom-media$/i; // match the custom selector params

const customMediaParamsRegExp = /^(--[A-z][\w-]*)\s+([\W\w]+)\s*$/; // whether the atrule is a custom selector

const isCustomMedia = node => node.type === 'atrule' && customMediaNameRegExp.test(node.name) && customMediaParamsRegExp.test(node.params);

/* Get Custom Media from CSS File
/* ========================================================================== */

function getCustomMediaFromCSSFile(_x) {
  return _getCustomMediaFromCSSFile.apply(this, arguments);
}
/* Get Custom Media from Object
/* ========================================================================== */


function _getCustomMediaFromCSSFile() {
  _getCustomMediaFromCSSFile = _asyncToGenerator(function* (from) {
    const css = yield readFile(from);
    const root = postcss.parse(css, {
      from
    });
    return getCustomMediaFromRoot(root, {
      preserve: true
    });
  });
  return _getCustomMediaFromCSSFile.apply(this, arguments);
}

function getCustomMediaFromObject(object) {
  const customMedia = Object.assign({}, Object(object).customMedia, Object(object)['custom-media']);

  for (const key in customMedia) {
    customMedia[key] = mediaASTFromString(customMedia[key]);
  }

  return customMedia;
}
/* Get Custom Media from JSON file
/* ========================================================================== */


function getCustomMediaFromJSONFile(_x2) {
  return _getCustomMediaFromJSONFile.apply(this, arguments);
}
/* Get Custom Media from JS file
/* ========================================================================== */


function _getCustomMediaFromJSONFile() {
  _getCustomMediaFromJSONFile = _asyncToGenerator(function* (from) {
    const object = yield readJSON(from);
    return getCustomMediaFromObject(object);
  });
  return _getCustomMediaFromJSONFile.apply(this, arguments);
}

function getCustomMediaFromJSFile(_x3) {
  return _getCustomMediaFromJSFile.apply(this, arguments);
}
/* Get Custom Media from Sources
/* ========================================================================== */


function _getCustomMediaFromJSFile() {
  _getCustomMediaFromJSFile = _asyncToGenerator(function* (from) {
    const object = yield Promise.resolve(require(from));
    return getCustomMediaFromObject(object);
  });
  return _getCustomMediaFromJSFile.apply(this, arguments);
}

function getCustomMediaFromSources(sources) {
  return sources.map(source => {
    if (source instanceof Promise) {
      return source;
    } else if (source instanceof Function) {
      return source();
    } // read the source as an object


    const opts = source === Object(source) ? source : {
      from: String(source)
    }; // skip objects with custom media

    if (Object(opts).customMedia || Object(opts)['custom-media']) {
      return opts;
    } // source pathname


    const from = path.resolve(String(opts.from || '')); // type of file being read from

    const type = (opts.type || path.extname(from).slice(1)).toLowerCase();
    return {
      type,
      from
    };
  }).reduce(
  /*#__PURE__*/
  function () {
    var _ref = _asyncToGenerator(function* (customMedia, source) {
      const _ref2 = yield source,
            type = _ref2.type,
            from = _ref2.from;

      if (type === 'css' || type === 'pcss') {
        return Object.assign((yield customMedia), (yield getCustomMediaFromCSSFile(from)));
      }

      if (type === 'js') {
        return Object.assign((yield customMedia), (yield getCustomMediaFromJSFile(from)));
      }

      if (type === 'json') {
        return Object.assign((yield customMedia), (yield getCustomMediaFromJSONFile(from)));
      }

      return Object.assign((yield customMedia), getCustomMediaFromObject((yield source)));
    });

    return function (_x4, _x5) {
      return _ref.apply(this, arguments);
    };
  }(), {});
}
/* Helper utilities
/* ========================================================================== */

const readFile = from => new Promise((resolve, reject) => {
  fs.readFile(from, 'utf8', (error, result) => {
    if (error) {
      reject(error);
    } else {
      resolve(result);
    }
  });
});

const readJSON =
/*#__PURE__*/
function () {
  var _ref3 = _asyncToGenerator(function* (from) {
    return JSON.parse((yield readFile(from)));
  });

  return function readJSON(_x6) {
    return _ref3.apply(this, arguments);
  };
}();

// return transformed medias, replacing custom pseudo medias with custom medias
function transformMediaList(mediaList, customMedias) {
  let index = mediaList.nodes.length - 1;

  while (index >= 0) {
    const transformedMedias = transformMedia(mediaList.nodes[index], customMedias);

    if (transformedMedias.length) {
      mediaList.nodes.splice(index, 1, ...transformedMedias);
    }

    --index;
  }

  return mediaList;
} // return custom pseudo medias replaced with custom medias

function transformMedia(media, customMedias) {
  const transpiledMedias = [];

  for (const index in media.nodes) {
    const _media$nodes$index = media.nodes[index],
          value = _media$nodes$index.value,
          nodes = _media$nodes$index.nodes;
    const key = value.replace(customPseudoRegExp, '$1');

    if (key in customMedias) {
      var _iteratorNormalCompletion = true;
      var _didIteratorError = false;
      var _iteratorError = undefined;

      try {
        for (var _iterator = customMedias[key].nodes[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
          const replacementMedia = _step.value;
          // use the first available modifier unless they cancel each other out
          const modifier = media.modifier !== replacementMedia.modifier ? media.modifier || replacementMedia.modifier : '';
          const mediaClone = media.clone({
            modifier,
            // conditionally use the raws from the first available modifier
            raws: !modifier || media.modifier ? _objectSpread({}, media.raws) : _objectSpread({}, replacementMedia.raws),
            type: media.type || replacementMedia.type
          }); // conditionally include more replacement raws when the type is present

          if (mediaClone.type === replacementMedia.type) {
            Object.assign(mediaClone.raws, {
              and: replacementMedia.raws.and,
              beforeAnd: replacementMedia.raws.beforeAnd,
              beforeExpression: replacementMedia.raws.beforeExpression
            });
          }

          mediaClone.nodes.splice(index, 1, ...replacementMedia.clone().nodes.map(node => {
            // use raws and spacing from the current usage
            if (media.nodes[index].raws.and) {
              node.raws = _objectSpread({}, media.nodes[index].raws);
            }

            node.spaces = _objectSpread({}, media.nodes[index].spaces);
            return node;
          })); // remove the currently transformed key to prevent recursion

          const nextCustomMedia = getCustomMediasWithoutKey(customMedias, key);
          const retranspiledMedias = transformMedia(mediaClone, nextCustomMedia);

          if (retranspiledMedias.length) {
            transpiledMedias.push(...retranspiledMedias);
          } else {
            transpiledMedias.push(mediaClone);
          }
        }
      } catch (err) {
        _didIteratorError = true;
        _iteratorError = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion && _iterator.return != null) {
            _iterator.return();
          }
        } finally {
          if (_didIteratorError) {
            throw _iteratorError;
          }
        }
      }

      return transpiledMedias;
    } else if (nodes && nodes.length) {
      transformMediaList(media.nodes[index], customMedias);
    }
  }

  return transpiledMedias;
}

const customPseudoRegExp = /\((--[A-z][\w-]*)\)/;

const getCustomMediasWithoutKey = (customMedias, key) => {
  const nextCustomMedias = Object.assign({}, customMedias);
  delete nextCustomMedias[key];
  return nextCustomMedias;
};

var transformAtrules = ((root, customMedia, opts) => {
  root.walkAtRules(mediaAtRuleRegExp, atrule => {
    if (customPseudoRegExp$1.test(atrule.params)) {
      const mediaAST = mediaASTFromString(atrule.params);
      const params = String(transformMediaList(mediaAST, customMedia));

      if (opts.preserve) {
        atrule.cloneBefore({
          params
        });
      } else {
        atrule.params = params;
      }
    }
  });
});
const mediaAtRuleRegExp = /^media$/i;
const customPseudoRegExp$1 = /\(--[A-z][\w-]*\)/;

/* Write Custom Media from CSS File
/* ========================================================================== */

function writeCustomMediaToCssFile(_x, _x2) {
  return _writeCustomMediaToCssFile.apply(this, arguments);
}
/* Write Custom Media from JSON file
/* ========================================================================== */


function _writeCustomMediaToCssFile() {
  _writeCustomMediaToCssFile = _asyncToGenerator(function* (to, customMedia) {
    const cssContent = Object.keys(customMedia).reduce((cssLines, name) => {
      cssLines.push(`@custom-media ${name} ${customMedia[name]};`);
      return cssLines;
    }, []).join('\n');
    const css = `${cssContent}\n`;
    yield writeFile(to, css);
  });
  return _writeCustomMediaToCssFile.apply(this, arguments);
}

function writeCustomMediaToJsonFile(_x3, _x4) {
  return _writeCustomMediaToJsonFile.apply(this, arguments);
}
/* Write Custom Media from Common JS file
/* ========================================================================== */


function _writeCustomMediaToJsonFile() {
  _writeCustomMediaToJsonFile = _asyncToGenerator(function* (to, customMedia) {
    const jsonContent = JSON.stringify({
      'custom-media': customMedia
    }, null, '  ');
    const json = `${jsonContent}\n`;
    yield writeFile(to, json);
  });
  return _writeCustomMediaToJsonFile.apply(this, arguments);
}

function writeCustomMediaToCjsFile(_x5, _x6) {
  return _writeCustomMediaToCjsFile.apply(this, arguments);
}
/* Write Custom Media from Module JS file
/* ========================================================================== */


function _writeCustomMediaToCjsFile() {
  _writeCustomMediaToCjsFile = _asyncToGenerator(function* (to, customMedia) {
    const jsContents = Object.keys(customMedia).reduce((jsLines, name) => {
      jsLines.push(`\t\t'${escapeForJS(name)}': '${escapeForJS(customMedia[name])}'`);
      return jsLines;
    }, []).join(',\n');
    const js = `module.exports = {\n\tcustomMedia: {\n${jsContents}\n\t}\n};\n`;
    yield writeFile(to, js);
  });
  return _writeCustomMediaToCjsFile.apply(this, arguments);
}

function writeCustomMediaToMjsFile(_x7, _x8) {
  return _writeCustomMediaToMjsFile.apply(this, arguments);
}
/* Write Custom Media to Exports
/* ========================================================================== */


function _writeCustomMediaToMjsFile() {
  _writeCustomMediaToMjsFile = _asyncToGenerator(function* (to, customMedia) {
    const mjsContents = Object.keys(customMedia).reduce((mjsLines, name) => {
      mjsLines.push(`\t'${escapeForJS(name)}': '${escapeForJS(customMedia[name])}'`);
      return mjsLines;
    }, []).join(',\n');
    const mjs = `export const customMedia = {\n${mjsContents}\n};\n`;
    yield writeFile(to, mjs);
  });
  return _writeCustomMediaToMjsFile.apply(this, arguments);
}

function writeCustomMediaToExports(customMedia, destinations) {
  return Promise.all(destinations.map(
  /*#__PURE__*/
  function () {
    var _ref = _asyncToGenerator(function* (destination) {
      if (destination instanceof Function) {
        yield destination(defaultCustomMediaToJSON(customMedia));
      } else {
        // read the destination as an object
        const opts = destination === Object(destination) ? destination : {
          to: String(destination)
        }; // transformer for custom media into a JSON-compatible object

        const toJSON = opts.toJSON || defaultCustomMediaToJSON;

        if ('customMedia' in opts) {
          // write directly to an object as customMedia
          opts.customMedia = toJSON(customMedia);
        } else if ('custom-media' in opts) {
          // write directly to an object as custom-media
          opts['custom-media'] = toJSON(customMedia);
        } else {
          // destination pathname
          const to = String(opts.to || ''); // type of file being written to

          const type = (opts.type || path.extname(to).slice(1)).toLowerCase(); // transformed custom media

          const customMediaJSON = toJSON(customMedia);

          if (type === 'css') {
            yield writeCustomMediaToCssFile(to, customMediaJSON);
          }

          if (type === 'js') {
            yield writeCustomMediaToCjsFile(to, customMediaJSON);
          }

          if (type === 'json') {
            yield writeCustomMediaToJsonFile(to, customMediaJSON);
          }

          if (type === 'mjs') {
            yield writeCustomMediaToMjsFile(to, customMediaJSON);
          }
        }
      }
    });

    return function (_x9) {
      return _ref.apply(this, arguments);
    };
  }()));
}
/* Helper utilities
/* ========================================================================== */

const defaultCustomMediaToJSON = customMedia => {
  return Object.keys(customMedia).reduce((customMediaJSON, key) => {
    customMediaJSON[key] = String(customMedia[key]);
    return customMediaJSON;
  }, {});
};

const writeFile = (to, text) => new Promise((resolve, reject) => {
  fs.writeFile(to, text, error => {
    if (error) {
      reject(error);
    } else {
      resolve();
    }
  });
});

const escapeForJS = string => string.replace(/\\([\s\S])|(')/g, '\\$1$2').replace(/\n/g, '\\n').replace(/\r/g, '\\r');

var index = postcss.plugin('postcss-custom-media', opts => {
  // whether to preserve custom media and at-rules using them
  const preserve = 'preserve' in Object(opts) ? Boolean(opts.preserve) : false; // sources to import custom media from

  const importFrom = [].concat(Object(opts).importFrom || []); // destinations to export custom media to

  const exportTo = [].concat(Object(opts).exportTo || []); // promise any custom media are imported

  const customMediaPromise = getCustomMediaFromSources(importFrom);
  return (
    /*#__PURE__*/
    function () {
      var _ref = _asyncToGenerator(function* (root) {
        const customMedia = Object.assign((yield customMediaPromise), getCustomMediaFromRoot(root, {
          preserve
        }));
        yield writeCustomMediaToExports(customMedia, exportTo);
        transformAtrules(root, customMedia, {
          preserve
        });
      });

      return function (_x) {
        return _ref.apply(this, arguments);
      };
    }()
  );
});

module.exports = index;
//# sourceMappingURL=index.cjs.js.map
