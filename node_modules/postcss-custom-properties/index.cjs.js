'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var postcss = _interopDefault(require('postcss'));
var valueParser = _interopDefault(require('postcss-values-parser'));
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

function parse(string) {
  return valueParser(string).parse();
}

function isBlockIgnored(ruleOrDeclaration) {
  var rule = ruleOrDeclaration.selector ? ruleOrDeclaration : ruleOrDeclaration.parent;
  return /(!\s*)?postcss-custom-properties:\s*off\b/i.test(rule.toString());
}

function isRuleIgnored(rule) {
  var previous = rule.prev();
  return Boolean(isBlockIgnored(rule) || previous && previous.type === 'comment' && /(!\s*)?postcss-custom-properties:\s*ignore\s+next\b/i.test(previous.text));
}

function getCustomPropertiesFromRoot(root, opts) {
  // initialize custom selectors
  const customPropertiesFromHtmlElement = {};
  const customPropertiesFromRootPseudo = {}; // for each html or :root rule

  root.nodes.slice().forEach(rule => {
    const customPropertiesObject = isHtmlRule(rule) ? customPropertiesFromHtmlElement : isRootRule(rule) ? customPropertiesFromRootPseudo : null; // for each custom property

    if (customPropertiesObject) {
      rule.nodes.slice().forEach(decl => {
        if (isCustomDecl(decl) && !isBlockIgnored(decl)) {
          const prop = decl.prop; // write the parsed value to the custom property

          customPropertiesObject[prop] = parse(decl.value).nodes; // conditionally remove the custom property declaration

          if (!opts.preserve) {
            decl.remove();
          }
        }
      }); // conditionally remove the empty html or :root rule

      if (!opts.preserve && isEmptyParent(rule) && !isBlockIgnored(rule)) {
        rule.remove();
      }
    }
  }); // return all custom properties, preferring :root properties over html properties

  return Object.assign({}, customPropertiesFromHtmlElement, customPropertiesFromRootPseudo);
} // match html and :root rules

const htmlSelectorRegExp = /^html$/i;
const rootSelectorRegExp = /^:root$/i;
const customPropertyRegExp = /^--[A-z][\w-]*$/; // whether the node is an html or :root rule

const isHtmlRule = node => node.type === 'rule' && htmlSelectorRegExp.test(node.selector) && Object(node.nodes).length;

const isRootRule = node => node.type === 'rule' && rootSelectorRegExp.test(node.selector) && Object(node.nodes).length; // whether the node is an custom property


const isCustomDecl = node => node.type === 'decl' && customPropertyRegExp.test(node.prop); // whether the node is a parent without children


const isEmptyParent = node => Object(node.nodes).length === 0;

/* Get Custom Properties from CSS File
/* ========================================================================== */

function getCustomPropertiesFromCSSFile(_x) {
  return _getCustomPropertiesFromCSSFile.apply(this, arguments);
}
/* Get Custom Properties from Object
/* ========================================================================== */


function _getCustomPropertiesFromCSSFile() {
  _getCustomPropertiesFromCSSFile = _asyncToGenerator(function* (from) {
    const css = yield readFile(from);
    const root = postcss.parse(css, {
      from
    });
    return getCustomPropertiesFromRoot(root, {
      preserve: true
    });
  });
  return _getCustomPropertiesFromCSSFile.apply(this, arguments);
}

function getCustomPropertiesFromObject(object) {
  const customProperties = Object.assign({}, Object(object).customProperties, Object(object)['custom-properties']);

  for (const key in customProperties) {
    customProperties[key] = parse(String(customProperties[key])).nodes;
  }

  return customProperties;
}
/* Get Custom Properties from JSON file
/* ========================================================================== */


function getCustomPropertiesFromJSONFile(_x2) {
  return _getCustomPropertiesFromJSONFile.apply(this, arguments);
}
/* Get Custom Properties from JS file
/* ========================================================================== */


function _getCustomPropertiesFromJSONFile() {
  _getCustomPropertiesFromJSONFile = _asyncToGenerator(function* (from) {
    const object = yield readJSON(from);
    return getCustomPropertiesFromObject(object);
  });
  return _getCustomPropertiesFromJSONFile.apply(this, arguments);
}

function getCustomPropertiesFromJSFile(_x3) {
  return _getCustomPropertiesFromJSFile.apply(this, arguments);
}
/* Get Custom Properties from Imports
/* ========================================================================== */


function _getCustomPropertiesFromJSFile() {
  _getCustomPropertiesFromJSFile = _asyncToGenerator(function* (from) {
    const object = yield Promise.resolve(require(from));
    return getCustomPropertiesFromObject(object);
  });
  return _getCustomPropertiesFromJSFile.apply(this, arguments);
}

function getCustomPropertiesFromImports(sources) {
  return sources.map(source => {
    if (source instanceof Promise) {
      return source;
    } else if (source instanceof Function) {
      return source();
    } // read the source as an object


    const opts = source === Object(source) ? source : {
      from: String(source)
    }; // skip objects with Custom Properties

    if (opts.customProperties || opts['custom-properties']) {
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
    var _ref = _asyncToGenerator(function* (customProperties, source) {
      const _ref2 = yield source,
            type = _ref2.type,
            from = _ref2.from;

      if (type === 'css') {
        return Object.assign((yield customProperties), (yield getCustomPropertiesFromCSSFile(from)));
      }

      if (type === 'js') {
        return Object.assign((yield customProperties), (yield getCustomPropertiesFromJSFile(from)));
      }

      if (type === 'json') {
        return Object.assign((yield customProperties), (yield getCustomPropertiesFromJSONFile(from)));
      }

      return Object.assign((yield customProperties), (yield getCustomPropertiesFromObject((yield source))));
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

function transformValueAST(root, customProperties) {
  if (root.nodes && root.nodes.length) {
    root.nodes.slice().forEach(child => {
      if (isVarFunction(child)) {
        // eslint-disable-next-line no-unused-vars
        const _child$nodes$slice = child.nodes.slice(1, -1),
              propertyNode = _child$nodes$slice[0],
              comma = _child$nodes$slice[1],
              fallbacks = _child$nodes$slice.slice(2);

        const name = propertyNode.value;

        if (name in Object(customProperties)) {
          // conditionally replace a known custom property
          const nodes = asClonedArrayWithBeforeSpacing(customProperties[name], child.raws.before);
          child.replaceWith(...nodes);
          retransformValueAST({
            nodes
          }, customProperties, name);
        } else if (fallbacks.length) {
          // conditionally replace a custom property with a fallback
          const index = root.nodes.indexOf(child);

          if (index !== -1) {
            root.nodes.splice(index, 1, ...asClonedArrayWithBeforeSpacing(fallbacks, child.raws.before));
          }

          transformValueAST(root, customProperties);
        }
      } else {
        transformValueAST(child, customProperties);
      }
    });
  }

  return root;
} // retransform the current ast without a custom property (to prevent recursion)

function retransformValueAST(root, customProperties, withoutProperty) {
  const nextCustomProperties = Object.assign({}, customProperties);
  delete nextCustomProperties[withoutProperty];
  return transformValueAST(root, nextCustomProperties);
} // match var() functions


const varRegExp = /^var$/i; // whether the node is a var() function

const isVarFunction = node => node.type === 'func' && varRegExp.test(node.value) && Object(node.nodes).length > 0; // return an array with its nodes cloned, preserving the raw


const asClonedArrayWithBeforeSpacing = (array, beforeSpacing) => {
  const clonedArray = asClonedArray(array, null);

  if (clonedArray[0]) {
    clonedArray[0].raws.before = beforeSpacing;
  }

  return clonedArray;
}; // return an array with its nodes cloned


const asClonedArray = (array, parent) => array.map(node => asClonedNode(node, parent)); // return a cloned node


const asClonedNode = (node, parent) => {
  const cloneNode = new node.constructor(node);

  for (const key in node) {
    if (key === 'parent') {
      cloneNode.parent = parent;
    } else if (Object(node[key]).constructor === Array) {
      cloneNode[key] = asClonedArray(node.nodes, cloneNode);
    } else if (Object(node[key]).constructor === Object) {
      cloneNode[key] = Object.assign({}, node[key]);
    }
  }

  return cloneNode;
};

var transformProperties = ((root, customProperties, opts) => {
  // walk decls that can be transformed
  root.walkDecls(decl => {
    if (isTransformableDecl(decl) && !isRuleIgnored(decl)) {
      const originalValue = decl.value;
      const valueAST = parse(originalValue);
      const value = String(transformValueAST(valueAST, customProperties)); // conditionally transform values that have changed

      if (value !== originalValue) {
        if (opts.preserve) {
          decl.cloneBefore({
            value
          });
        } else {
          decl.value = value;
        }
      }
    }
  });
}); // match custom properties

const customPropertyRegExp$1 = /^--[A-z][\w-]*$/; // match custom property inclusions

const customPropertiesRegExp = /(^|[^\w-])var\([\W\w]+\)/; // whether the declaration should be potentially transformed

const isTransformableDecl = decl => !customPropertyRegExp$1.test(decl.prop) && customPropertiesRegExp.test(decl.value);

/* Write Custom Properties to CSS File
/* ========================================================================== */

function writeCustomPropertiesToCssFile(_x, _x2) {
  return _writeCustomPropertiesToCssFile.apply(this, arguments);
}
/* Write Custom Properties to JSON file
/* ========================================================================== */


function _writeCustomPropertiesToCssFile() {
  _writeCustomPropertiesToCssFile = _asyncToGenerator(function* (to, customProperties) {
    const cssContent = Object.keys(customProperties).reduce((cssLines, name) => {
      cssLines.push(`\t${name}: ${customProperties[name]};`);
      return cssLines;
    }, []).join('\n');
    const css = `:root {\n${cssContent}\n}\n`;
    yield writeFile(to, css);
  });
  return _writeCustomPropertiesToCssFile.apply(this, arguments);
}

function writeCustomPropertiesToJsonFile(_x3, _x4) {
  return _writeCustomPropertiesToJsonFile.apply(this, arguments);
}
/* Write Custom Properties to Common JS file
/* ========================================================================== */


function _writeCustomPropertiesToJsonFile() {
  _writeCustomPropertiesToJsonFile = _asyncToGenerator(function* (to, customProperties) {
    const jsonContent = JSON.stringify({
      'custom-properties': customProperties
    }, null, '  ');
    const json = `${jsonContent}\n`;
    yield writeFile(to, json);
  });
  return _writeCustomPropertiesToJsonFile.apply(this, arguments);
}

function writeCustomPropertiesToCjsFile(_x5, _x6) {
  return _writeCustomPropertiesToCjsFile.apply(this, arguments);
}
/* Write Custom Properties to Module JS file
/* ========================================================================== */


function _writeCustomPropertiesToCjsFile() {
  _writeCustomPropertiesToCjsFile = _asyncToGenerator(function* (to, customProperties) {
    const jsContents = Object.keys(customProperties).reduce((jsLines, name) => {
      jsLines.push(`\t\t'${escapeForJS(name)}': '${escapeForJS(customProperties[name])}'`);
      return jsLines;
    }, []).join(',\n');
    const js = `module.exports = {\n\tcustomProperties: {\n${jsContents}\n\t}\n};\n`;
    yield writeFile(to, js);
  });
  return _writeCustomPropertiesToCjsFile.apply(this, arguments);
}

function writeCustomPropertiesToMjsFile(_x7, _x8) {
  return _writeCustomPropertiesToMjsFile.apply(this, arguments);
}
/* Write Custom Properties to Exports
/* ========================================================================== */


function _writeCustomPropertiesToMjsFile() {
  _writeCustomPropertiesToMjsFile = _asyncToGenerator(function* (to, customProperties) {
    const mjsContents = Object.keys(customProperties).reduce((mjsLines, name) => {
      mjsLines.push(`\t'${escapeForJS(name)}': '${escapeForJS(customProperties[name])}'`);
      return mjsLines;
    }, []).join(',\n');
    const mjs = `export const customProperties = {\n${mjsContents}\n};\n`;
    yield writeFile(to, mjs);
  });
  return _writeCustomPropertiesToMjsFile.apply(this, arguments);
}

function writeCustomPropertiesToExports(customProperties, destinations) {
  return Promise.all(destinations.map(
  /*#__PURE__*/
  function () {
    var _ref = _asyncToGenerator(function* (destination) {
      if (destination instanceof Function) {
        yield destination(defaultCustomPropertiesToJSON(customProperties));
      } else {
        // read the destination as an object
        const opts = destination === Object(destination) ? destination : {
          to: String(destination)
        }; // transformer for Custom Properties into a JSON-compatible object

        const toJSON = opts.toJSON || defaultCustomPropertiesToJSON;

        if ('customProperties' in opts) {
          // write directly to an object as customProperties
          opts.customProperties = toJSON(customProperties);
        } else if ('custom-properties' in opts) {
          // write directly to an object as custom-properties
          opts['custom-properties'] = toJSON(customProperties);
        } else {
          // destination pathname
          const to = String(opts.to || ''); // type of file being written to

          const type = (opts.type || path.extname(opts.to).slice(1)).toLowerCase(); // transformed Custom Properties

          const customPropertiesJSON = toJSON(customProperties);

          if (type === 'css') {
            yield writeCustomPropertiesToCssFile(to, customPropertiesJSON);
          }

          if (type === 'js') {
            yield writeCustomPropertiesToCjsFile(to, customPropertiesJSON);
          }

          if (type === 'json') {
            yield writeCustomPropertiesToJsonFile(to, customPropertiesJSON);
          }

          if (type === 'mjs') {
            yield writeCustomPropertiesToMjsFile(to, customPropertiesJSON);
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

const defaultCustomPropertiesToJSON = customProperties => {
  return Object.keys(customProperties).reduce((customPropertiesJSON, key) => {
    customPropertiesJSON[key] = String(customProperties[key]);
    return customPropertiesJSON;
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

var index = postcss.plugin('postcss-custom-properties', opts => {
  // whether to preserve custom selectors and rules using them
  const preserve = 'preserve' in Object(opts) ? Boolean(opts.preserve) : true; // sources to import custom selectors from

  const importFrom = [].concat(Object(opts).importFrom || []); // destinations to export custom selectors to

  const exportTo = [].concat(Object(opts).exportTo || []); // promise any custom selectors are imported

  const customPropertiesPromise = getCustomPropertiesFromImports(importFrom); // synchronous transform

  const syncTransform = root => {
    const customProperties = getCustomPropertiesFromRoot(root, {
      preserve
    });
    transformProperties(root, customProperties, {
      preserve
    });
  }; // asynchronous transform


  const asyncTransform =
  /*#__PURE__*/
  function () {
    var _ref = _asyncToGenerator(function* (root) {
      const customProperties = Object.assign({}, (yield customPropertiesPromise), getCustomPropertiesFromRoot(root, {
        preserve
      }));
      yield writeCustomPropertiesToExports(customProperties, exportTo);
      transformProperties(root, customProperties, {
        preserve
      });
    });

    return function asyncTransform(_x) {
      return _ref.apply(this, arguments);
    };
  }(); // whether to return synchronous function if no asynchronous operations are requested


  const canReturnSyncFunction = importFrom.length === 0 && exportTo.length === 0;
  return canReturnSyncFunction ? syncTransform : asyncTransform;
});

module.exports = index;
//# sourceMappingURL=index.cjs.js.map
