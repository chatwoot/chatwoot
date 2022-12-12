'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var parser = _interopDefault(require('postcss-values-parser'));
var fs = _interopDefault(require('fs'));
var path = _interopDefault(require('path'));
var postcss = _interopDefault(require('postcss'));

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

const dashedMatch = /^--/; // returns the value of a css function as a string

var getFnValue = (node => {
  const value = String(node.nodes.slice(1, -1));
  return dashedMatch.test(value) ? value : undefined;
});

var updateEnvValue = ((node, variables) => {
  // get the value of a css function as a string
  const value = getFnValue(node);

  if (typeof value === 'string' && value in variables) {
    node.replaceWith(...asClonedArrayWithBeforeSpacing(variables[value], node.raws.before));
  }
}); // return an array with its nodes cloned, preserving the raw

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

// returns whether a node is a css env() function
var isEnvFunc = (node => node && node.type === 'func' && node.value === 'env');

function walk(node, fn) {
  node.nodes.slice(0).forEach(childNode => {
    if (childNode.nodes) {
      walk(childNode, fn);
    }

    if (isEnvFunc(childNode)) {
      fn(childNode);
    }
  });
}

var getReplacedValue = ((originalValue, variables) => {
  // get the ast of the original value
  const ast = parser(originalValue).parse(); // walk all of the css env() functions

  walk(ast, node => {
    // update the environment value for the css env() function
    updateEnvValue(node, variables);
  }); // return the stringified ast

  return String(ast);
});

// returns whether a node is an at-rule
var isAtrule = (node => node && node.type === 'atrule');

// returns whether a node is a declaration
var isDecl = (node => node && node.type === 'decl');

var getSupportedValue = (node => isAtrule(node) && node.params || isDecl(node) && node.value);

function setSupportedValue (node, value) {
  if (isAtrule(node)) {
    node.params = value;
  }

  if (isDecl(node)) {
    node.value = value;
  }
}

/* Import Custom Properties from Object
/* ========================================================================== */

function importEnvironmentVariablesFromObject(object) {
  const environmentVariables = Object.assign({}, Object(object).environmentVariables || Object(object)['environment-variables']);

  for (const key in environmentVariables) {
    environmentVariables[key] = parser(environmentVariables[key]).parse().nodes;
  }

  return environmentVariables;
}
/* Import Custom Properties from JSON file
/* ========================================================================== */


function importEnvironmentVariablesFromJSONFile(_x) {
  return _importEnvironmentVariablesFromJSONFile.apply(this, arguments);
}
/* Import Custom Properties from JS file
/* ========================================================================== */


function _importEnvironmentVariablesFromJSONFile() {
  _importEnvironmentVariablesFromJSONFile = _asyncToGenerator(function* (from) {
    const object = yield readJSON(path.resolve(from));
    return importEnvironmentVariablesFromObject(object);
  });
  return _importEnvironmentVariablesFromJSONFile.apply(this, arguments);
}

function importEnvironmentVariablesFromJSFile(_x2) {
  return _importEnvironmentVariablesFromJSFile.apply(this, arguments);
}
/* Import Custom Properties from Sources
/* ========================================================================== */


function _importEnvironmentVariablesFromJSFile() {
  _importEnvironmentVariablesFromJSFile = _asyncToGenerator(function* (from) {
    const object = yield Promise.resolve(require(path.resolve(from)));
    return importEnvironmentVariablesFromObject(object);
  });
  return _importEnvironmentVariablesFromJSFile.apply(this, arguments);
}

function importEnvironmentVariablesFromSources(sources) {
  return sources.map(source => {
    if (source instanceof Promise) {
      return source;
    } else if (source instanceof Function) {
      return source();
    } // read the source as an object


    const opts = source === Object(source) ? source : {
      from: String(source)
    }; // skip objects with Custom Properties

    if (opts.environmentVariables || opts['environment-variables']) {
      return opts;
    } // source pathname


    const from = String(opts.from || ''); // type of file being read from

    const type = (opts.type || path.extname(from).slice(1)).toLowerCase();
    return {
      type,
      from
    };
  }).reduce(
  /*#__PURE__*/
  function () {
    var _ref = _asyncToGenerator(function* (environmentVariables, source) {
      const _ref2 = yield source,
            type = _ref2.type,
            from = _ref2.from;

      if (type === 'js') {
        return Object.assign(environmentVariables, (yield importEnvironmentVariablesFromJSFile(from)));
      }

      if (type === 'json') {
        return Object.assign(environmentVariables, (yield importEnvironmentVariablesFromJSONFile(from)));
      }

      return Object.assign(environmentVariables, importEnvironmentVariablesFromObject((yield source)));
    });

    return function (_x3, _x4) {
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

  return function readJSON(_x5) {
    return _ref3.apply(this, arguments);
  };
}();

var index = postcss.plugin('postcss-env-fn', opts => {
  // sources to import environment variables from
  const importFrom = [].concat(Object(opts).importFrom || []); // promise any environment variables are imported

  const environmentVariablesPromise = importEnvironmentVariablesFromSources(importFrom);
  return (
    /*#__PURE__*/
    function () {
      var _ref = _asyncToGenerator(function* (root) {
        const environmentVariables = yield environmentVariablesPromise;
        root.walk(node => {
          const supportedValue = getSupportedValue(node);

          if (supportedValue) {
            const replacedValue = getReplacedValue(supportedValue, environmentVariables);

            if (replacedValue !== supportedValue) {
              setSupportedValue(node, replacedValue);
            }
          }
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
