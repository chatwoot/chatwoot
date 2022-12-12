"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = readInitialCoverage;

var _core = require("@babel/core");

var _schema = require("@istanbuljs/schema");

var _constants = require("./constants");

function getAst(code) {
  if (typeof code === 'object' && typeof code.type === 'string') {
    // Assume code is already a babel ast.
    return code;
  }

  if (typeof code !== 'string') {
    throw new Error('Code must be a string');
  } // Parse as leniently as possible


  return (0, _core.parseSync)(code, {
    babelrc: false,
    configFile: false,
    parserOpts: {
      allowImportExportEverywhere: true,
      allowReturnOutsideFunction: true,
      allowSuperOutsideMethod: true,
      sourceType: 'script',
      plugins: _schema.defaults.instrumenter.parserPlugins
    }
  });
}

function readInitialCoverage(code) {
  const ast = getAst(code);
  let covScope;
  (0, _core.traverse)(ast, {
    ObjectProperty(path) {
      const {
        node
      } = path;

      if (!node.computed && path.get('key').isIdentifier() && node.key.name === _constants.MAGIC_KEY) {
        const magicValue = path.get('value').evaluate();

        if (!magicValue.confident || magicValue.value !== _constants.MAGIC_VALUE) {
          return;
        }

        covScope = path.scope.getFunctionParent() || path.scope.getProgramParent();
        path.stop();
      }
    }

  });

  if (!covScope) {
    return null;
  }

  const result = {};

  for (const key of ['path', 'hash', 'gcv', 'coverageData']) {
    const binding = covScope.getOwnBinding(key);

    if (!binding) {
      return null;
    }

    const valuePath = binding.path.get('init');
    const value = valuePath.evaluate();

    if (!value.confident) {
      return null;
    }

    result[key] = value.value;
  }

  delete result.coverageData[_constants.MAGIC_KEY];
  delete result.coverageData.hash;
  return result;
}